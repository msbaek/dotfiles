-- key mapping for vim
-- Convert input soruce as English and sends 'escape' if inputSource is not English.
-- Sends 'escape' if inputSource is English.
-- key bindding reference --> https://www.hammerspoon.org/docs/hs.hotkey.html
-- local inputEnglish = "com.apple.keylayout.ABC"
-- local inputEnglish = "com.apple.keylayout.Roman"
local inputEnglish = "com.apple.keylayout.ABC"
local esc_bind

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

function input_eng()
	-- local input_source = hs.keycodes.currentSourceID()
	-- if not (input_source == inputEnglish) then
	hs.keycodes.currentSourceID(inputEnglish)
	-- end
end

-- hs.hotkey.bind({ "cmd", "shift" }, "V", function()
-- 	local clipboard = hs.pasteboard.getContents()
-- 	local converted = "![](ATTACHMENTS/" .. string.gsub(clipboard, " ", "%%20") .. ")"
-- 	hs.pasteboard.setContents(converted)
-- 	hs.notify
-- 		.new({ title = "변환 완료", informativeText = "변환된 텍스트가 클립보드에 복사되었습니다." })
-- 		:send()
-- end)

-- hs.hotkey.bind({}, 'tab', input_eng)

esc_bind = hs.hotkey.new({}, "escape", convert_to_eng_with_esc):enable()
