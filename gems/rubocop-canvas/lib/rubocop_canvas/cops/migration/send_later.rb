module RuboCop
  module Cop
    module Migration
      class SendLater < Cop
        include RuboCop::Canvas::MigrationTags

        def on_send(node)
          super
          _receiver, method_name = *node
          if method_name.to_s =~ /^send_later/
            check_send_later(node, method_name)
          end
        end

        def check_send_later(node, method_name)
          if method_name.to_s !~ /if_production/
            add_offense(node, :expression, "All `send_later`s in migrations "\
                                        "should be `send_later_if_production`")
          end

          if tags.include?(:predeploy)
            add_offense(node, :expression, "`send_later` cannot be used in a "\
                                "predeploy migration, since job servers won't"\
                                " have the new code yet")
          end
        end
      end
    end
  end
end
