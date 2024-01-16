# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "./key_commands"
require "./key_mapper"

class Editor
  VERSION = "0.1.0"

  property rows : Array(String) = [] of String
  property row_offset : Int32 = 0
  property column_offset : Int32 = 0

  property row_count : Int32 = 0
  property column_count : Int32 = 0

  property cursor_x : Int32 = 1
  property cursor_y : Int32 = 1

  property screen_buffer : String::Builder

  def initialize
    get_window_size!
    if ARGV.size > 0
      open_file(ARGV[0])
    end
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
    row_count.times do |editor_row|
      buffer_row = editor_row + row_offset
      if buffer_row + 1 > rows.size
        if editor_row == (row_count / 3).to_i && rows.empty?
          welcome_msg = "Wes's editor -- version #{VERSION}"[0..column_count - 1]
          padding = (column_count - welcome_msg.size) / 2
          @screen_buffer << "#{" " * padding.to_i}#{welcome_msg}"
        else
          @screen_buffer << "~"
        end
      else
        this_row = rows[buffer_row]
        buffer_column = [column_offset, this_row.size].min
        @screen_buffer << this_row[buffer_column, column_count]
      end
      @screen_buffer << "\x1b[K" # erases the part of the line to the right of the cursor
      @screen_buffer << "\r\n" unless editor_row == row_count - 1
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
        @column_count = cols_s.to_i
        @row_count = rows_s.to_i
      else
        puts "Could not determine screen size, exiting"
        Process.exit(0)
      end
    end
  end

  private def editor_move_cursor(direction)
    case direction
    when KeyCommands::Left
      @cursor_x -= 1 if cursor_x > 1
      @column_offset -= 1 if cursor_x == 1 && column_offset > 0
    when KeyCommands::Right
      if cursor_x < column_count
        @cursor_x += 1
      elsif (cursor_x + column_offset) >= column_count
        @column_offset += 1
      end
    when KeyCommands::Up
      @cursor_y -= 1 if cursor_y > 1
      @row_offset -= 1 if cursor_y == 1 && row_offset > 0
    when KeyCommands::Down
      if cursor_y < row_count
        @cursor_y += 1
      elsif (cursor_y + row_offset) < rows.size
        @row_offset += 1
      end
    end
  end

  private def open_file(filename)
    File.each_line(filename) do |line|
      rows << line.chomp
    end
  end

  private def process_keypresses(io)
    mapper = KeyMapper.new(io)

    case mapper.command
    when KeyCommands::Home
      @cursor_x = 0
    when KeyCommands::End
      @cursor_x = column_count
    when KeyCommands::PageUp
      row_count.times { editor_move_cursor KeyCommands::Up }
    when KeyCommands::PageDown
      row_count.times { editor_move_cursor KeyCommands::Down }
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
