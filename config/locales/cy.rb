# frozen_string_literal: true

{
  cy: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1 then "af"
          when 2 then "ail"
          when 3, 4 then "ydd"
          when 5, 6 then "ed"
          when 11, 13, 14, 16, 17, 19 then "eg"
          else
            if number > 20 && number < 40
              "ain"
            else
              "fed"
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
