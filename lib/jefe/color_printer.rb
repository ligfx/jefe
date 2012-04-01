require 'thor/shell/color'

class Jefe::ColorPrinter
	Color = Thor::Shell::Color
	COLORS = %w{CYAN YELLOW GREEN MAGENTA RED}
	def initialize
		@colors = {"system" => "WHITE"}
		@longest_seen = 0
	end
	def colored color, string
		color = Color.const_get color
		"#{color}#{string}#{Color::CLEAR}"
	end
	def color_for type
		@colors[type] ||= COLORS.shift.tap {|c| COLORS.push c}
	end
	def padded name
		@longest_seen = name.size if name.size > @longest_seen
		name.ljust(@longest_seen)
	end
	def datetime
		Time.now.strftime '%H:%M:%S'
	end
	def out name, msg
		type = name.match(/^([A-Za-z0-9_]+).\d+$/) ? $1 : name
		color = color_for type
		puts colored(color, "#{datetime} #{padded name} | ")  + msg.chomp
	end
end