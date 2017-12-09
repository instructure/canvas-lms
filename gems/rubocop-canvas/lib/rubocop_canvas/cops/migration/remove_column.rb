#
# Copyright (C) 2015 - present Instructure, Inc.
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
    module Migration
      class RemoveColumn < Cop
        include RuboCop::Canvas::MigrationTags
        MSG = "`remove_column` needs to be in a postdeploy migration"

        def on_def(node)
          method_name, *_args = *node
          @current_def = method_name
        end

        def on_defs(node)
          _receiver, method_name, *_args = *node
          @current_def = method_name
        end

        def on_send(node)
          super
          _receiver, method_name, *_args = *node
          if remove_column_in_predeploy?(method_name)
            add_offense(node, message: MSG, severity: :warning)
          end
        end

        private
        def remove_column_in_predeploy?(method_name)
          tags.include?(:predeploy) &&
            method_name == :remove_column &&
            @current_def == :up
        end
      end
    end
  end
end
