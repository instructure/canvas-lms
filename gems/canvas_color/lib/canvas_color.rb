#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# Copyright (c) 2007 McClain Looney
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Implements a color (r,g,b + a) with conversion to/from web format (eg #aabbcc), and
# with a number of utilities to lighten, darken and blend values.
module CanvasColor
  class Color

    attr_reader :r, :g, :b, :a

    # Table for conversion to hex
    HEXVAL = (('0'..'9').to_a).concat(('A'..'F').to_a).freeze
    # Default value for #darken, #lighten etc.
    BRIGHTNESS_DEFAULT = 0.2

    NAMED_COLORS = {
      "aliceblue": "#f0f8ff",
      "antiquewhite": "#faebd7",
      "aqua": "#00ffff",
      "aquamarine": "#7fffd4",
      "azure": "#f0ffff",
      "beige": "#f5f5dc",
      "bisque": "#ffe4c4",
      "black": "#000000",
      "blanchedalmond": "#ffebcd",
      "blue": "#0000ff",
      "blueviolet": "#8a2be2",
      "brown": "#a52a2a",
      "burlywood": "#deb887",
      "cadetblue": "#5f9ea0",
      "chartreuse": "#7fff00",
      "chocolate": "#d2691e",
      "coral": "#ff7f50",
      "cornflowerblue": "#6495ed",
      "cornsilk": "#fff8dc",
      "crimson": "#dc143c",
      "cyan": "#00ffff",
      "darkblue": "#00008b",
      "darkcyan": "#008b8b",
      "darkgoldenrod": "#b8860b",
      "darkgray": "#a9a9a9",
      "darkgreen": "#006400",
      "darkgrey": "#a9a9a9",
      "darkkhaki": "#bdb76b",
      "darkmagenta": "#8b008b",
      "darkolivegreen": "#556b2f",
      "darkorange": "#ff8c00",
      "darkorchid": "#9932cc",
      "darkred": "#8b0000",
      "darksalmon": "#e9967a",
      "darkseagreen": "#8fbc8f",
      "darkslateblue": "#483d8b",
      "darkslategray": "#2f4f4f",
      "darkslategrey": "#2f4f4f",
      "darkturquoise": "#00ced1",
      "darkviolet": "#9400d3",
      "deeppink": "#ff1493",
      "deepskyblue": "#00bfff",
      "dimgray": "#696969",
      "dimgrey": "#696969",
      "dodgerblue": "#1e90ff",
      "firebrick": "#b22222",
      "floralwhite": "#fffaf0",
      "forestgreen": "#228b22",
      "fuchsia": "#ff00ff",
      "gainsboro": "#dcdcdc",
      "ghostwhite": "#f8f8ff",
      "gold": "#ffd700",
      "goldenrod": "#daa520",
      "gray": "#808080",
      "green": "#008000",
      "greenyellow": "#adff2f",
      "grey": "#808080",
      "honeydew": "#f0fff0",
      "hotpink": "#ff69b4",
      "indianred": "#cd5c5c",
      "indigo": "#4b0082",
      "ivory": "#fffff0",
      "khaki": "#f0e68c",
      "lavender": "#e6e6fa",
      "lavenderblush": "#fff0f5",
      "lawngreen": "#7cfc00",
      "lemonchiffon": "#fffacd",
      "lightblue": "#add8e6",
      "lightcoral": "#f08080",
      "lightcyan": "#e0ffff",
      "lightgoldenrodyellow": "#fafad2",
      "lightgray": "#d3d3d3",
      "lightgreen": "#90ee90",
      "lightgrey": "#d3d3d3",
      "lightpink": "#ffb6c1",
      "lightsalmon": "#ffa07a",
      "lightseagreen": "#20b2aa",
      "lightskyblue": "#87cefa",
      "lightslategray": "#778899",
      "lightslategrey": "#778899",
      "lightsteelblue": "#b0c4de",
      "lightyellow": "#ffffe0",
      "lime": "#00ff00",
      "limegreen": "#32cd32",
      "linen": "#faf0e6",
      "magenta": "#ff00ff",
      "maroon": "#800000",
      "mediumaquamarine": "#66cdaa",
      "mediumblue": "#0000cd",
      "mediumorchid": "#ba55d3",
      "mediumpurple": "#9370db",
      "mediumseagreen": "#3cb371",
      "mediumslateblue": "#7b68ee",
      "mediumspringgreen": "#00fa9a",
      "mediumturquoise": "#48d1cc",
      "mediumvioletred": "#c71585",
      "midnightblue": "#191970",
      "mintcream": "#f5fffa",
      "mistyrose": "#ffe4e1",
      "moccasin": "#ffe4b5",
      "navajowhite": "#ffdead",
      "navy": "#000080",
      "oldlace": "#fdf5e6",
      "olive": "#808000",
      "olivedrab": "#6b8e23",
      "orange": "#ffa500",
      "orangered": "#ff4500",
      "orchid": "#da70d6",
      "palegoldenrod": "#eee8aa",
      "palegreen": "#98fb98",
      "paleturquoise": "#afeeee",
      "palevioletred": "#db7093",
      "papayawhip": "#ffefd5",
      "peachpuff": "#ffdab9",
      "peru": "#cd853f",
      "pink": "#ffc0cb",
      "plum": "#dda0dd",
      "powderblue": "#b0e0e6",
      "purple": "#800080",
      "rebeccapurple": "#663399",
      "red": "#ff0000",
      "rosybrown": "#bc8f8f",
      "royalblue": "#4169e1",
      "saddlebrown": "#8b4513",
      "salmon": "#fa8072",
      "sandybrown": "#f4a460",
      "seagreen": "#2e8b57",
      "seashell": "#fff5ee",
      "sienna": "#a0522d",
      "silver": "#c0c0c0",
      "skyblue": "#87ceeb",
      "slateblue": "#6a5acd",
      "slategray": "#708090",
      "slategrey": "#708090",
      "snow": "#fffafa",
      "springgreen": "#00ff7f",
      "steelblue": "#4682b4",
      "tan": "#d2b48c",
      "teal": "#008080",
      "thistle": "#d8bfd8",
      "tomato": "#ff6347",
      "turquoise": "#40e0d0",
      "violet": "#ee82ee",
      "wheat": "#f5deb3",
      "white": "#ffffff",
      "whitesmoke": "#f5f5f5",
      "yellow": "#ffff00",
      "yellowgreen": "#9acd32"
    }.freeze

    # Constructor.  Inits to white (#FFFFFF) by default, or accepts any params
    # supported by #parse.
    def initialize(*args)
      @r = 255
      @g = 255
      @b = 255
      @a = 255

      if args.size.between?(3,4)
        self.r = args[0]
        self.g = args[1]
        self.b = args[2]
        self.a = args[3] if args[3]
      else
        set(*args)
      end
    end

    # All-purpose setter - pass in another Color, '#000000', rgb vals... whatever
    def set(*args)
      val = Color.parse(*args)
      unless val.nil?
        self.r = val.r
        self.g = val.g
        self.b = val.b
        self.a = val.a
      end
      self
    end

    # Test for equality, accepts string vals as well, eg Color.new('aaa') == '#AAAAAA' => true
    def ==(val)
      val = Color.parse(val)
      return false if val.nil?
      return r == val.r && g == val.g && b == val.b && a == val.a
    end

    # Setters for individual channels - take 0-255 or '00'-'FF' values
    def r=(val); @r = from_hex(val); end

    def g=(val); @g = from_hex(val); end

    def b=(val); @b = from_hex(val); end

    def a=(val); @a = from_hex(val); end

    # Attempt to read in a string and parse it into values
    def self.parse(*args)
      case args.size

      when 0 then
        return nil

      when 1 then
        val = args[0]

        # Trivial parse... :-)
        return val if val.is_a?(Color)

        # Single value, assume grayscale
        return Color.new(val, val, val) if val.is_a?(Integer)

        # Assume string
        str = val.to_s.upcase

        # handle html color names like "red" or "whitesmoke"
        found_hex_code = NAMED_COLORS[val.to_sym]
        return Color.new(found_hex_code) if found_hex_code

        str = str[/[0-9A-F]{3,8}/] || ''
        case str.size
        when 3, 4 then
          r, g, b, a = str.scan(/[0-9A-F]/)
        when 6,8 then
          r, g, b, a = str.scan(/[0-9A-F]{2}/)
        else
          return nil
        end

        return Color.new(r,g,b,a || 255)

      when 3,4 then
        return Color.new(*args)

      end
      nil
    end

    def inspect
      to_s(true)
    end

    def to_s(add_hash = true)
      trans? ? to_rgba(add_hash) : to_rgb(add_hash)
    end

    def to_rgb(add_hash = true)
      (add_hash ? '#' : '') + to_hex(r) + to_hex(g) + to_hex(b)
    end

    def to_rgba(add_hash = true)
      to_rgb(add_hash) + to_hex(a)
    end

    def opaque?
      @a == 255
    end

    def trans?
      @a != 255
    end

    def grayscale?
      @r == @g && @g == @b
    end

    # Lighten color towards white.  0.0 is a no-op, 1.0 will return #FFFFFF
    def lighten(amt = BRIGHTNESS_DEFAULT)
      return self if amt <= 0
      return WHITE if amt >= 1.0
      val = Color.new(self)
      val.r += ((255-val.r) * amt).to_i
      val.g += ((255-val.g) * amt).to_i
      val.b += ((255-val.b) * amt).to_i
      val
    end

    # In place version of #lighten
    def lighten!(amt = BRIGHTNESS_DEFAULT)
      set(lighten(amt))
      self
    end

    # Darken a color towards full black.  0.0 is a no-op, 1.0 will return #000000
    def darken(amt = BRIGHTNESS_DEFAULT)
      return self if amt <= 0
      return BLACK if amt >= 1.0
      val = Color.new(self)
      val.r -= (val.r * amt).to_i
      val.g -= (val.g * amt).to_i
      val.b -= (val.b * amt).to_i
      val
    end

    # In place version of #darken
    def darken!(amt = BRIGHTNESS_DEFAULT)
      set(darken(amt))
      self
    end

    # Convert to grayscale, using perception-based weighting
    def grayscale
      val = Color.new(self)
      val.r = val.g = val.b = (0.2126 * val.r + 0.7152 * val.g + 0.0722 * val.b)
      val
    end

    # In place version of #grayscale
    def grayscale!
      set(grayscale)
      self
    end

    # Blend to a color amt % towards another color value, eg
    # red.blend(blue, 0.5) will be purple, white.blend(black, 0.5) will be gray, etc.
    def blend(other, amt)
      other = Color.parse(other)
      return Color.new(self) if amt <= 0 || other.nil?
      return Color.new(other) if amt >= 1.0
      val = Color.new(self)
      val.r += ((other.r - val.r)*amt).to_i
      val.g += ((other.g - val.g)*amt).to_i
      val.b += ((other.b - val.b)*amt).to_i
      val
    end

    # In place version of #blend
    def blend!(other, amt)
      set(blend(other, amt))
      self
    end

    # Class-level version for explicit blends of two values, useful with constants
    def self.blend(col1, col2, amt)
      col1 = Color.parse(col1)
      col2 = Color.parse(col2)
      col1.blend(col2, amt)
    end

    protected

    # Convert int to string hex, eg 255 => 'FF'
    def to_hex(val)
      HEXVAL[val / 16] + HEXVAL[val % 16]
    end

    # Convert int or string to int, eg 80 => 80, 'FF' => 255, '7' => 119
    def from_hex(val)
      if val.is_a?(String)
        # Double up if single char form
        val = val + val if val.size == 1
        # Convert to integer
        val = val.hex
      end
      # Clamp
      val = 0 if val < 0
      val = 255 if val > 255
      val
    end

    public

    # Some constants for general use
    WHITE = Color.new(255,255,255).freeze
    BLACK = Color.new(0,0,0).freeze

  end

  # "Global" method for creating Color objects, eg:
  #   new_color = rgb(params[:new_color])
  #   style="border: 1px solid <%= rgb(10,50,80).lighten %>"
  def rgb(*args)
    Color.parse(*args)
  end
end
