module Diakonos

module KeyCode
    KEYSTRINGS = [
        "ctrl+space",   # 0
        "ctrl+a",       # 1
        "ctrl+b",       # 2
        "ctrl+c",       # 3
        "ctrl+d",       # 4
        "ctrl+e",       # 5
        "ctrl+f",       # 6
        "ctrl+g",       # 7
        nil,            # 8
        "tab",          # 9
        "ctrl+j",       # 10
        "ctrl+k",       # 11
        "ctrl+l",       # 12
        "enter",        # 13
        "ctrl+n",       # 14
        "ctrl+o",       # 15
        "ctrl+p",       # 16
        "ctrl+q",       # 17
        "ctrl+r",       # 18
        "ctrl+s",       # 19
        "ctrl+t",       # 20
        "ctrl+u",       # 21
        "ctrl+v",       # 22
        "ctrl+w",       # 23
        "ctrl+x",       # 24
        "ctrl+y",       # 25
        "ctrl+z",       # 26
        "esc",          # 27
        nil,            # 28
        nil,            # 29
        nil,            # 30
        nil,            # 31
        "space",        # 32
        33.chr, 34.chr, 35.chr, 36.chr, 37.chr, 38.chr, 39.chr,
        40.chr, 41.chr, 42.chr, 43.chr, 44.chr, 45.chr, 46.chr, 47.chr, 48.chr, 49.chr,
        50.chr, 51.chr, 52.chr, 53.chr, 54.chr, 55.chr, 56.chr, 57.chr, 58.chr, 59.chr,
        60.chr, 61.chr, 62.chr, 63.chr, 64.chr, 65.chr, 66.chr, 67.chr, 68.chr, 69.chr,
        70.chr, 71.chr, 72.chr, 73.chr, 74.chr, 75.chr, 76.chr, 77.chr, 78.chr, 79.chr,
        80.chr, 81.chr, 82.chr, 83.chr, 84.chr, 85.chr, 86.chr, 87.chr, 88.chr, 89.chr,
        90.chr, 91.chr, 92.chr, 93.chr, 94.chr, 95.chr, 96.chr, 97.chr, 98.chr, 99.chr,
        100.chr, 101.chr, 102.chr, 103.chr, 104.chr, 105.chr, 106.chr, 107.chr, 108.chr, 109.chr,
        110.chr, 111.chr, 112.chr, 113.chr, 114.chr, 115.chr, 116.chr, 117.chr, 118.chr, 119.chr,
        120.chr, 121.chr, 122.chr, 123.chr, 124.chr, 125.chr, 126.chr,
        "backspace"    # 127
    ]

    def keyString
        if self.class == Fixnum
            retval = KEYSTRINGS[ self ]
        end
        if retval.nil?
            case self
                when Curses::KEY_DOWN
                    retval = "down"
                when Curses::KEY_UP
                    retval = "up"
                when Curses::KEY_LEFT
                    retval = "left"
                when Curses::KEY_RIGHT
                    retval = "right"
                when Curses::KEY_HOME
                    retval = "home"
                when Curses::KEY_END
                    retval = "end"
                when Curses::KEY_IC
                    retval = "insert"
                when Curses::KEY_DC
                    retval = "delete"
                when Curses::KEY_PPAGE
                    retval = "page-up"
                when Curses::KEY_NPAGE
                    retval = "page-down"
                when Curses::KEY_A1
                    retval = "numpad7"
                when Curses::KEY_A3
                    retval = "numpad9"
                when Curses::KEY_B2
                    retval = "numpad5"
                when Curses::KEY_C1
                    retval = "numpad1"
                when Curses::KEY_C3
                    retval = "numpad3"
                when Curses::KEY_FIND
                    retval = "find"
                when Curses::KEY_SELECT
                    retval = "select"
                when Curses::KEY_SUSPEND
                    retval = "suspend"
                when Curses::KEY_F0..(Curses::KEY_F0 + 24)
                    retval = "f" + (self - Curses::KEY_F0).to_s
                when CTRL_H
                    retval = "ctrl+h"
                when Curses::KEY_RESIZE
                    retval = "resize"
                when RESIZE2
                    retval = "resize2"
            end
        end
        if retval.nil? and self.class == Fixnum
            retval = "keycode#{self}"
        end
        retval
    end
end

end