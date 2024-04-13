class Buffer
  property filename : String | Nil = nil
  property rendered_rows : Array(String) = [] of String
  property rows : Array(String) = [] of String

  def concat_rows_at_cursor(cursor)
    file_row = cursor.file_row
    removed = rows.delete_at(file_row + 1)
    rendered_rows.delete_at(file_row + 1)

    rows[file_row] = rows[file_row] + removed
    rendered_rows[file_row] = render(rows[file_row])
  end

  def delete_at_cursor(cursor)
    file_row = cursor.file_row
    rows[file_row] = rows[file_row].delete_at(cursor.row_position, 1)
    rendered_rows[file_row] = render(rows[file_row])
  end

  def insert_at_cursor(text, cursor, viewport)
    return if text.nil?

    file_row = cursor.file_row

    if text == '\r'
      # enter/return splits the line at the cursor
      before = after = ""
      if cursor.row_position == 0
        after = rows[file_row]
      else
        before = rows[file_row][0..(Math.max(cursor.row_position - 1, 0))]
        after = rows[file_row][(cursor.row_position)..rows[file_row].size - 1]
      end
      rows[file_row] = before
      rows.insert(file_row + 1, after)
      rendered_rows.insert(file_row, "")
      rendered_rows[file_row] = render(rows[file_row])
      rendered_rows[file_row + 1] = render(rows[file_row + 1])

      viewport.move_cursor(KeyCommands::Down)
      cursor.beginning_of_line!
    else
      rows[file_row] = rows[cursor.file_row].insert(cursor.row_position, text)
      rendered_rows[file_row] = render(rows[file_row])

      viewport.move_cursor(KeyCommands::Right)
    end
  end

  def open_file(filename)
    @filename = filename

    File.each_line(filename) do |line|
      rows << line.chomp
      rendered_rows << render(line)
    end
  end

  private def render(line)
    line.chomp.gsub(/\t/, " " * Editor::TAB_SPACES)
  end
end
