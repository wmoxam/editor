require "./key_commands"

class KeyMapper
  property io : IO
  property read_char : Char?

  MOVEMENTS = [KeyCommands::Up, KeyCommands::Down, KeyCommands::Left, KeyCommands::Right]

  def initialize(io)
    @io = io
    @read_char = io.read_char
  end

  def command
    @command ||= begin
      char = @read_char

      unless char.nil?
        if char.ascii_control?
          case char.bytes.first
          when ctrl_key('q')
            KeyCommands::Quit
          when '\e'
            seq1 = io.read_char
            case seq1
            when '['
              seq2 = io.read_char
              case seq2
              when 'A'
                KeyCommands::Up
              when 'B'
                KeyCommands::Down
              when 'C'
                KeyCommands::Right
              when 'D'
                KeyCommands::Left
              when /\d/
                seq3 = io.read_char
                if seq3 == '~'
                  case seq2
                  when '5' # page up
                    KeyCommands::PageUp
                  when '6' # page down
                    KeyCommands::PageDown
                  end
                end
              end
            end
          end
        else
          case char.bytes.first
          when 'w'
            KeyCommands::Up
          when 's'
            KeyCommands::Down
          when 'a'
            KeyCommands::Left
          when 'd'
            KeyCommands::Right
          end
        end
      end
    end
  end

  def movement?
    MOVEMENTS.includes?(command)
  end

  private def ctrl_key(char)
    char.bytes.first & 0x1f
  end
end
