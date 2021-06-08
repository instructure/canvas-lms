# frozen_string_literal: true

{
  fr: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          'e'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}