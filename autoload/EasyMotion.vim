" EasyMotion - Vim motions on speed!
"
" Author: Kim Silkebækken <kim.silkebaekken+vim@gmail.com>
" Source repository: https://github.com/Lokaltog/vim-easymotion

" Default configuration functions {{{
	function! EasyMotion#InitOptions(options) " {{{
		for [key, value] in items(a:options)
			if ! exists('g:EasyMotion_' . key)
				exec 'let g:EasyMotion_' . key . ' = ' . string(value)
			endif
		endfor
		" Reset Migemo Dictionary
		let s:migemo_dicts = {}
	endfunction " }}}
	function! EasyMotion#InitHL(group, colors) " {{{
		let group_default = a:group . 'Default'

		" Prepare highlighting variables
		let guihl = printf('guibg=%s guifg=%s gui=%s', a:colors.gui[0], a:colors.gui[1], a:colors.gui[2])
		if !exists('g:CSApprox_loaded')
			let ctermhl = &t_Co == 256
				\ ? printf('ctermbg=%s ctermfg=%s cterm=%s', a:colors.cterm256[0], a:colors.cterm256[1], a:colors.cterm256[2])
				\ : printf('ctermbg=%s ctermfg=%s cterm=%s', a:colors.cterm[0], a:colors.cterm[1], a:colors.cterm[2])
		else
			let ctermhl = ''
		endif

		" Create default highlighting group
		execute printf('hi default %s %s %s', group_default, guihl, ctermhl)

		" Check if the hl group exists
		if hlexists(a:group)
			redir => hlstatus | exec 'silent hi ' . a:group | redir END

			" Return if the group isn't cleared
			if hlstatus !~ 'cleared'
				return
			endif
		endif

		" No colors are defined for this group, link to defaults
		execute printf('hi default link %s %s', a:group, group_default)
	endfunction " }}}
	function! EasyMotion#InitMappings(motions) "{{{
		for motion in keys(a:motions)
			call EasyMotion#InitOptions({ 'mapping_' . motion : g:EasyMotion_leader_key . motion })
		endfor

		if g:EasyMotion_do_mapping
			for [motion, fn] in items(a:motions)
				if empty(g:EasyMotion_mapping_{motion})
					continue
				endif

				silent exec 'nnoremap <silent> ' . g:EasyMotion_mapping_{motion} . '      :call EasyMotion#' . fn.name . '(0, ' . fn.dir . ')<CR>'
				silent exec 'onoremap <silent> ' . g:EasyMotion_mapping_{motion} . '      :call EasyMotion#' . fn.name . '(0, ' . fn.dir . ')<CR>'
				silent exec 'vnoremap <silent> ' . g:EasyMotion_mapping_{motion} . ' :<C-U>call EasyMotion#' . fn.name . '(1, ' . fn.dir . ')<CR>'
			endfor
		endif
	endfunction "}}}

	function! EasyMotion#InitSpecialMappings(motions) "{{{
		for motion in keys(a:motions)
			call EasyMotion#InitOptions({ 'special_mapping_' . motion : g:EasyMotion_leader_key . motion })
		endfor

		if g:EasyMotion_do_mapping
			for [motion, fn] in items(a:motions)
				if empty(g:EasyMotion_special_mapping_{motion})
					continue
				endif

				if g:EasyMotion_special_{fn.flag}
					silent exec 'onoremap <silent> ' . g:EasyMotion_special_mapping_{motion} . ' :call EasyMotion#' . fn.name . '()<CR>'
					silent exec 'nnoremap <silent> v' . g:EasyMotion_special_mapping_{motion} . ' :call EasyMotion#' . fn.name . '()<CR>'
					silent exec 'nnoremap <silent> p' . g:EasyMotion_special_mapping_{motion} . ' :call EasyMotion#' . fn.name . 'Paste()<CR>'
					silent exec 'nnoremap <silent> y' . g:EasyMotion_special_mapping_{motion} . ' :call EasyMotion#' . fn.name . 'Yank()<CR>'
				endif
			endfor
		endif
	endfunction "}}}

