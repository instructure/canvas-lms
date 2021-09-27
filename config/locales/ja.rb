# frozen_string_literal: true

{
  ja: {
    number: {
      nth: {
        ordinals: lambda do |_key, _options|
          '第'
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{ActiveSupport::Inflector.ordinal(number)}#{number}"
        end
      }
    }
  }
}