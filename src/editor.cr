# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "termios"
require "./ioctl"

class Editor
  property rows : Int32 = 0
  property columns : Int32 = 0
  property buffer : String::Builder

  def initialize
    get_window_size!
    @buffer = String::Builder.new
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

  private def draw_rows
    rows.times do |i|
      @buffer << "~"

      @buffer << "\r\n" unless i == rows - 1
    end
  end

  private def process_keypresses(io)
    c = io.read_char

    unless c.nil?
      if c.ascii_control?
        case c.bytes.first
        when ctrl_key('q')
          return false
        end
      end
    end

    true
  end

  private def refresh_screen
    @buffer = String::Builder.new
    @buffer << "\x1b[2J"
    @buffer << "\x1b[H"

    draw_rows

    @buffer << "\x1b[H"
    print buffer.to_s
  end

  # todo: get window size the hard way
  # https://viewsourcecode.org/snaptoken/kilo/03.rawInputAndOutput.html#window-size-the-hard-way
  private def get_window_size!
    LibC.ioctl(1, LibC::TIOCGWINSZ, out screen_size)
    @rows = screen_size.ws_col.to_i - 1
    @columns = screen_size.ws_row.to_i - 2
  end
end

Editor.new.run
