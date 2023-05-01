" rustdoc.vim - Automatic rustdoc management for Vim
" Maintainer:   Zeioth
" Version:      1.0.0




" Path helper methods {{{

function! rustdoc#chdir(path)
    if has('nvim')
        let chdir = haslocaldir() ? 'lcd' : haslocaldir(-1, 0) ? 'tcd' : 'cd'
    else
        let chdir = haslocaldir() ? ((haslocaldir() == 1) ? 'lcd' : 'tcd') : 'cd'
    endif
    execute chdir fnameescape(a:path)
endfunction

" Throw an exception message.
function! rustdoc#throw(message)
    throw "rustdoc: " . a:message
endfunction

" Show an error message.
function! rustdoc#error(message)
    let v:errmsg = "rustdoc: " . a:message
    echoerr v:errmsg
endfunction

" Show a warning message.
function! rustdoc#warning(message)
    echohl WarningMsg
    echom "rustdoc: " . a:message
    echohl None
endfunction

" Prints a message if debug tracing is enabled.
function! rustdoc#trace(message, ...)
    if g:rustdoc_trace || (a:0 && a:1)
        let l:message = "rustdoc: " . a:message
        echom l:message
    endif
endfunction

" Strips the ending slash in a path.
function! rustdoc#stripslash(path)
    return fnamemodify(a:path, ':s?[/\\]$??')
endfunction

" Normalizes the slashes in a path.
function! rustdoc#normalizepath(path)
    if exists('+shellslash') && &shellslash
        return substitute(a:path, '\v/', '\\', 'g')
    elseif has('win32')
        return substitute(a:path, '\v/', '\\', 'g')
    else
        return a:path
    endif
endfunction

" Shell-slashes the path (opposite of `normalizepath`).
function! rustdoc#shellslash(path)
    if exists('+shellslash') && !&shellslash
        return substitute(a:path, '\v\\', '/', 'g')
    else
        return a:path
    endif
endfunction

" Returns whether a path is rooted.
if has('win32') || has('win64')
    function! rustdoc#is_path_rooted(path) abort
        return len(a:path) >= 2 && (
                    \a:path[0] == '/' || a:path[0] == '\' || a:path[1] == ':')
    endfunction
else
    function! rustdoc#is_path_rooted(path) abort
        return !empty(a:path) && a:path[0] == '/'
    endfunction
endif

" }}}




" rustdoc helper methods {{{

" Finds the first directory with a project marker by walking up from the given
" file path.
function! rustdoc#get_project_root(path) abort
    if g:rustdoc_project_root_finder != ''
        return call(g:rustdoc_project_root_finder, [a:path])
    endif
    return rustdoc#default_get_project_root(a:path)
endfunction

" Default implementation for finding project markers... useful when a custom
" finder (`g:rustdoc_project_root_finder`) wants to fallback to the default
" behaviour.
function! rustdoc#default_get_project_root(path) abort
    let l:path = rustdoc#stripslash(a:path)
    let l:previous_path = ""
    let l:markers = g:rustdoc_project_root[:]
    while l:path != l:previous_path
        for root in l:markers
            if !empty(globpath(l:path, root, 1))
                let l:proj_dir = simplify(fnamemodify(l:path, ':p'))
                let l:proj_dir = rustdoc#stripslash(l:proj_dir)
                if l:proj_dir == ''
                    call rustdoc#trace("Found project marker '" . root .
                                \"' at the root of your file-system! " .
                                \" That's probably wrong, disabling " .
                                \"rustdoc for this file...",
                                \1)
                    call rustdoc#throw("Marker found at root, aborting.")
                endif
                for ign in g:rustdoc_exclude_project_root
                    if l:proj_dir == ign
                        call rustdoc#trace(
                                    \"Ignoring project root '" . l:proj_dir .
                                    \"' because it is in the list of ignored" .
                                    \" projects.")
                        call rustdoc#throw("Ignore project: " . l:proj_dir)
                    endif
                endfor
                return l:proj_dir
            endif
        endfor
        let l:previous_path = l:path
        let l:path = fnamemodify(l:path, ':h')
    endwhile
    call rustdoc#throw("Can't figure out what file to use for: " . a:path)
endfunction

" }}}




" ============================================================================
" YOU PROBABLY ONLY CARE FROM HERE
" ============================================================================

" rustdoc Setup {{{

