# frozen_string_literal: true

{
  sv: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1, 2 then ":a"
          when 11, 12 then ":e"
          else
            num_modulo = number.to_i.abs % 10
            case num_modulo
            when 1, 2 then ":a"
            else ":e"
            end
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
