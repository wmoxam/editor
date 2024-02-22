class Buffer
  property filename : String | Nil = nil
  property rendered_rows : Array(String) = [] of String
  property rows : Array(String) = [] of String

  def concat_rows_at_cursor(cursor)
    removed = rows.delete_at(cursor.file_row + 1)
    rendered_rows.delete_at(cursor.file_row + 1)

    rows[cursor.file_row] = rows[cursor.file_row] + removed
    rendered_rows[cursor.file_row] = render(rows[cursor.file_row])
  end

  def delete_at_cursor(cursor)
    rows[cursor.file_row] = rows[cursor.file_row].delete_at(cursor.row_position, 1)
    rendered_rows[cursor.file_row] = render(rows[cursor.file_row])
  end

  def insert_at_cursor(text, cursor, viewport)
    return if text.nil?

    rows[cursor.file_row] = rows[cursor.file_row].insert(cursor.row_position, text)
    rendered_rows[cursor.file_row] = render(rows[cursor.file_row])

    viewport.move_cursor(KeyCommands::Right)
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
