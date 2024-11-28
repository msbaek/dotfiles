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

-- 이미지 경로 변환을 위한 함수
function convertImagePath()
	local clipboard = hs.pasteboard.getContents()

	-- Pasted image로 시작하는지 확인
	if string.match(clipboard, "^Pasted image") then
		local converted = "![](ATTACHMENTS/" .. string.gsub(clipboard, " ", "%%20") .. ")"
		hs.pasteboard.setContents(converted)

		-- 성공 알림 표시
		hs.notify
			.new({
				title = "변환 완료",
				informativeText = "마크다운 이미지 경로가 클립보드에 복사되었습니다.",
				soundName = "Purr", -- 맥 알림음 추가
			})
			:send()
	else
		-- 잘못된 형식일 경우 경고 알림
		hs.notify
			.new({
				title = "변환 실패",
				informativeText = "클립보드의 내용이 'Pasted image'로 시작하지 않습니다.",
				soundName = "Basso",
			})
			:send()
	end
end

-- Command + Shift + V 단축키 설정
hs.hotkey.bind({ "cmd", "shift" }, "V", convertImagePath)

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
