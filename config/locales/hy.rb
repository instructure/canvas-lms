# frozen_string_literal: true

{
  hy: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1; '‑ին'
          else; '‑րդ'
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