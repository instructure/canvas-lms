# frozen_string_literal: true

{
  cy: {
    number: {
      nth: {
        ordinals: lambda do |_key, options|
          number = options[:number]
          case number
          when 1; 'af'
          when 2; 'ail'
          when 3; 'ydd'
          when 4; 'ydd'
          when 5; 'ed'
          when 6; 'ed'
          when 11; 'eg'
          when 13; 'eg'
          when 14; 'eg'
          when 16; 'eg'
          when 17; 'eg'
          when 19; 'eg'
          else
            if number > 20 && number < 40 then
              'ain'
            else
              'fed'
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