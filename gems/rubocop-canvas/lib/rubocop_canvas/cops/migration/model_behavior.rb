#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "active_support/core_ext/string/inflections"
require 'active_record'

module RuboCop
  module Cop
    module Migration

      # Helper class that represents a whitelist object
      # Simple object that holds data for the Whitelist
      class WhitelistItem
        def initialize(item_string)
          @receivers_method = ""

          # Break appart the string
          str_arr = item_string.split('.')
          # Match these patterns ("Canvas","some_method")
          if str_arr.count == 1
            @right_wild_card = false
            @name = str_arr[0]
            # Match this pattern ("some_method.*", "Receiver.some_method")
          elsif str_arr.count == 2
            # "Receiver.some_method" pattern
            if upper_case?(str_arr[0].chars.first)
              @right_wild_card = false
              @receivers_method = str_arr[1]
              @name = str_arr[0]
            # "some_method.*" pattern
            elsif str_arr[1] == '*'
              @right_wild_card = true
              @name = str_arr[0]
            else
              @name = str_arr[0]
              @right_wild_card = false
            end
          end

          @receiver = upper_case?(@name.chars.first)
        end

        attr_reader :name, :receiver, :right_wild_card, :receivers_method
        alias receiver? receiver
        alias right_wild_card? right_wild_card

        # Overrides
        def to_s
          "name: #{@name} receiver?: #{@receiver} right_wild?: #{@right_wild_card} receivers_method: #{@receivers_method}"
        end

        # Helper functions
        def upper_case?(word)
          word == word.upcase
        end
      end

      class ModelBehavior < Cop
        def on_class(node)
          klass, = *node.to_a
          full_class = resolve_const(klass).join("::")
          list_item = WhitelistItem.new(full_class)
          whitelist[full_class.to_sym] = list_item
        end

        # e.g.
        #   User = Class.new(ActiveRecord::Base)
        #   SOME_ARRAY = [...]
        def on_casgn(node)
          parent, const = *node.to_a
          full_const = resolve_const(parent) << const
          str_const = full_const.join("::").to_s
          list_item = WhitelistItem.new(str_const)
          whitelist[str_const.to_sym] = list_item
        end

        def on_send(node)
          return if ignored_node?(node)

          receiver, methods = resolve_receiver(node)
          receiver = resolve_const(receiver)
          return if receiver.empty?

          # so that we don't get redundant errors for a big long chain of
          # method calls
          ignore_sends(node.to_a[0])

          # If receiver is in the whitelist we good
          joined_receiver = receiver.join("::").to_sym

          # Build up the receiver checking if any portion of it is in the whitelist
          accumulated_receiver = ''
          receiver.each_with_index do |val, ind|
            # Add to the receiver so it is of the format (Module1, Module1::Module2, etc.)
            join_character = (ind == 0) ? '' : '::'
            accumulated_receiver = (accumulated_receiver.to_s + join_character + val.to_s).to_sym
            receiver_list_item = whitelist[accumulated_receiver]

            # Did we find a receiver in the whitelist?
            if receiver_list_item
              # "Receiver.some_method" pattern
              if receiver_list_item.receivers_method == methods[0].to_s
                return
              # "Receiver" pattern
              elsif receiver_list_item.receivers_method == ""
                return
              end
            end
          end

          # Otherwise start checking the methods from left to right
          methods.each do |method_name|
            # check if the curent method is in the whitelist
            whitelist_item = whitelist[method_name]

            # If whitelist_item is nil (method not in whitelist) produce an error
            if whitelist_item.nil?
              produce_error(node, joined_receiver.to_s)
              return
            end

            # Right wildcard (allow anything after)
            break if whitelist_item.right_wild_card?
          end
        end

        def produce_error(node, receiver)
          # receiver = receiver.join("::")
          if model?(receiver)
            message = "If possible, avoid auto-loaded models in a migration; define them here so the behavior doesn't change (e.g. `#{receiver} = Class.new(ActiveRecord::Base)`)."
          else
            message = "If possible, avoid auto-loaded classes/modules in a migration; define any behavior you need here. If you really can't though, add it to the whitelist."
          end
          add_offense node, message: message, severity: :convention
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

        # ruby built-ins (e.g. Class, String, etc) as well as ActiveRecord methods.
        # Add any additional modules you need the cop to include here
        # ... this happens to also get rubocop and its dependencies,
        # but ¯\_(ツ)_/¯
        BASE_WHITELIST = ActiveRecord::Base.methods.map(&:to_s) +
                         Module.constants.map(&:to_s) -
                         %w[find_each]

        def whitelist
          # If whitelist is initialized return it
          return @whitelist if @whitelist

          # Initialize the whitelist
          @whitelist = {}

          # Add in base whitelist with no wildcards
          BASE_WHITELIST.each do |str|
            @whitelist[str.to_sym] = WhitelistItem.new(str)
          end

          # Add in default.yml methods with the appropriate wildcards
          cop_config["Whitelist"].each do |str|
            list_item = WhitelistItem.new(str)
            @whitelist[list_item.name.to_sym] = list_item
          end

          @whitelist
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
