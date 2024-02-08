# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "./key_commands"
require "./key_mapper"

class Editor
  VERSION = "0.1.0"

  TAB_SPACES = 2

  property rendered_rows : Array(String) = [] of String
  property rows : Array(String) = [] of String
  property row_offset : Int32 = 0
  property column_offset : Int32 = 0

  property row_count : Int32 = 0
  property column_count : Int32 = 0

  property cursor_x : Int32 = 0
  property cursor_y : Int32 = 1
  property last_x : Int32 = 0

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
        this_row = rendered_rows[buffer_row]
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
      if at_beginning_of_line?
        if !at_beginning_of_file?
          editor_move_cursor(KeyCommands::Up)

          @cursor_x = [row_length, column_count].min
          @column_offset = [0, row_length - column_count].max
          @last_x = 0
        end

        return
      end

      @last_x = 0
      @cursor_x -= 1
      @column_offset -= 1 if cursor_x == 0 && column_offset > 0
    when KeyCommands::Right
      if at_end_of_line?
        return if at_end_of_file?

        @column_offset = 0
        @cursor_x = 0
        @last_x = 0

        editor_move_cursor(KeyCommands::Down)
        return
      end

      @last_x = 0

      if cursor_x < column_count - 1
        @cursor_x += 1
      elsif !at_end_of_line?
        @column_offset += 1
      end
    when KeyCommands::Up
      @cursor_y -= 1 if cursor_y > 1
      @row_offset -= 1 if cursor_y == 1 && row_offset > 0

      if last_x > 0
        @column_offset = 0
        @cursor_x = last_x
      end

      if at_end_of_line?
        @last_x = row_position
        @column_offset = 0
        @cursor_x = row_length
      end
    when KeyCommands::Down
      return if at_end_of_file?

      if cursor_y < row_count
        @cursor_y += 1
      elsif (file_row) < rows.size - 1
        @row_offset += 1
      end

      if last_x > 0
        @column_offset = 0
        @cursor_x = last_x
      end

      if at_end_of_line?
        @last_x = row_position
        @column_offset = 0
        @cursor_x = row_length
      end
    end
  end

  private def at_beginning_of_line?
    cursor_x < 1
  end

  private def at_beginning_of_file?
    file_row == 0
  end

  private def at_end_of_file?
    file_row >= rows.size - 1
  end

  private def at_end_of_line?
    row_position >= row_length
  end

  private def file_row
    cursor_y + row_offset - 1
  end

  private def rendered_cursor_x
    end_range = cursor_x - 1
    if end_range >= 0
      cursor_x + (rows[file_row][0..end_range].scan(/\t/).size * (TAB_SPACES - 1))
    else
      cursor_x
    end
  end

  private def row_length
    return 0 if rows.empty?

    rows[file_row].size
  end

  private def row_position
    cursor_x + column_offset
  end

  private def open_file(filename)
    File.each_line(filename) do |line|
      rows << line.chomp
      rendered_rows << line.chomp.gsub(/\t/, " " * TAB_SPACES)
    end
  end

  private def process_keypresses(io)
    mapper = KeyMapper.new(io)

    case mapper.command
    when KeyCommands::Home
      @cursor_x = 0
    when KeyCommands::End
      @cursor_x = row_length
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

    @screen_buffer << "\x1b[#{cursor_y};#{rendered_cursor_x + 1}H" # reposition cursor
    @screen_buffer << "\x1b[?25h"                                  # show cursor
    print screen_buffer.to_s
  end
end

Editor.new.run
