# frozen_string_literal: true

{
  el: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          'ος'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}