class Cursor
  property column_offset : Int32 = 0
  property last_x : Int32 = 0
  property row_offset : Int32 = 0
  property x : Int32 = 0
  property y : Int32 = 1

  def file_row
    y + row_offset - 1
  end

  def row_position
    x + column_offset
  end
end
