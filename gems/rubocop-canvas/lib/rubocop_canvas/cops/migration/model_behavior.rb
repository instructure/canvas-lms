require "active_support/core_ext/string/inflections"

module RuboCop
  module Cop
    module Migration
      class ModelBehavior < Cop
        def on_class(node)
          klass, _ = *node.to_a
          whitelist << resolve_const(klass)
        end

        # e.g.
        #   User = Class.new(ActiveRecord::Base)
        #   SOME_ARRAY = [...]
        def on_casgn(node)
          parent, const = *node.to_a
          full_const = resolve_const(parent) << const
          whitelist << full_const
        end

        def on_send(node)
          return if ignored_node?(node)

          receiver, methods = resolve_receiver(node)
          receiver = resolve_const(receiver)
          return if receiver.empty?

          # so that we don't get redundant errors for a big long chain of
          # method calls
          ignore_sends(node.to_a[0])

          parts = receiver + methods
          return true if whitelist.any? do |whitelist_parts|
            if whitelist_parts[0] == :*
              methods.any? { |m| m == whitelist_parts.last }
            else
              parts[0, whitelist_parts.length] == whitelist_parts
            end
          end

          receiver = receiver.join("::")
          if model?(receiver)
            message = "If possible, avoid auto-loaded models in a migration; define them here so the behavior doesn't change (e.g. `#{receiver} = Class.new(ActiveRecord::Base)`)."
          else
            message = "If possible, avoid auto-loaded classes/modules in a migration; define any behavior you need here. If you really can't though, add it to the whitelist."
          end
          add_offense node, :expression, message, :convention
        end

        def model?(const_name)
          File.exist?("app/models/#{const_name.underscore}.rb")
        end

        private

        def ignore_sends(node)
          while node && node.type == :send
            ignore_node node
            node = node.to_a[0]
          end
        end

        # just ruby built-ins (e.g. Class, String, etc) ... this happens
        # to also get rubocop and its dependencies, but ¯\_(ツ)_/¯
        BASE_WHITELIST = Module.constants.map(&:to_s)

        def whitelist
          @whitelist ||= (BASE_WHITELIST + cop_config["Whitelist"]).map do |item|
            item.split(/\.|::/).map(&:to_sym)
          end
        end

        # follow chained methods calls back to receiver, e.g.
        # User.where("foo").order("lol").update_all =>
        # [receiver_node, [:where, :order, :update_all]]
        def resolve_receiver(node)
          receiver, method_name, _args = *node
          methods = []
          if receiver && receiver.type == :send
            receiver, methods = resolve_receiver(receiver)
          end
          methods << method_name
          [receiver, methods]
        end

        def resolve_const(node)
          result = []
          while node
            return [] unless node.type == :const || node.type == :cbase
            node, value = node.to_a
            result.unshift value if value
          end
          result
        end
      end
    end
  end
end
