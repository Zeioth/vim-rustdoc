# vim-rustdoc
Out of the box, this plugin automatically regenerates your rustdoc
documentation. Currently, this plugin is in highly experimental state.

## Dependencies
None. Rust ships with this tool.

## Documentation
Please use <:h rustdoc> on vim to read the [full documentation](https://github.com/Zeioth/vim-rustdoc/blob/main/doc/rustdoc.txt).

## How to use

You just need to define the next keybindings (you MUST setup this)

```
" Shortcuts to open and generate docs
nmap <silent> <C-k> :<C-u>rustdocRegen<CR>
nmap <silent> <C-h> :<C-u>rustdocOpen<CR>
```

Enable automated doc generation on save (optional)
```
let g:rustdoc_auto_regen = 1

" rustdoc - Open on browser
let g:rustdoc_browser_cmd = get(g:, 'rustdoc_browser_cmd', 'xdg-open')
let g:rustdoc_browser_file = get(g:, 'rustdoc_browser_file', './docs/index.html')
```

Custom command to generate the rustdoc documentation (optional)

```
let g:rustdoc_cmd = get(g:, 'rustdoc_cmd', 'rustdoc')
```

Change the way the root of the project is detected (optional)

```
" By default, we detect the root of the project where the first .git file is found
let g:rustdoc_project_root = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_FOSSIL_', '.fslckout']
```

## Final notes

Please have in mind that you are responsable for adding your rustdoc directory to the .gitignore if you don't want it to be pushed by accident.

It is also possible to disable this plugin for a single project. For that, create .norustdoc file in the project root directory.

## Credits
This project started as a hack of [vim-doxygen](https://github.com/Zeioth/vim-doxygen), which started as a hack of [vim-guttentags](https://github.com/ludovicchabant/vim-gutentags). We use its boiler plate functions to manage directories in vimscript with good compatibility across operative systems. So please support its author too if you can!
