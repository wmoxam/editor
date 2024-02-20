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

  delegate insert, move_cursor, refresh_screen, row_count, to: @viewport
  delegate open_file, to: @buffer

  def initialize
    @buffer = Buffer.new

    if ARGV.size > 0
      open_file(ARGV[0])
    end

    @viewport = Viewport.new(buffer)
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

  private def process_keypresses(io)
    mapper = KeyMapper.new(io)

    case mapper.command
    when KeyCommands::Home
      viewport.home!
    when KeyCommands::End
      viewport.end!
    when KeyCommands::PageUp
      row_count.times { move_cursor KeyCommands::Up }
    when KeyCommands::PageDown
      row_count.times { move_cursor KeyCommands::Down }
    when KeyCommands::Quit
      return false
    else
      if mapper.movement?
        move_cursor mapper.command
      else
        insert mapper.read_char
      end
    end

    true
  end
end

Editor.new.run
