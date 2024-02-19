class Buffer
  property filename : String | Nil = nil
  property rendered_rows : Array(String) = [] of String
  property rows : Array(String) = [] of String

  def open_file(filename)
    @filename = filename

    File.each_line(filename) do |line|
      rows << line.chomp
      rendered_rows << line.chomp.gsub(/\t/, " " * Editor::TAB_SPACES)
    end
  end
end
