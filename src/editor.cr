# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "./key_commands"
require "./key_mapper"

class Editor
  VERSION = "0.1.0"

  property rows : Int32 = 0
  property columns : Int32 = 0

  property cursor_x : Int32 = 1
  property cursor_y : Int32 = 1

  property screen_buffer : String::Builder

  def initialize
    get_window_size!
    @screen_buffer = String::Builder.new
  end

  def run
    STDIN.raw do |io|
      while true
        refresh_screen
        break unless process_keypresses(io)
      end

      print "\x1b[2J"
      print "\x1b[H"
    end
  end

  private def draw_rows
    rows.times do |i|
      if i == (rows / 3).to_i
        welcome_msg = "Wes's editor -- version #{VERSION}"[0..columns - 1]
        padding = (columns - welcome_msg.size) / 2
        @screen_buffer << "#{" " * padding.to_i}#{welcome_msg}"
      else
        @screen_buffer << "~"
      end
      @screen_buffer << "\x1b[K" # erases the part of the line to the right of the cursor
      @screen_buffer << "\r\n" unless i == rows - 1
    end
  end

  # https://viewsourcecode.org/snaptoken/kilo/03.rawInputAndOutput.html#window-size-the-hard-way
  private def get_window_size!
    print "\x1b[999C\x1b[999B"
    print "\x1b[6n"

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
      else
        puts "Could not determine screen size, exiting"
        Process.exit(0)
      end
    end
  end

  private def editor_move_cursor(direction)
    case direction
    when KeyCommands::Left
      @cursor_x -= 1 if @cursor_x > 1
    when KeyCommands::Right
      @cursor_x += 1 if @cursor_x < columns
    when KeyCommands::Up
      @cursor_y -= 1 if @cursor_y > 1
    when KeyCommands::Down
      @cursor_y += 1 if @cursor_y < rows
    end
  end

  private def process_keypresses(io)
    mapper = KeyMapper.new(io)

    case mapper.command
    when KeyCommands::PageUp
      rows.times { editor_move_cursor KeyCommands::Up }
    when KeyCommands::PageDown
      rows.times { editor_move_cursor KeyCommands::Down }
    when KeyCommands::Quit
      return false
    else
      editor_move_cursor(mapper.command) if mapper.movement?
    end

    true
  end

  private def refresh_screen
    @screen_buffer = String::Builder.new
    @screen_buffer << "\x1b[?25l" # hide cursor
    @screen_buffer << "\x1b[H"    # reposition cursor

    draw_rows

    @screen_buffer << "\x1b[#{cursor_y};#{cursor_x}H" # reposition cursor
    @screen_buffer << "\x1b[?25h"                     # show cursor
    print screen_buffer.to_s
  end
end

Editor.new.run
