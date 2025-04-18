local inputEnglish = "com.apple.keylayout.ABC"
local esc_bind

-- ESC 키를 눌렀을 때 영어로 전환하는 함수
function convert_to_eng_with_esc()
	local inputSource = hs.keycodes.currentSourceID()
	if not (inputSource == inputEnglish) then
		hs.eventtap.keyStroke({}, "right")
		hs.keycodes.currentSourceID(inputEnglish)
	end
	esc_bind:disable()
	hs.eventtap.keyStroke({}, "escape")
	esc_bind:enable()
end

-- Command+Tab을 눌렀을 때 영어로 전환하는 함수
function convert_to_eng_with_cmd_tab(event)
	local flags = event:getFlags()
	local keyCode = event:getKeyCode()

	-- Command가 눌린 상태에서 Tab 키가 눌렸는지 확인
	if flags.cmd and keyCode == hs.keycodes.map.tab then
		-- 영어 입력 소스로 변경
		hs.keycodes.currentSourceID(inputEnglish)
	end

	return false -- 이벤트를 시스템에 전달
end

-- ESC 키 핫키 설정
esc_bind = hs.hotkey.new({}, "escape", convert_to_eng_with_esc):enable()

-- Command+Tab 이벤트 감지기 설정
cmd_tab_watcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, convert_to_eng_with_cmd_tab)
cmd_tab_watcher:start()
