# frozen_string_literal: true

{
  uk: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          '‑й'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}