" Setup rustdoc for the current buffer.
function! rustdoc#setup_rustdoc() abort
    if exists('b:rustdoc_files') && !g:rustdoc_debug
        " This buffer already has rustdoc support.
        return
    endif

    " Don't setup rustdoc for anything that's not a normal buffer
    " (so don't do anything for help buffers and quickfix windows and
    "  other such things)
    " Also don't do anything for the default `[No Name]` buffer you get
    " after starting Vim.
    if &buftype != '' || 
          \(bufname('%') == '' && !g:rustdoc_generate_on_empty_buffer)
        return
    endif

    " We only want to use vim-rustdoc in the filetypes supported by rustdoc
    if index(g:rustdoc_include_filetypes, &filetype) == -1
        return
    endif

    " Let the user specify custom ways to disable rustdoc.
    if g:rustdoc_init_user_func != '' &&
                \!call(g:rustdoc_init_user_func, [expand('%:p')])
        call rustdoc#trace("Ignoring '" . bufname('%') . "' because of " .
                    \"custom user function.")
        return
    endif

    " Try and find what file we should manage.
    call rustdoc#trace("Scanning buffer '" . bufname('%') . "' for rustdoc setup...")
    try
        let l:buf_dir = expand('%:p:h', 1)
        if g:rustdoc_resolve_symlinks
            let l:buf_dir = fnamemodify(resolve(expand('%:p', 1)), ':p:h')
        endif
        if !exists('b:rustdoc_root')
            let b:rustdoc_root = rustdoc#get_project_root(l:buf_dir)
        endif
        if !len(b:rustdoc_root)
            call rustdoc#trace("no valid project root.. no rustdoc support.")
            return
        endif
        if filereadable(b:rustdoc_root . '/.norustdoc')
            call rustdoc#trace("'.norustdoc' file found... no rustdoc support.")
            return
        endif

        let b:rustdoc_files = {}
    catch /^rustdoc\:/
        call rustdoc#trace("No rustdoc support for this buffer.")
        return
    endtry

    " We know what file to manage! Now set things up.
    call rustdoc#trace("Setting rustdoc for buffer '".bufname('%')."'")

    " Autocommands for updating rustdoc on save.
    " We need to pass the buffer number to the callback function in the rare
    " case that the current buffer is changed by another `BufWritePost`
    " callback. This will let us get that buffer's variables without causing
    " errors.
    let l:bn = bufnr('%')
    execute 'augroup rustdoc_buffer_' . l:bn
    execute '  autocmd!'
    execute '  autocmd BufWritePost <buffer=' . l:bn . '> call s:write_triggered_update_rustdoc(' . l:bn . ')'
    execute 'augroup end'

    " Miscellaneous commands.
    command! -buffer -bang RustdocRegen :call s:manual_rustdoc_regen(<bang>0)
    command! -buffer -bang RustdocOpen :call s:rustdoc_open()

endfunction

" }}}




"  rustdoc Management {{{

" (Re)Generate the docs for the current project.
function! s:manual_rustdoc_regen(bufno) abort
    if g:rustdoc_enabled == 1
      "visual feedback"
      if g:rustdoc_verbose_manual_regen == 1
        echo 'Manually regenerating rustdoc documentation.'
      endif

      " Run async
      call s:update_rustdoc(a:bufno , 0, 2)
    endif
endfunction

" Open rustdoc in the browser.
function! s:rustdoc_open() abort
    try
        let l:bn = bufnr('%')
        let l:proj_dir = getbufvar(l:bn, 'rustdoc_root')

        "visual feedback"
        if g:rustdoc_verbose_open == 1
          echo g:rustdoc_browser_cmd . ' ' . l:proj_dir . g:rustdoc_browser_file
        endif
        call job_start(['sh', '-c', g:rustdoc_browser_cmd . ' ' . l:proj_dir . g:rustdoc_browser_file], {})
    endtry
endfunction

" (re)generate rustdoc for a buffer that just go saved.
function! s:write_triggered_update_rustdoc(bufno) abort
    if g:rustdoc_enabled && g:rustdoc_generate_on_write
      call s:update_rustdoc(a:bufno, 0, 2)
    endif
    silent doautocmd user rustdocupdating
endfunction

" update rustdoc for the current buffer's file.
" write_mode:
"   0: update rustdoc if it exists, generate it otherwise.
"   1: always generate (overwrite) rustdoc.
"
" queue_mode:
"   0: if an update is already in progress, report it and abort.
"   1: if an update is already in progress, abort silently.
"   2: if an update is already in progress, queue another one.
function! s:update_rustdoc(bufno, write_mode, queue_mode) abort
    " figure out where to save.
    let l:proj_dir = getbufvar(a:bufno, 'rustdoc_root')

    " Switch to the project root to make the command line smaller, and make
    " it possible to get the relative path of the filename.
    let l:prev_cwd = getcwd()
    call rustdoc#chdir(l:proj_dir)
    try
        
        " Generate the rustdoc docs where specified.
        if g:rustdoc_auto_regen == 1
          call job_start(['sh', '-c', g:rustdoc_cmd], {})

        endif       

    catch /^rustdoc\:/
        echom "Error while generating ".a:module." file:"
        echom v:exception
    finally
        " Restore the current directory...
        call rustdoc#chdir(l:prev_cwd)
    endtry
endfunction

" }}}
