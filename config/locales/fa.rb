# frozen_string_literal: true

{
  fa: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          'م'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}