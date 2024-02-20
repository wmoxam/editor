require "./cursor"
require "./cursor_movement"
require "./status_message"

class Viewport
  property row_count : Int32 = 0
  property column_count : Int32 = 0

  property cursor : Cursor
  property buffer : Buffer
  property screen_buffer : String::Builder

  property status_message : StatusMessage

  delegate filename, rendered_rows, rows, to: @buffer
  delegate column_offset, file_row, row_offset, row_position, to: @cursor

  def initialize(buffer)
    @screen_buffer = String::Builder.new
    @status_message = StatusMessage.new("HELP: Ctrl-Q = quit")
    @status_time = Time.local

    @buffer = buffer
    @cursor = Cursor.new

    get_window_size!
  end

  def cursor_movement
    @cursor_movement ||= CursorMovement.new(cursor, self)
  end

  def delete_char
    buffer.delete_at_cursor(cursor, self)
  end

  def end!
    cursor.x = row_length
  end

  def home!
    @cursor.x = 0
  end

  def insert(text)
    buffer.insert_at_cursor(text, cursor, self)
  end

  def move_cursor(direction)
    cursor_movement.move(direction)
  end

  def refresh_screen
    @screen_buffer = String::Builder.new
    @screen_buffer << "\x1b[?25l" # hide cursor
    @screen_buffer << "\x1b[H"    # reposition cursor

    draw_rows
    draw_status_bar
    draw_message_bar

    @screen_buffer << "\x1b[#{cursor.y};#{rendered_cursor_x + 1}H" # reposition cursor
    @screen_buffer << "\x1b[?25h"                                  # show cursor
    print screen_buffer.to_s
  end

  def row_length
    return 0 if rows.empty?

    rows[file_row].size
  end

  private def draw_rows
    row_count.times do |editor_row|
      buffer_row = editor_row + row_offset
      if buffer_row + 1 > rows.size
        if editor_row == (row_count / 3).to_i && rows.empty?
          welcome_msg = "Wes's editor -- version #{Editor::VERSION}"[0..column_count - 1]
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
    right_status = "#{[rows.size, cursor.y + row_offset].min}/#{rows.size}"

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
    @screen_buffer << status_message.message[0, column_count] if status_message.visible?
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
        @row_count = rows_s.to_i - 2
      else
        puts "Could not determine screen size, exiting"
        Process.exit(0)
      end
    end
  end

  private def rendered_cursor_x
    end_range = cursor.x - 1
    if end_range >= 0
      cursor.x + (rows[file_row][0..end_range].scan(/\t/).size * (Editor::TAB_SPACES - 1))
    else
      cursor.x
    end
  end
end
