" rustdoc.vim - Automatic rustdoc management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Globals - Boiler plate {{{

if (&cp || get(g:, 'rustdoc_dont_load', 0))
    finish
endif

if v:version < 704
    echoerr "rustdoc: this plugin requires vim >= 7.4."
    finish
endif

let g:rustdoc_debug = get(g:, 'rustdoc_debug', 0)

if (exists('g:loaded_rustdoc') && !g:rustdoc_debug)
    finish
endif
if (exists('g:loaded_rustdoc') && g:rustdoc_debug)
    echom "Reloaded rustdoc."
endif
let g:loaded_rustdoc = 1

let g:rustdoc_trace = get(g:, 'rustdoc_trace', 0)

let g:rustdoc_enabled = get(g:, 'rustdoc_enabled', 1)

" }}}




" Globals - For border cases {{{


let g:rustdoc_project_root = get(g:, 'rustdoc_project_root', ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout'])

let g:rustdoc_project_root_finder = get(g:, 'rustdoc_project_root_finder', '')

let g:rustdoc_exclude_project_root = get(g:, 'rustdoc_exclude_project_root', 
            \['/usr/local', '/opt/homebrew', '/home/linuxbrew/.linuxbrew'])

let g:rustdoc_include_filetypes = get(g:, 'rustdoc_include_filetypes', ['rust'])
let g:rustdoc_resolve_symlinks = get(g:, 'rustdoc_resolve_symlinks', 0)
let g:rustdoc_generate_on_new = get(g:, 'rustdoc_generate_on_new', 1)
let g:rustdoc_generate_on_write = get(g:, 'rustdoc_generate_on_write', 1)
let g:rustdoc_generate_on_empty_buffer = get(g:, 'rustdoc_generate_on_empty_buffer', 0)

let g:rustdoc_init_user_func = get(g:, 'rustdoc_init_user_func', 
            \get(g:, 'rustdoc_enabled_user_func', ''))

let g:rustdoc_define_advanced_commands = get(g:, 'rustdoc_define_advanced_commands', 0)


" }}}




" Globals - The important stuff {{{

" rustdoc - Auto regen
let g:rustdoc_auto_regen = get(g:, 'rustdoc_auto_regen', 1)
let g:rustdoc_cmd = get(g:, 'rustdoc_cmd', 'rustdoc ')

" rustdoc - Open on browser
let g:rustdoc_browser_cmd = get(g:, 'rustdoc_browser_cmd', 'xdg-open')
let g:rustdoc_browser_file = get(g:, 'rustdoc_browser_file', '/docs/index.html')

" rustdoc - Verbose
let g:rustdoc_verbose_manual_regen = get(g:, 'rustdoc_verbose_open', '1')
let g:rustdoc_verbose_open = get(g:, 'rustdoc_verbose_open', '1')


" }}}




" rustdoc Setup {{{

augroup rustdoc_detect
    autocmd!
    autocmd BufNewFile,BufReadPost *  call rustdoc#setup_rustdoc()
    autocmd VimEnter               *  if expand('<amatch>')==''|call rustdoc#setup_rustdoc()|endif
augroup end

" }}}




" Misc Commands {{{

if g:rustdoc_define_advanced_commands
    command! RustdocToggleEnabled :let g:rustdoc_enabled=!g:rustdoc_enabled
    command! RustdocToggleTrace   :call rustdoc#toggletrace()
endif

" }}}

