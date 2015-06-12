module RuboCop
  module Cop
    module Rails
      # This cop checks for the use of Time methods without zone.
      #
      # Built on top of Ruby on Rails style guide (https://github.com/bbatsov/rails-style-guide#time)
      # and the article http://danilenko.org/2012/7/6/rails_timezones/, then
      # copied and modified from RuboCop::Cop::Rails::TimeZone
      #
      #
      # @example
      #   # offense
      #   Time.now
      #   Time.parse('2015-03-02 19:05:37')
      #
      #   # no offense
      #   Time.zone.now
      #   Time.now.utc
      #   Time.zone.parse('2015-03-02 19:05:37')
      #   DateTime.strptime(str, "%Y-%m-%d %H:%M %Z").in_time_zone
      #   Time.at(timestamp).in_time_zone
      class SmartTimeZone < Cop

        MSG = 'Do not use `%s` without zone. Use `%s` instead.'

        TIMECLASS = [:Time, :DateTime].freeze

        DANGER_METHODS = [:now, :local, :new, :strftime, :parse, :at].freeze

        def on_const(node)
          _module, klass = *node

          return unless method_send?(node)

          check_time_node(klass, node.parent) if TIMECLASS.include?(klass)
        end

        private

        def check_time_node(klass, node)
          chain = extract_method_chain(node)
          return if (chain & DANGER_METHODS).empty? ||
                    !(chain & good_methods).empty?

          method_name = (chain & DANGER_METHODS).join('.')
          safe_method_name = safe_method(method_name, node)

          add_offense(node, :selector,
                      format(MSG,
                             "#{klass}.#{method_name}",
                             "Time.zone.#{safe_method_name}")
                     )
        end

        def extract_method_chain(node)
          chain = []
          p = node
          while !p.nil? && p.send_type?
            chain << extract_method(p)
            p = p.parent
          end
          chain
        end

        def extract_method(node)
          _receiver, method_name, *_args = *node
          method_name
        end

        # checks that parent node of send_type
        # and receiver is the given node
        def method_send?(node)
          return false unless node.parent.send_type?

          receiver, _method_name, *_args = *node.parent

          receiver == node
        end

        def safe_method(method_name, node)
          _receiver, _method_name, *args = *node
          return method_name unless method_name == 'new'

          if args.empty?
            'now'
          else
            'local'
          end
        end

        def good_methods
          [:zone, :in_time_zone, :utc]
        end
      end
    end
  end
end
