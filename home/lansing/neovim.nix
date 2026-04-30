{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;

    plugins = with pkgs.vimPlugins; [
      dracula-vim
      vim-devicons
      ultisnips
      vim-snippets
      nerdtree
      nerdcommenter
      vim-startify
      coc-nvim
    ];

    extraConfig = ''
      set nocompatible
      set showmatch
      set ignorecase
      set hlsearch
      set incsearch
      set tabstop=4
      set softtabstop=4
      set expandtab
      set shiftwidth=4
      set autoindent
      set number
      set wildmode=longest,list
      filetype plugin indent on
      syntax on
      set mouse=a
      set clipboard=unnamedplus
      set cursorline

      silent! colorscheme dracula

      nnoremap <C-n> :NERDTreeToggle<CR>
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l
      inoremap jk <Esc>
      inoremap kj <Esc>
      inoremap <A-j> <Esc>:m .+1<CR>==gi
      inoremap <A-k> <Esc>:m .-2<CR>==gi
      vnoremap <A-j> :m '>+1<CR>gv=gv
      vnoremap <A-k> :m '<-2<CR>gv=gv
    '';
  };
}
