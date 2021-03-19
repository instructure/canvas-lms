# frozen_string_literal: true

{
  nn: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          '.'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}