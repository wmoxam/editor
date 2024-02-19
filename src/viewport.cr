class Viewport
  property row_count : Int32 = 0
  property column_count : Int32 = 0
  property row_offset : Int32 = 0
  property column_offset : Int32 = 0
  property cursor_x : Int32 = 0
  property cursor_y : Int32 = 1
  property last_x : Int32 = 0
  property buffer : Buffer
  property screen_buffer : String::Builder

  property status_message : String = ""
  property status_time : Time = Time.local

  delegate filename, rendered_rows, rows, to: @buffer

  def initialize(buffer)
    @buffer = buffer
    @screen_buffer = String::Builder.new
    @status_message = "HELP: Ctrl-Q = quit"
    @status_time = Time.local

    get_window_size!
  end

  def end!
    @cursor_x = row_length
  end

  def file_row
    cursor_y + row_offset - 1
  end

  def home!
    @cursor_x = 0
  end

  def move_cursor(direction)
    case direction
    when KeyCommands::Left
      if at_beginning_of_line?
        if !at_beginning_of_file?
          move_cursor(KeyCommands::Up)

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

        move_cursor(KeyCommands::Down)
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

  def refresh_screen
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

  def row_length
    return 0 if rows.empty?

    rows[file_row].size
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
    end_range = cursor_x - 1
    if end_range >= 0
      cursor_x + (rows[file_row][0..end_range].scan(/\t/).size * (Editor::TAB_SPACES - 1))
    else
      cursor_x
    end
  end

  private def row_position
    cursor_x + column_offset
  end
end
