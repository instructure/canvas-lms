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
      class SendLater < Cop
        include RuboCop::Canvas::MigrationTags

        PREDEPLOY_MSG = "`send_later` cannot be used in a"\
                        " predeploy migration, since job servers won't"\
                        " have the new code yet"
        

        def on_send(node)
          super
          _receiver, method_name = *node
          if method_name.to_s =~ /^send_later/
            check_send_later(node, method_name)
          end
        end

        def check_send_later(node, method_name)
          if method_name.to_s !~ /if_production/
            add_offense(node,
              message: "All `send_later`s in migrations should be `send_later_if_production`",
              severity: :warning)
          end

          if tags.include?(:predeploy)
            add_offense(node, message: PREDEPLOY_MSG, severity: :warning)
          end
        end
      end
    end
  end
end
