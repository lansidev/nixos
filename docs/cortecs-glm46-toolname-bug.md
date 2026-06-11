# Cortecs `glm-4.6` — truncated tool-call names (known provider bug)

**Status:** open — reported to Cortecs 2026-06-08. Workaround (stopgap) applied
in this repo; revert once Cortecs fixes it (see [below](#revert-once-cortecs-fixes-it)).

## TL;DR

`glm-4.6` on Cortecs (upstream backend **AtlasCloud**) returns a **truncated**
`tool_call.function.name`: a tool named `ask_user_question` comes back as
`ask_u` / `ask_us` (the truncation length varies between requests). The tool
*arguments* are returned complete and valid — only the **name** is mangled.

Any tool whose name is longer than a single token is therefore unusable: the
harness looks up the returned name, finds no such tool, and fails (Pi shows
`Tool ask_u not found`). Short, single-token names (`read`, `bash`) happen to
survive, which masks the bug for simple tool sets.

This is a **provider bug** — not Pi, not the `pi-subagents`/`rpiv-ask-user-question`
extensions. Verified against the raw Cortecs API in both `stream: true` and
`stream: false` mode. Qwen models on the **same** endpoint return the full name
correctly, so the Cortecs proxy itself is fine — only the `glm-4.6` (AtlasCloud)
route is affected.

## Workaround in this repo (stopgap)

`modules/development/pi-coding-agent.nix` pins the main model to
**`qwen3-next-80b-a3b-thinking`** instead of `glm-4.6` (`defaultModel`), mirrored
on the Mac (`~/.pi/agent/settings.json`). It returns correct tool names **and**
correct nested tool-call arguments, and is EU-sovereign. `glm-4.6` stays in the
`models.json` allow-list and is still selectable via `/model` — it just is not
the default.

> The obvious first replacement, `qwen3-coder-next`, was rejected: it returns
> the correct tool *name* but serialises *nested* arguments as JSON strings
> (e.g. `questions` for `ask_user_question` arrives as a string, not an array),
> which fails schema validation and also broke the `write` tool. Probing the raw
> API across the Cortecs catalog, only `qwen3-next-80b-a3b-thinking` and
> `devstral-2512` returned well-formed nested arguments; `devstral-2512` is
> historically loop-prone (the reason GLM replaced it), so the thinking model won.

This is intentionally a **minimal stopgap**: the "GLM-4.6 is the main model"
wording elsewhere (`README.md`, `docs/pi-coding-agent.md`,
`docs/pi-coding-agent-macos.md`, and the subagent/`models.json` comments in
`pi-coding-agent.nix`) is the *intended* steady state and was deliberately
**left in place** rather than rewritten — to avoid churn on a temporary
provider regression. `defaultModel` + this file + the `AGENTS.md` pitfall are
the single source of truth for the current deviation.

> Side effect to remember: the main model is now `qwen3-next-80b-a3b-thinking`,
> which is also the `planner` `agentOverrides` model — so `planner` delegations
> now run on the same model as the main agent. Harmless; revisit the tiering
> after reverting to `glm-4.6`.

### Revert once Cortecs fixes it

1. Re-run reproduction **A** below. If `function.name` is `ask_user_question`
   (not `ask_u`/`ask_us`), the bug is fixed.
2. Set `defaultModel = "glm-4.6";` again in
   `modules/development/pi-coding-agent.nix` **and**
   `~/.pi/agent/settings.json` (KEEP IN SYNC), then `home-manager switch`
   (or `nixos-rebuild switch`) and restart Pi on the Mac.
3. Remove the `AGENTS.md` pitfall entry and delete this file (or mark it
   resolved).

## Report sent to Cortecs

> `$CORTECS_API_KEY` below — on the Mac: `$(cat ~/.pi/agent/cortecs_api_key)`;
> on NixOS: `$(cat /run/secrets/pi/cortecs_api_key)`.

### Summary

On the Cortecs OpenAI-compatible endpoint, model `glm-4.6` returns a truncated
`tool_call.function.name`. A tool defined as `ask_user_question` comes back as
`ask_u` / `ask_us` (truncation length varies between requests). This makes
function calling unusable with `glm-4.6` for any tool whose name is longer than
a single token: the client looks up the returned name, finds no such tool, and
errors out. The tool *arguments* are returned complete and valid — only the
name is truncated.

### Environment

- Endpoint: `https://api.cortecs.ai/v1/chat/completions`
- Affected model: `glm-4.6`
- Upstream backend (from a 400 error's metadata): `provider_name: "AtlasCloud"`
- Date observed: 2026-06-08
- API style: `openai-completions`

### Expected vs. actual

- Expected: `function.name == "ask_user_question"`
- Actual:   `function.name == "ask_us"` (or `"ask_u"`)

### Scope

- Reproduces with **both** `"stream": true` and `"stream": false` → not a
  streaming artifact; the returned name itself is truncated.
- Other models on the same endpoint are **unaffected**: `qwen3-coder-next` and
  `qwen3-30b-a3b-instruct-2507` both return the full `ask_user_question`.
  ⇒ The issue is specific to the `glm-4.6` route (AtlasCloud), not the Cortecs
  proxy in general.
- Truncation length is not constant (seen at 5 and 6 characters), so it is not a
  fixed limit and cannot be worked around by client-side aliasing.

### Reproduction

```bash
# A) Streaming — GLM-4.6 (truncated name)
curl -sN https://api.cortecs.ai/v1/chat/completions \
  -H "Authorization: Bearer $CORTECS_API_KEY" -H "Content-Type: application/json" \
  -d '{
    "model":"glm-4.6","stream":true,"tool_choice":"auto",
    "messages":[
      {"role":"system","content":"You MUST call the ask_user_question tool. Never answer in plain text."},
      {"role":"user","content":"I want to commit. Ask me to confirm via the ask_user_question tool."}],
    "tools":[{"type":"function","function":{
      "name":"ask_user_question","description":"Ask the user a clarifying question.",
      "parameters":{"type":"object","properties":{"question":{"type":"string"}},"required":["question"]}}}]
  }' | grep -o '"name":"[^"]*"'
# → "name":"ask_us"     (expected "name":"ask_user_question")

# B) Non-streaming — GLM-4.6 (same truncation)
curl -s https://api.cortecs.ai/v1/chat/completions \
  -H "Authorization: Bearer $CORTECS_API_KEY" -H "Content-Type: application/json" \
  -d '{ "model":"glm-4.6","stream":false,"tool_choice":"auto",
        "messages":[{"role":"system","content":"You MUST call the ask_user_question tool."},
                    {"role":"user","content":"Ask me to confirm via ask_user_question."}],
        "tools":[{"type":"function","function":{"name":"ask_user_question",
          "description":"Ask a question.","parameters":{"type":"object",
          "properties":{"question":{"type":"string"}},"required":["question"]}}}] }'
# → choices[0].message.tool_calls[0].function.name == "ask_us"

# C) Control — identical request, model "qwen3-coder-next"
#    (or "qwen3-30b-a3b-instruct-2507"): function.name == "ask_user_question"  ✓
```

### Impact

Any OpenAI-compatible client / agent harness using `glm-4.6` with tools whose
names exceed one token (very common — e.g. `ask_user_question`, `search_web`,
`create_file`) cannot resolve the tool call and fails. Short single-token tool
names (`read`, `bash`) happen to survive, which masks the bug for simple tool
sets.

### Secondary finding

On `glm-4.6`, `"tool_choice": "required"` returns HTTP 400:
`{"code":400,"msg":"invalid request params"}` (provider AtlasCloud).
`"tool_choice": "auto"` is accepted. Possibly related (tool-call request
handling on the `glm-4.6` route).

### Request

Please fix the truncation of tool-call function names on the `glm-4.6` route so
it matches the other models on the endpoint.
