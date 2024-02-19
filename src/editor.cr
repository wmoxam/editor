# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "./buffer"
require "./key_commands"
require "./key_mapper"
require "./viewport"

class Editor
  VERSION = "0.1.0"

  TAB_SPACES = 2

  property buffer : Buffer
  property viewport : Viewport

  property screen_buffer : String::Builder

  property status_message : String = ""
  property status_time : Time = Time.local

  delegate column_count, column_offset, cursor_x, cursor_y, editor_move_cursor,
    file_row, last_x, row_count, row_length, row_offset, to: @viewport

  delegate filename, open_file, rows, rendered_rows, to: @buffer

  def initialize
    @buffer = Buffer.new

    if ARGV.size > 0
      open_file(ARGV[0])
    end

    @viewport = Viewport.new(buffer)
    @status_message = "HELP: Ctrl-Q = quit"
    @status_time = Time.local
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
      @screen_buffer << "\r\n"
    end
  end

  private def draw_status_bar
    status = "#{(filename || "[No name]")[0..19]} - #{rows.size} lines"
    right_status = "#{[rows.size, cursor_y + row_offset].min}/#{rows.size}"

    @screen_buffer << "\x1b[7m"
    @screen_buffer << status[0, column_count]
    if status.size + 1 + right_status.size <= column_count
      @screen_buffer << " " * (column_count - status.size - right_status.size)
      @screen_buffer << right_status
    elsif column_count - status.size > 0
      @screen_buffer << " " * (column_count - status.size)
    end
    @screen_buffer << "\x1b[m"
    @screen_buffer << "\r\n"
  end

  private def draw_message_bar
    @screen_buffer << "\x1b[K"
    @screen_buffer << status_message[0, column_count] if (Time.local - status_time).seconds < 5
  end

  private def rendered_cursor_x
    end_range = cursor_x - 1
    if end_range >= 0
      cursor_x + (rows[file_row][0..end_range].scan(/\t/).size * (TAB_SPACES - 1))
    else
      cursor_x
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
    draw_status_bar
    draw_message_bar

    @screen_buffer << "\x1b[#{cursor_y};#{rendered_cursor_x + 1}H" # reposition cursor
    @screen_buffer << "\x1b[?25h"                                  # show cursor
    print screen_buffer.to_s
  end
end

Editor.new.run