" }}}
" Motion functions {{{
	function! EasyMotion#F(visualmode, direction) " {{{
		let char = s:GetSearchChar(a:visualmode)

		if empty(char)
			return
		endif

		let re = escape(char, '.$^~')

		if g:EasyMotion_use_migemo
			if ! has_key(s:migemo_dicts, &l:encoding)
				let s:migemo_dicts[&l:encoding] = s:load_migemo_dict()
			endif
			if re =~# '^\a$'
				let re = s:migemo_dicts[&l:encoding][re]
			endif
		endif

		if g:EasyMotion_smartcase && char =~# '\v\U'
			let re = '\c' . re
		else
			let re = '\C' . re
		endif

		call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', mode(1))
	endfunction " }}}
	function! EasyMotion#S(visualmode, direction) " {{{
		let char = s:GetSearchChar(a:visualmode)

		if empty(char)
			return
		endif

		let re = escape(char, '.$^~')

		if g:EasyMotion_use_migemo
			if ! has_key(s:migemo_dicts, &l:encoding)
				let s:migemo_dicts[&l:encoding] = s:load_migemo_dict()
			endif
			if re =~# '^\a$'
				let re = s:migemo_dicts[&l:encoding][re]
			endif
		endif

		if g:EasyMotion_smartcase && char =~# '\v\U'
			let re = '\c' . re
		else
			let re = '\C' . re
		endif

		call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', mode(1))
	endfunction " }}}
	function! EasyMotion#T(visualmode, direction) " {{{
		let char = s:GetSearchChar(a:visualmode)

		if empty(char)
			return
		endif

		let re = escape(char, '.$^~')

		if g:EasyMotion_use_migemo
			if ! has_key(s:migemo_dicts, &l:encoding)
				let s:migemo_dicts[&l:encoding] = s:load_migemo_dict()
			endif
			if re =~# '^\a$'
				let re = s:migemo_dicts[&l:encoding][re]
			endif
		endif

		if a:direction == 1
			" backward
			let re = re . '\zs.'
		else
			" forward
			let re = '.\ze' . re
		endif

		if g:EasyMotion_smartcase && char =~# '\v\U'
			let re = '\c' . re
		else
			let re = '\C' . re
		endif


		call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', mode(1))
	endfunction " }}}

	function! EasyMotion#WB(visualmode, direction) " {{{
		call s:EasyMotion('\(\<.\|^$\)', a:direction, a:visualmode ? visualmode() : '', '')
	endfunction " }}}
	function! EasyMotion#WBW(visualmode, direction) " {{{
		call s:EasyMotion('\(\(^\|\s\)\@<=\S\|^$\)', a:direction, a:visualmode ? visualmode() : '', '')
	endfunction " }}}
	function! EasyMotion#E(visualmode, direction) " {{{
		call s:EasyMotion('\(.\>\|^$\)', a:direction, a:visualmode ? visualmode() : '', mode(1))
	endfunction " }}}
	function! EasyMotion#EW(visualmode, direction) " {{{
		call s:EasyMotion('\(\S\(\s\|$\)\|^$\)', a:direction, a:visualmode ? visualmode() : '', mode(1))
	endfunction " }}}

	function! EasyMotion#JK(visualmode, direction) " {{{
		if g:EasyMotion_startofline
			call s:EasyMotion('^\(\w\|\s*\zs\|$\)', a:direction, a:visualmode ? visualmode() : '', '')
		else
			let prev_column = getpos('.')[2] - 1
			call s:EasyMotion('^.\{,' . prev_column . '}\zs\(.\|$\)', a:direction, a:visualmode ? visualmode() : '', '')
		endif
	endfunction " }}}
	function! EasyMotion#Search(visualmode, direction) " {{{
		call s:EasyMotion(@/, a:direction, a:visualmode ? visualmode() : '', '')
	endfunction " }}}

	function! EasyMotion#SelectLines() "{{{
		let orig_pos = [line('.'), col('.')]

		call s:EasyMotion('^\ze\(\w\|\s*\|$\)', 2, '', '', 0, 0, 1)
		if g:EasyMotion_cancelled
			keepjumps call cursor(orig_pos[0], orig_pos[1])
			return ''
		else
			let pos1 = [line('.'), col('.')]
			keepjumps call cursor(orig_pos[0], orig_pos[1])
			call s:EasyMotion('^\ze\(\w\|\s*\|$\)', 2, '', '', 0, 0, 1)
			if g:EasyMotion_cancelled
				keepjumps call cursor(orig_pos[0], orig_pos[1])
				return ''
			else
				normal! V
				keepjumps call cursor(pos1[0], pos1[1])
			endif
		endif
	endfunction "}}}
	function! EasyMotion#SelectLinesYank() "{{{
		let orig_pos = [line('.'), col('.')]
		call EasyMotion#SelectLines()
		normal y
		keepjumps call cursor(orig_pos[0], orig_pos[1])
		"normal p
	endfunction "}}}
	function! EasyMotion#SelectLinesPaste() "{{{
		let orig_pos = [line('.'), col('.')]
		call EasyMotion#SelectLines()
		normal y
		keepjumps call cursor(orig_pos[0], orig_pos[1])
		if !g:EasyMotion_cancelled
			normal p
		endif
	endfunction "}}}

	function! EasyMotion#SelectPhrase() "{{{
		let chars = s:GetSearchChar2(0)
		if empty(chars)
			return
		endif

		let orig_pos = [line('.'), col('.')]

		if g:EasyMotion_smartcase && chars[0] =~# '\v\U' || chars[1] =~# '\v\U'
			let re = '\c'
		else
			let re = '\C'
		endif

		let re = re . escape(chars[0], '.$^~') . '\|' . escape(chars[1], '.$^~')
		call s:EasyMotion(re, 2, '', '', 0, 0, 0, 0)
		if g:EasyMotion_cancelled
			keepjumps call cursor(orig_pos[0], orig_pos[1])
			return ''
		else
			let pos1 = [line('.'), col('.')]
			keepjumps call cursor(orig_pos[0], orig_pos[1])
			call s:EasyMotion(re, 2, '', '', 0, 0, 0, pos1)
			if g:EasyMotion_cancelled
				keepjumps call cursor(orig_pos[0], orig_pos[1])
				return ''
			else
				normal! v
				keepjumps call cursor(pos1[0], pos1[1])
			endif
		endif
	endfunction "}}}
	function! EasyMotion#SelectPhraseYank() "{{{
		let orig_pos = [line('.'), col('.')]

		call EasyMotion#SelectPhrase()
		normal y
		keepjumps call cursor(orig_pos[0], orig_pos[1])
	endfunction "}}}
	function! EasyMotion#SelectPhrasePaste() "{{{
		let orig_pos = [line('.'), col('.')]
		call EasyMotion#SelectPhrase()
		normal y
		keepjumps call cursor(orig_pos[0], orig_pos[1])
		if !g:EasyMotion_cancelled
			normal p
		endif
	endfunction "}}}

