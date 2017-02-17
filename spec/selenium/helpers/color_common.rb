require File.expand_path(File.dirname(__FILE__) + '/../common')

module ColorCommon
  def convert_hex_to_rgb_color(hex_color)
    hex_color = hex_color[1..-1]
    rgb_array = hex_color.scan(/../).map {|color| color.to_i(16)}
    "(#{rgb_array[0]}, #{rgb_array[1]}, #{rgb_array[2]})"
  end

  def random_hex_color
    values = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
    color = "#" + values.sample + values.sample + values.sample + values.sample + values.sample + values.sample
    color
  end
end
