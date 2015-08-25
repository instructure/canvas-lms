require File.expand_path(File.dirname(__FILE__) + '/../common')

def verify_colors_for_arrays(color_text_field_array, color_box_array)
  # handle styling wih hex and rbg
  color_text_field_array.each_with_index do |x, index|
    if !color_box_array[index].attribute(:style).include?('rgb')
      expect(color_box_array[index].attribute(:style)).to include_text(x.attribute(:placeholder))
    else
      # convert to rgb
      hex = x.attribute(:placeholder)[1..-1]
      rgb_array = hex.scan(/../).map {|color| color.to_i(16)}
      color_string = "(#{rgb_array[0]}, #{rgb_array[1]}, #{rgb_array[2]})"

      expect(color_box_array[index].attribute(:style)).to include_text(color_string)
    end
  end
end

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