" }}}
" Helper functions {{{
	function! s:Message(message) " {{{
		echo 'EasyMotion: ' . a:message
	endfunction " }}}
	function! s:Prompt(message) " {{{
		echohl Question
		echo a:message . ': '
		echohl None
	endfunction " }}}
	function! s:VarReset(var, ...) " {{{
		if ! exists('s:var_reset')
			let s:var_reset = {}
		endif

		if a:0 == 0 && has_key(s:var_reset, a:var)
			" Reset var to original value
			call setbufvar("", a:var, s:var_reset[a:var])
		elseif a:0 == 1
			let new_value = a:0 == 1 ? a:1 : ''

			" Store original value
			let s:var_reset[a:var] = getbufvar("", a:var)

			" Set new var value
			call setbufvar("", a:var, new_value)
		endif
	endfunction " }}}
	function! s:SetLines(lines, key) " {{{
		try
			" Try to join changes with previous undo block
			undojoin
		catch
		endtry

		for [line_num, line] in a:lines
			call setline(line_num, line[a:key])
		endfor
	endfunction " }}}
	function! s:GetChar() " {{{
		let char = getchar()

		if char == 27
			" Escape key pressed
			redraw

			call s:Message('Cancelled')

			return ''
		endif

		return nr2char(char)
	endfunction " }}}

	function! s:GetSearchChar2(visualmode) " {{{

		let chars = []
		for i in [1, 2]
			redraw

			call s:Prompt('Search for character ' . i)
			let char = s:GetChar()

			" Check that we have an input char
			if empty(char)
				" Restore selection
				if ! empty(a:visualmode)
					silent exec 'normal! gv'
				endif

				return ''
			endif
			call add(chars, char)
		endfor

		return chars
	endfunction " }}}
	function! s:GetSearchChar(visualmode) " {{{
		call s:Prompt('Search for character')

		let char = s:GetChar()

		" Check that we have an input char
		if empty(char)
			" Restore selection
			if ! empty(a:visualmode)
				silent exec 'normal! gv'
			endif

			return ''
		endif

		return char
	endfunction " }}}

