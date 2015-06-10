module Canvas::ICU
  module NaiveCollator
    def self.rules
      ''
    end

    def self.collation_key(string)
      string.downcase
    end

    def self.compare(a, b)
      collation_key(a) <=> collation_key(b)
    end

    def self.collate(sortable)
      sortable.sort{ |a, b| compare(a, b) }
    end
  end

  begin
    Bundler.require 'icu'
    if !ICU::Lib.respond_to?(:ucol_getRules)
      require 'ffi'
      suffix = ICU::Lib.figure_suffix(ICU::Lib.version.to_s)

      ICU::Lib.attach_function(:ucol_getRules, "ucol_getRules#{suffix}", [:pointer, :pointer], :pointer)
      ICU::Lib.attach_function(:ucol_getSortKey, "ucol_getSortKey#{suffix}", [:pointer, :pointer, :int, :pointer, :int], :int)
      ICU::Lib.attach_function(:ucol_getAttribute, "ucol_getAttribute#{suffix}", [:pointer, :int, :pointer], :int)
      ICU::Lib.attach_function(:ucol_setAttribute, "ucol_setAttribute#{suffix}", [:pointer, :int, :int, :pointer], :void)

      ICU::Collation::Collator.class_eval do
        def rules
          @rules ||= begin
            length = FFI::MemoryPointer.new(:int)
            ptr = ICU::Lib.ucol_getRules(@c, length)
            ptr.read_array_of_uint16(length.read_int).pack("U*")
          end
        end

        def collation_key(string)
          ptr = ICU::UCharPointer.from_string(string)
          size = ICU::Lib.ucol_getSortKey(@c, ptr, string.jlength, nil, 0)
          buffer = FFI::MemoryPointer.new(:char, size)
          ICU::Lib.ucol_getSortKey(@c, ptr, string.jlength, buffer, size)
          buffer.read_bytes(size - 1)
        end

        def [](attribute)
          ATTRIBUTE_VALUES_INVERSE[ICU::Lib.check_error do |error|
            ICU::Lib.ucol_getAttribute(@c, ATTRIBUTES[attribute], error)
          end]
        end

        def []=(attribute, value)
          ICU::Lib.check_error do |error|
            ICU::Lib.ucol_setAttribute(@c, ATTRIBUTES[attribute], ATTRIBUTE_VALUES[value], error)
          end
          value
        end

        ATTRIBUTES = {
          french_collation: 0,
          alternate_handling: 1,
          case_first: 2,
          case_level: 3,
          normalization_mode: 4,
          strength: 5,
          hiragana_quaternary_mode: 6,
          numeric_collation: 7,
        }.freeze

        ATTRIBUTES.each_key do |attribute|
          class_eval <<-CODE
            def #{attribute}
              self[:#{attribute}]
            end

            def #{attribute}=(value)
              self[:#{attribute}] = value
            end
          CODE
        end

        ATTRIBUTE_VALUES = {
          nil => -1,
          primary: 0,
          secondary: 1,
          default_strength: 2,
          tertiary: 2,
          quaternary: 3,
          identical: 15,

          false => 16,
          true => 17,

          shifted: 20,
          non_ignorable: 21,

          lower_first: 24,
          upper_first: 25,
        }.freeze
        ATTRIBUTE_VALUES_INVERSE = Hash[ATTRIBUTE_VALUES.map {|k,v| [v, k]}].freeze
      end
    end

    def self.collator
      @collations ||= {}
      @collations[I18n.locale] ||= begin
        collator = ICU::Collation::Collator.new(I18n.locale.to_s)
        collator.normalization_mode = true
        collator.numeric_collation = true
        collator
      end
    end

  rescue LoadError
    def self.collator
      NaiveCollator
    end
  end

  def self.locale_for_collation
    collator.rules.empty? ? 'root' : I18n.locale
  end

  def self.compare(a, b)
    if (!a.is_a?(String) || !b.is_a?(String))
      a <=> b
    else
      collator.compare(a, b)
    end
  end

  def self.collation_key(string)
    return string unless string.is_a?(String)
    collator.collation_key(string)
  end

  class << self
    delegate :collate, to: :collator
  end

  def self.collate_by(sortable)
    sortable.sort { |a, b| compare(yield(a), yield(b)) }
  end
end
