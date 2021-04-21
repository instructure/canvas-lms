# frozen_string_literal: true

{
  ko: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          '째'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}