function! s:load_migemo_dict() "{{{
    let enc = &l:encoding
    if enc ==# 'utf-8'
        return EasyMotion#migemo#utf8#load_dict()
    elseif enc ==# 'cp932'
        return EasyMotion#migemo#cp932#load_dict()
    elseif enc ==# 'euc-jp'
        return EasyMotion#migemo#eucjp#load_dict()
    else
        let g:EasyMotion_use_migemo = 0
        throw "Error: ".enc." is not supported. Migemo is made disabled."
    endif
endfunction "}}}
" }}}
" Grouping algorithms {{{
	let s:grouping_algorithms = {
	\   1: 'SCTree'
	\ , 2: 'Original'
	\ }
	" Single-key/closest target priority tree {{{
		" This algorithm tries to assign one-key jumps to all the targets closest to the cursor.
		" It works recursively and will work correctly with as few keys as two.
		function! s:GroupingAlgorithmSCTree(targets, keys)
			" Prepare variables for working
			let targets_len = len(a:targets)
			let keys_len = len(a:keys)

			let groups = {}

			let keys = reverse(copy(a:keys))

			" Semi-recursively count targets {{{
				" We need to know exactly how many child nodes (targets) this branch will have
				" in order to pass the correct amount of targets to the recursive function.

				" Prepare sorted target count list {{{
					" This is horrible, I know. But dicts aren't sorted in vim, so we need to
					" work around that. That is done by having one sorted list with key counts,
					" and a dict which connects the key with the keys_count list.

					let keys_count = []
					let keys_count_keys = {}

					let i = 0
					for key in keys
						call add(keys_count, 0)

						let keys_count_keys[key] = i

						let i += 1
					endfor
				" }}}

				let targets_left = targets_len
				let level = 0
				let i = 0

				while targets_left > 0
					" Calculate the amount of child nodes based on the current level
					let childs_len = (level == 0 ? 1 : (keys_len - 1) )

					for key in keys
						" Add child node count to the keys_count array
						let keys_count[keys_count_keys[key]] += childs_len

						" Subtract the child node count
						let targets_left -= childs_len

						if targets_left <= 0
							" Subtract the targets left if we added too many too
							" many child nodes to the key count
							let keys_count[keys_count_keys[key]] += targets_left

							break
						endif

						let i += 1
					endfor

					let level += 1
				endwhile
			" }}}
			" Create group tree {{{
				let i = 0
				let key = 0

				call reverse(keys_count)

				for key_count in keys_count
					if key_count > 1
						" We need to create a subgroup
						" Recurse one level deeper
						let groups[a:keys[key]] = s:GroupingAlgorithmSCTree(a:targets[i : i + key_count - 1], a:keys)
					elseif key_count == 1
						" Assign single target key
						let groups[a:keys[key]] = a:targets[i]
					else
						" No target
						continue
					endif

					let key += 1
					let i += key_count
				endfor
			" }}}

			" Finally!
			return groups
		endfunction
	" }}}
	" Original {{{
		function! s:GroupingAlgorithmOriginal(targets, keys)
			" Split targets into groups (1 level)
			let targets_len = len(a:targets)
			let keys_len = len(a:keys)

			let groups = {}

			let i = 0
			let root_group = 0
			try
				while root_group < targets_len
					let groups[a:keys[root_group]] = {}

					for key in a:keys
						let groups[a:keys[root_group]][key] = a:targets[i]

						let i += 1
					endfor

					let root_group += 1
				endwhile
			catch | endtry

			" Flatten the group array
			if len(groups) == 1
				let groups = groups[a:keys[0]]
			endif

			return groups
		endfunction
	" }}}
	" Coord/key dictionary creation {{{
		function! s:CreateCoordKeyDict(groups, ...)
			" Dict structure:
			" 1,2 : a
			" 2,3 : b
			let sort_list = []
			let coord_keys = {}
			let group_key = a:0 == 1 ? a:1 : ''

			for [key, item] in items(a:groups)
				let key = ( ! empty(group_key) ? group_key.key : key)

				if type(item) == 3
					" Destination coords

					" The key needs to be zero-padded in order to
					" sort correctly
					let dict_key = printf('%05d,%05d', item[0], item[1])
					let coord_keys[dict_key] = key

					" We need a sorting list to loop correctly in
					" PromptUser, dicts are unsorted
					call add(sort_list, dict_key)
				else
					" Item is a dict (has children)
					let coord_key_dict = s:CreateCoordKeyDict(item, key)

					" Make sure to extend both the sort list and the
					" coord key dict
					call extend(sort_list, coord_key_dict[0])
					call extend(coord_keys, coord_key_dict[1])
				endif

				unlet item
			endfor

			return [sort_list, coord_keys]
		endfunction
	" }}}
