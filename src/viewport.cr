class Viewport
  property row_count : Int32 = 0
  property column_count : Int32 = 0
  property row_offset : Int32 = 0
  property column_offset : Int32 = 0
  property cursor_x : Int32 = 0
  property cursor_y : Int32 = 1
  property last_x : Int32 = 0
  property buffer : Buffer

  delegate rendered_rows, rows, to: @buffer

  def initialize(buffer)
    @buffer = buffer
    get_window_size!
  end

  def editor_move_cursor(direction)
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

  def file_row
    cursor_y + row_offset - 1
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

  private def row_position
    cursor_x + column_offset
  end
end
