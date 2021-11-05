# frozen_string_literal: true

{
  pl: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1 then "‑szy"
          when 2 then "‑gi"
          when 3 then "‑ci"
          when 7, 8 then "‑my"
          when 4, 5, 6, 9, 10, 11, 12, 13, 17, 18 then "‑ty"
          else
            num_modulo = number.to_i.abs % 10
            case num_modulo
            when 1 then "‑szy"
            when 2 then "‑gi"
            when 3 then "‑ci"
            when 7, 8 then "‑my"
            else "‑ty"
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
