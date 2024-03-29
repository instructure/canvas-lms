# frozen_string_literal: true

module Bundler
  module Multilock
    module UI
      class Capture < Bundler::UI::Silent
        class << self
          def capture
            original_ui = Bundler.ui
            Bundler.ui = new
            yield
            Bundler.ui
          ensure
            Bundler.ui = original_ui
          end
        end

        def initialize
          @messages = []

          super
        end

        def replay
          @messages.each do |(level, args)|
            Bundler.ui.send(level, *args)
          end
          nil
        end

        def add_color(string, _color)
          string
        end

        %i[info confirm warn error debug].each do |level|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{level}(message = nil, newline = nil)      # def info(message = nil, newline = nil)
              @messages << [:#{level}, [message, newline]]  #   @messages << [:info, [message, newline]]
            end                                             # end
                                                            #
            def #{level}?                                   # def info?
              true                                          #   true
            end                                             # end
          RUBY

          def trace(message, newline = nil, force = false) # rubocop:disable Style/OptionalBooleanParameter
            @messages << [:trace, [message, newline, force]]
          end
        end
      end
    end
  end
end
