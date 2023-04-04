# frozen_string_literal: true

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

module RuboCop
  module Cop
    module Specs
      class PreferFOverFj < Cop
        include RuboCop::Cop::Consts::JQuerySelectors

        SUSPECT_METHOD_NAMES = {
          fj: "f",
          ffj: "ff"
        }.freeze

        def on_send(node)
          _receiver, method_name, *args = *node
          return unless SUSPECT_METHOD_NAMES.key?(method_name)
          return if jquery_necessary?(args.to_a.first.children.first)

          add_offense node, message: error_msg(method_name), severity: :warning
        end

        private

        def jquery_necessary?(selector)
          # TODO: inspect the value of the variable
          return true unless selector.is_a?(String)

          selector =~ JQUERY_SELECTORS_REGEX
        end

        def error_msg(method)
          alternative = SUSPECT_METHOD_NAMES[method]
          "Prefer `#{alternative}` instead of `#{method}`; `#{method}` " \
            "should only be used if you are doing jquery-fake-css selectors " \
            "(e.g. `:visible`)"
        end

        def autocorrect(node)
          _, method_name, *_args = *node
          lambda do |corrector|
            corrector.replace(node.loc.selector, SUSPECT_METHOD_NAMES[method_name])
          end
        end
      end
    end
  end
end
