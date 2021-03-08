# frozen_string_literal: true

# From what I can gather, in Maori regular numerals are used as ordinals
{
  mi: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          ''
        end,

        ordinalized: lambda do |_key, options|
          options[:number]
        end
      }
    }
  }
}