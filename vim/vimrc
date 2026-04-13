" ================================
"  Minimal & Solid Vimrc
"  For C / System Programming
" ================================

" ---- 基础 ----
set nocompatible
filetype plugin indent on
syntax on

" ---- 显示 ----

set number
set relativenumber

" 相对行号：冷色、偏灰，不像正文数字
highlight LineNr guifg=#5a5f6a ctermfg=8

" 当前行号：稍亮但不刺眼
highlight CursorLineNr guifg=#c0c5ce ctermfg=7

" 当前行背景不强调，避免噪音
highlight CursorLine ctermbg=NONE guibg=NONE
set cursorline          " 高亮当前行
set showcmd             " 显示未完成命令
set ruler               " 显示光标位置
set scrolloff=5         " 上下保留行

" ---- 搜索 ----
set hlsearch
set incsearch
set ignorecase
set smartcase

" ---- 缩进（C 友好）----
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent

" ---- 编辑体验 ----
set backspace=indent,eol,start
set wildmenu
set wildmode=longest:full,full
set nowrap               " 不自动换行（代码友好）

" ---- 文件 / 备份 ----
set backup
set undofile
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//

" 自动创建目录
if !isdirectory(expand("~/.vim/undo"))
  call mkdir(expand("~/.vim/undo"), "p")
endif
if !isdirectory(expand("~/.vim/backup"))
  call mkdir(expand("~/.vim/backup"), "p")
endif
if !isdirectory(expand("~/.vim/swap"))
  call mkdir(expand("~/.vim/swap"), "p")
endif

" ---- 剪贴板 ----
set clipboard=unnamedplus

" ---- 编码 ----
set encoding=utf-8
set fileencodings=utf-8,gbk,latin1

" ---- C 语言专属 ----
augroup c_settings
  autocmd!
  autocmd FileType c,cpp setlocal cindent
augroup END

" ---- 常用快捷键 ----
let mapleader=" "

" 快速保存 / 退出
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" 清除搜索高亮
nnoremap <leader><space> :nohlsearch<CR>

" 更符合直觉的行首行尾
nnoremap H ^
nnoremap L $

" ---- 性能 ----
set lazyredraw
set ttyfast

