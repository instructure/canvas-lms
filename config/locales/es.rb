# frozen_string_literal: true

{
  es: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          '.º'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}