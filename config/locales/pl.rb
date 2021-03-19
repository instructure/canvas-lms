# frozen_string_literal: true

{
  pl: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1; "‑szy"
          when 2; "‑gi"
          when 3; "‑ci"
          when 7; "‑my"
          when 8; "‑my"
          when 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 17, 18; "‑ty"
          else
            num_modulo = number.to_i.abs % 10
            case num_modulo
            when 1; "‑szy"
            when 2; "‑gi"
            when 3; "‑ci"
            when 7; "‑my"
            when 8; "‑my"
            else    "‑ty"
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