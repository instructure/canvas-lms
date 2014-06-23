require "yaml"

module LuckySneaks
  module Unidecoder
    # Contains Unicode codepoints, loading as needed from YAML files
    CODEPOINTS = Hash.new { |h, k|
      h[k] = YAML::load_file(File.join(File.dirname(__FILE__), "unidecoder_data", "#{k}.yml"))
    } unless defined?(CODEPOINTS)
  
    class << self
      # Returns string with its UTF-8 characters transliterated to ASCII ones
      # 
      # You're probably better off just using the added String#to_ascii
      def decode(string)
        string.gsub(/[^\x00-\x7f]/u) do |codepoint|
          unpacked = codepoint.unpack("U")[0]
          begin
            CODEPOINTS[code_group(unpacked)][grouped_point(unpacked)]
          rescue
            # Hopefully this won't come up much
            "?"
          end
        end
      end
      
      # Returns character for the given Unicode codepoint
      def encode(codepoint)
        ["0x#{codepoint}".to_i(16)].pack("U")
      end
      
      # Returns string indicating which file (and line) contains the
      # transliteration value for the character
      def in_yaml_file(character)
        unpacked = character.unpack("U")[0]
        "#{code_group(unpacked)}.yml (line #{grouped_point(unpacked) + 2})"
      end
    
    private
      # Returns the Unicode codepoint grouping for the given character
      def code_group(unpacked_character)
        "x%02x" % (unpacked_character >> 8)
      end
    
      # Returns the index of the given character in the YAML file for its codepoint group
      def grouped_point(unpacked_character)
        unpacked_character & 255
      end
    end
  end
end

module LuckySneaks
  module StringExtensions
    # Returns string with its UTF-8 characters transliterated to ASCII ones. Example: 
    # 
    #   "⠋⠗⠁⠝⠉⠑".to_ascii #=> "braille"
    def to_ascii
      LuckySneaks::Unidecoder.decode(self)
    end
  end
end