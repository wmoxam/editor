# A simple text editor
# Based on kilo, https://viewsourcecode.org/snaptoken/kilo/index.html

require "termios"

module Editor
  VERSION = "0.1.0"

  def self.run
    STDIN.raw do |input|
      while true
        c = '0'
        c = input.read_char
        if c.nil? || c == 'q'
          break
        else
          if c.ascii_control?
            print "#{c.bytes.to_s}\r\n"
          else
            print "#{c.bytes.to_s} ('#{c}')\r\n"
          end
        end
      end
    end
  end
end

Editor.run
