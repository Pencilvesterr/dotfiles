" ------ GENERAL -------
" Don't try to be vi compatible
set nocompatible
" Security
set modelines=0
" Encoding
set encoding=utf-8
" Allow hidden buffers
set hidden


" ------ UI / APPEARANCE -------
" Turn on syntax highlighting
syntax on
" Show line numbers
set number
" Show file stats
set ruler
" Status bar
set laststatus=2
" Last line
set showmode
set showcmd
" Rendering
set ttyfast
" Color scheme (terminal)
" colorscheme dracula

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default


" ------ WHITESPACE / FORMATTING -------
" set wrap
" set textwidth=88
set formatoptions=cqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround
" use % to jump between pairs, including < >
set matchpairs+=<:>
runtime! macros/matchit.vim


" ------ SEARCH -------
nnoremap / /\v
vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch


" ------ CURSOR & SCROLLING -------
set scrolloff=15
set backspace=indent,eol,start

" Cursor shape: steady bar in insert, steady block in normal, underline in replace
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"
let &t_SR = "\e[4 q"
" Reset cursor on start (for older versions of vim)
augroup myCmds
  au!
  autocmd VimEnter * silent !echo -ne "\e[2 q"
augroup END

set ttimeout
set ttimeoutlen=1

" Hybrid line numbers: relative in normal mode, absolute in insert mode
set number
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END


" ------ CLIPBOARD & REGISTERS -------
" Use clipboard for yanking+pasting, avoid using clipboard when deleting
set clipboard=unnamed
" Deleting goes to null register
nnoremap d ""d
nnoremap dd ""dd
vnoremap d ""d
nnoremap x ""x
vnoremap x ""x
nnoremap C ""C
vnoremap C ""C
nnoremap c ""c
vnoremap c ""c
" Paste without overwriting clipboard (visual mode)
xnoremap p "_dP
xnoremap P "_dP

" Copy and paste to system clipboard with command key (WezTerm sends these char sequences)
vnoremap <Char-0xAB> "+x
nnoremap <Char-0xAB> yydd
vnoremap <Char-0xAC> "+y
nnoremap <Char-0xAC> "+y

" ------ MAPPINGS -------
" Ensure space isn't mapped to anything before making it the leader key
nnoremap <SPACE> <Nop>
" Set leader key as space
let mapleader = " "

" Motion remaps
map H ^
map L $
map J }
map K {


" Scrolling — keep cursor centred
nnoremap z zz
nnoremap G Gzz
nnoremap gg ggzz

" Clear search highlight
nnoremap <CR> :noh<CR><CR>
map <leader><space> :let @/=''<cr>

" macOS-style word deletion with Alt+Backspace in insert mode
inoremap <M-BS> <C-w>

" Remap help key
inoremap <F1> <ESC>:set invfullscreen<CR>a
nnoremap <F1> :set invfullscreen<CR>
vnoremap <F1> :set invfullscreen<CR>



" ------ PLUGINS -------
" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin()
Plug 'unblevable/quick-scope'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" LSP for coding
Plug 'dense-analysis/ale'
" Smooth scroll
Plug 'yuttie/comfortable-motion.vim'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'junegunn/vim-peekaboo'
" {} will also jump to lines with only whitespace
Plug 'dbakker/vim-paragraph-motion'
" Highlight copied text
Plug 'machakann/vim-highlightedyank'
" Press s and then two chars to highlight/jump to that position
Plug 'easymotion/vim-easymotion'
call plug#end()

map s <Plug>(easymotion-s2)
" Bottom vim-airline theme
let g:airline_theme='bubblegum'
" Use quickscope only when pressing one of these keys
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
