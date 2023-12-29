# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "termios"

class Editor
  VERSION = "0.1.0"

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
      if i == (rows / 3).to_i
        @buffer << "Wes's editor -- version #{VERSION}"
      else
        @buffer << "~"
      end
      @buffer << "\x1b[K" # erases the part of the line to the right of the cursor
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
    @buffer << "\x1b[?25l" # hide cursor
    @buffer << "\x1b[H"    # reposition cursor

    draw_rows

    @buffer << "\x1b[H"    # reposition cursor
    @buffer << "\x1b[?25h" # show cursor
    print buffer.to_s
  end

  # todo: get window size the hard way
  # https://viewsourcecode.org/snaptoken/kilo/03.rawInputAndOutput.html#window-size-the-hard-way
  private def get_window_size!
    STDOUT.print "\x1b[999C\x1b[999B"
    STDOUT.print "\x1b[6n"

    puts ""
    size = String::Builder.new

    STDIN.raw do |io|
      io.each_char do |c|
        unless c.nil?
          unless c.ascii_control?
            size << c
            break if c == 'R'
          end
        end
      end

      matches = size.to_s.match(/(\d+);(\d+)/)

      if matches
        _all, rows_s, cols_s = matches
        @columns = cols_s.to_i
        @rows = rows_s.to_i
      end
    end
  end
end

Editor.new.run
