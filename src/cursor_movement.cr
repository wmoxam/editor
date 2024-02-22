class CursorMovement
  property cursor : Cursor
  property viewport : Viewport

  delegate at_beginning_of_file?, at_beginning_of_line?, column_offset,
    file_row, last_x, row_offset, row_position, x, y, to: @cursor
  delegate at_end_of_file?, at_end_of_line?, column_count, row_count, row_length, rows, to: @viewport

  Left  = KeyCommands::Left
  Right = KeyCommands::Right
  Down  = KeyCommands::Down
  Up    = KeyCommands::Up

  def initialize(cursor, viewport)
    @cursor = cursor
    @viewport = viewport
  end

  def move(direction)
    case direction
    when Left
      if at_beginning_of_line?
        if !at_beginning_of_file?
          move(Up)

          @cursor.x = [row_length, column_count].min
          @cursor.column_offset = [0, row_length - column_count].max
          @cursor.last_x = 0
        end

        return
      end

      @cursor.last_x = 0
      @cursor.x -= 1
      @cursor.column_offset -= 1 if x == 0 && column_offset > 0
    when Right
      if at_end_of_line?
        return if at_end_of_file?

        @cursor.column_offset = 0
        @cursor.x = 0
        @cursor.last_x = 0

        move(Down)
        return
      end

      @cursor.last_x = 0

      if x < column_count - 1
        @cursor.x += 1
      else
        @cursor.column_offset += 1
      end
    when Up
      @cursor.y -= 1 if y > 1
      @cursor.row_offset -= 1 if y == 1 && row_offset > 0

      if last_x > 0
        @cursor.column_offset = 0
        @cursor.x = last_x
      end

      if row_position >= row_length
        @cursor.last_x = row_position
        @cursor.column_offset = 0
        @cursor.x = row_length
      end
    when Down
      return if at_end_of_file?

      if y < row_count
        @cursor.y += 1
      elsif (file_row) < rows.size - 1
        @cursor.row_offset += 1
      end

      if last_x > 0
        @cursor.column_offset = 0
        @cursor.x = last_x
      end

      if row_position >= row_length
        @cursor.last_x = row_position
        @cursor.column_offset = 0
        @cursor.x = row_length
      end
    end
  end
end
