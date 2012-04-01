require 'thor/shell/color'

class Jefe::ColorPrinter
	Color = Thor::Shell::Color
	COLORS = [:cyan, :yellow, :green, :magenta, :red]
	def initialize
		@colors ||= {"system" => :white}
		@longest_seen = 0
	end
	def set_color color, string
		color = Color.const_get color.to_s.upcase
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
	def out name, command
		type = name.match(/^([A-Za-z0-9_]+).\d+$/) ? $1 : name
		color = color_for type
		puts set_color(color, "#{datetime} #{padded name} | ")  + command.chomp
	end
end