" }}}
" Core functions {{{
	function! s:PromptUser(groups, allows_repeat, fixed_column) "{{{

		" If only one possible match, jump directly to it {{{
			let group_values = values(a:groups)

			if len(group_values) == 1
				redraw

				return group_values[0]
			endif
		" }}}
		" Prepare marker lines {{{
			let lines = {}
			let hl_coords = []
			let hl_coords_sub = []
			let coord_key_dict = s:CreateCoordKeyDict(a:groups)

			for dict_key in sort(coord_key_dict[0])
				let target_key = coord_key_dict[1][dict_key]
				let [line_num, col_num] = split(dict_key, ',')

				let line_num = str2nr(line_num)
				let col_num = str2nr(col_num)

				" Add original line and marker line
				if ! has_key(lines, line_num)
					let current_line = getline(line_num)

					let lines[line_num] = { 'orig': current_line, 'marker': current_line, 'mb_compensation': 0 }
				endif

				" Solve multibyte issues by matching the byte column
				" number instead of the visual column
				let col_num -= lines[line_num]['mb_compensation']

				" Compensate for byte difference between marker
				" character and target character
				"
				" This has to be done in order to match the correct
				" column; \%c matches the byte column and not display
				" column.
				let target_key_len = strlen(target_key)
				let target_key_width = strdisplaywidth(target_key)
				let target_char = matchstr(lines[line_num]['marker'], '\%' . col_num . 'c.')
				let i = 2
				while target_key_width > strdisplaywidth(target_char) && i <= target_key_width
					let target_char = matchstr(lines[line_num]['marker'], '\%' . col_num . 'c'.repeat('.',i))
					let i += 1
				endwhile
				unlet i
				let target_char_len = strlen(target_char)
				let target_char_width = strdisplaywidth(target_char)

				if strlen(lines[line_num]['marker']) > 0
					" Substitute marker character if line length > 0
					let padding_len = max([target_char_width - target_key_width, 0])
					let padding = repeat(' ', padding_len)
					let target_key_len += padding_len
					let target_key = target_key . repeat(' ', padding_len)
					let target_char_charlen = strlen(substitute(target_char,'.','x','g'))
					let lines[line_num]['marker'] = substitute(lines[line_num]['marker'], '\%' . col_num . 'c'.repeat('.', target_char_charlen), target_key, '')
				else
				" Set the line to the marker character if the line is empty
					let lines[line_num]['marker'] = target_key
				endif

				" Add highlighting coordinates
				call add(hl_coords, '\%' . line_num . 'l\%' . col_num . 'c.')
				if target_key_len > 1
					call add(hl_coords_sub, '\%' . line_num . 'l\%' . (col_num + 1) . 'c' . repeat('.', target_key_len - 1))
				endif

				" Add marker/target lenght difference for multibyte
				" compensation
				let lines[line_num]['mb_compensation'] += (target_char_len - target_key_len)
			endfor


		let lines_items = items(lines)
		" }}}
		" Highlight targets {{{
			let target_hl_id = matchadd(g:EasyMotion_hl_group_target, join(hl_coords, '\|'), 1)
			if !empty(hl_coords_sub)
				let target_hl_sub_id = matchadd(g:EasyMotion_hl_group_target_sub, join(hl_coords_sub, '\|'), 1)
			endif
		" }}}

		try
			" Set lines with markers
			call s:SetLines(lines_items, 'marker')

			redraw

			" Get target character {{{
				call s:Prompt('Target key')

				let char = s:GetChar()
			" }}}
		finally
			" Restore original lines
			call s:SetLines(lines_items, 'orig')

			" Un-highlight targets {{{
				if exists('target_hl_id')
					call matchdelete(target_hl_id)
				endif
				if exists('target_hl_sub_id')
					call matchdelete(target_hl_sub_id)
				endif
			" }}}

			redraw
		endtry

		" Check if we have an input char {{{
			if empty(char)
				throw 'Cancelled'
			endif
		" }}}
		" Check if the input char is valid {{{
		if a:allows_repeat && char == '.'
			return g:old_target
		else
			if ! has_key(a:groups, char)
				throw 'Invalid target'
			endif
		" }}}

			let target = a:groups[char]

			if type(target) == 3
				" Return target coordinates
				return target
			else
				" Prompt for new target character
				return s:PromptUser(target, a:allows_repeat, a:fixed_column)
			endif
		endif
	endfunction "}}}

	function! s:EasyMotion(regexp, direction, visualmode, mode, ...) " {{{
		" For SelectLines(), to highlight previous selected line
		let hlcurrent = a:0 >= 1 ? a:1 : 0
		" For SelectLines(), to allows '.' to repeat the previously pressed
		" character
		let allows_repeat = a:0 >= 2 ? a:2 : 0
		" For SelectLines(), a flag to display character only at the beginning
		" of the line
		let fixed_column = a:0 >= 3 ? a:3 : 0

		let hlchar = a:0 >= 4 ? a:4 : 0

		let orig_pos = [line('.'), col('.')]
		let targets = []

		try
			" Reset properties {{{
				call s:VarReset('&scrolloff', 0)
				call s:VarReset('&modified', 0)
				call s:VarReset('&modifiable', 1)
				call s:VarReset('&readonly', 0)
				call s:VarReset('&spell', 0)
				call s:VarReset('&virtualedit', '')
                call s:VarReset('&foldmethod', 'manual')
			" }}}
			" Find motion targets {{{
				let search_direction = (a:direction >= 1 ? 'b' : '')
				let search_stopline = line(a:direction >= 1 ? 'w0' : 'w$')

				let search_at_cursor = fixed_column ? 'c' : ''
				while 1
					let pos = searchpos(a:regexp, search_direction . search_at_cursor, search_stopline)
					let search_at_cursor = ''

					" Reached end of search range
					if pos == [0, 0]
						break
					endif

					" Skip folded lines
					if foldclosed(pos[0]) != -1 && (g:EasyMotion_skipfoldedline == 1 || pos[0] != foldclosed(pos[0]))
						continue
					endif

					call add(targets, pos)
				endwhile

				if a:direction == 2
					keepjumps call cursor(orig_pos[0], orig_pos[1])
					let targets2 = []
					while 1
						let pos = searchpos(a:regexp, '', line('w$'))
						if pos == [0, 0]
							break
						endif

						if foldclosed(pos[0]) != -1 && (g:EasyMotion_skipfoldedline == 1 || pos[0] != foldclosed(pos[0]))
							continue
						endif

						call add(targets2, pos)
					endwhile
					let t1 = 0
					let t2 = 0
					let targets3 = []
					while t1 < len(targets) || t2 < len(targets2)
						if t1 < len(targets)
							call add(targets3, targets[t1])
							let t1 += 1
						endif
						if t2 < len(targets2)
							call add(targets3, targets2[t2])
							let t2 += 1
						endif
					endwhile
					let targets = targets3

				endif

				let targets_len = len(targets)
				if targets_len == 0
					throw 'No matches'
				endif
			" }}}

			let GroupingFn = function('s:GroupingAlgorithm' . s:grouping_algorithms[g:EasyMotion_grouping])
			let groups = GroupingFn(targets, split(g:EasyMotion_keys, '\zs'))

			" Shade inactive source {{{
				if g:EasyMotion_do_shade
					let shade_hl_pos = '\%' . orig_pos[0] . 'l\%'. orig_pos[1] .'c'

					if a:direction == 1
						" Backward
						let shade_hl_re = '\%'. line('w0') .'l\_.*' . shade_hl_pos
					elseif a:direction == 0
						" Forward
						let shade_hl_re = shade_hl_pos . '\_.*\%'. line('w$') .'l'
					elseif a:direction == 2
						" Both directions"
						let shade_hl_re = '\%'. line('w0') .'l\_.*\%'. line('w$') .'l'
					endif
					if !fixed_column
						let shade_hl_id = matchadd(g:EasyMotion_hl_group_shade, shade_hl_re, 0)
					endif
				endif
				if hlcurrent != 0
					let shade_hl_line_id = matchadd(g:EasyMotion_hl_line_group_shade, '\%'. hlcurrent .'l.*', 1)
				endif
				if !empty(hlchar)
					let shade_hl_line_id = matchadd(g:EasyMotion_hl_line_group_shade, '\%'. hlchar[0] .'l\%' . hlchar[1] .'c' , 2)
				endif
			" }}}

			" Prompt user for target group/character
			let coords = s:PromptUser(groups, allows_repeat, fixed_column)
			let g:old_target = coords

			" Update selection {{{
				if ! empty(a:visualmode)
					keepjumps call cursor(orig_pos[0], orig_pos[1])

					exec 'normal! ' . a:visualmode
				endif
			" }}}
			" Handle operator-pending mode {{{
				if a:mode == 'no'
					" This mode requires that we eat one more
					" character to the right if we're using
					" a forward motion
					if a:direction != 1
						let coords[1] += 1
					endif
				endif
			" }}}

			" Update cursor position
			call cursor(orig_pos[0], orig_pos[1])
			let mark_save = getpos("'e")
			call setpos("'e", [bufnr('%'), coords[0], coords[1], 0])
			execute 'normal! `e'
			call setpos("'e", mark_save)

			call s:Message('Jumping to [' . coords[0] . ', ' . coords[1] . ']')
			let g:EasyMotion_cancelled = 0
		catch
			redraw

			" Show exception message
			call s:Message(v:exception)

			" Restore original cursor position/selection {{{
				if ! empty(a:visualmode)
					silent exec 'normal! gv'
				else
					keepjumps call cursor(orig_pos[0], orig_pos[1])
				endif
			" }}}
			let g:EasyMotion_cancelled = 1
		finally
			" Restore properties {{{
				call s:VarReset('&scrolloff')
				call s:VarReset('&modified')
				call s:VarReset('&modifiable')
				call s:VarReset('&readonly')
				call s:VarReset('&spell')
				call s:VarReset('&virtualedit')
                call s:VarReset('&foldmethod')
			" }}}
			" Remove shading {{{
				if g:EasyMotion_do_shade && exists('shade_hl_id') && (!fixed_column)
					call matchdelete(shade_hl_id)
				endif
				if (hlcurrent || !empty(hlchar)) && exists('shade_hl_line_id')
					call matchdelete(shade_hl_line_id)
				endif
			" }}}
		endtry
	endfunction " }}}
" }}}

" vim: fdm=marker:noet:ts=4:sw=4:sts=4
