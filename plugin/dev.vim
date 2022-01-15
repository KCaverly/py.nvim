function! ReloadAlpha()
lua << EOF
    for k in pairs(package.loaded) do 
        if k:match("^poetry") then
            package.loaded[k] = nil
        end
    end
EOF
endfunction

" Reload the plugin
nnoremap <Leader>prb :call ReloadAlpha()<CR>
