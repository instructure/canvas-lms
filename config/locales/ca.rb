# frozen_string_literal: true

{
  ca: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1; 'r'
          when 2; 'n'
          when 3; 'r'
          when 4; 't'
          else; 'è'
          end
        end,

        ordinalized: lambda do |_key, options|
          number = options[:number]
          "#{number}#{ActiveSupport::Inflector.ordinal(number)}"
        end
      }
    }
  }
}