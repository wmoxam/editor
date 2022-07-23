# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "termios"
require "./ioctl"

class Editor
  property rows : Int32 = 0
  property columns : Int32 = 0

  def initialize
    get_window_size!
  end

  def run
    STDIN.raw do |io|
      while true
        refresh_screen

        unless process_keypresses(io)
          refresh_screen
          Process.exit(0)
        end
      end
    end
  end

  private def ctrl_key(char)
    char.bytes.first & 0x1f
  end

  private def drawRows
    @rows.times do |i|
      print "~"

      print "\r\n" unless i == @rows - 1
    end
  end

  private def process_keypresses(io)
    c = io.read_char

    unless c.nil?
      if c.ascii_control?
        case c.bytes.first
        when ctrl_key('q')
          return false
        else
          print "#{c.bytes.to_s}\r\n"
        end
      else
        print "#{c.bytes.to_s} ('#{c}')\r\n"
      end
    end

    true
  end

  private def refresh_screen
    print "\x1b[2J"
    print "\x1b[H"

    drawRows

    print "\x1b[H"
  end

  private def get_window_size!
    LibC.ioctl(1, LibC::TIOCGWINSZ, out screen_size)
    @rows = screen_size.ws_col.to_i - 1
    @columns = screen_size.ws_row.to_i - 2
  end
end

Editor.new.run
