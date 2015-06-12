module RuboCop
  module Cop
    module Lint
      class FreezeConstants < Cop
        def on_casgn(node)
          _scope, _const_name, value = *node
          check_for_unfrozen_structures(value)
        end

        def check_for_unfrozen_structures(node, safe_at_this_level=false)
          return if node.nil?
          return if node.children.last == :to_i
          safe_at_next_level = false
          if node.type == :send
            safe_at_next_level = send_is_safe?(node)
          elsif node.type == :array || node.type == :hash
            mark_offense!(node) unless safe_at_this_level
          end
          return if node.type == :block
          check_children(node, safe_at_next_level)
        end

        private
        def send_is_safe?(node)
          return true if target_isnt_structure_or_string(node)
          return true if node.children.include?(:freeze)
          mark_offense!(node)
          false
        end

        def target_isnt_structure_or_string(node)
          target = node.children.first
          ![:hash, :array, :string].include?(target.type)
        end

        def check_children(node, safe_at_next_level)
          node.children.each do |child|
            if child.respond_to?(:type)
              check_for_unfrozen_structures(child, safe_at_next_level)
            end
          end
        end

        def mark_offense!(node)
          add_offense(node, :expression, "data structure constants"\
                                            " should be frozen")
        end

      end
    end
  end
end
