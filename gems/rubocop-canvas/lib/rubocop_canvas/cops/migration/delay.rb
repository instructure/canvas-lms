# frozen_string_literal: true

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
      class Delay < Cop
        include RuboCop::Canvas::MigrationTags

        PREDEPLOY_MSG = "`delay` cannot be used in a " \
                        "predeploy migration, since job servers won't " \
                        "have the new code yet"

        def on_send(node)
          super
          _receiver, method_name = *node

          return unless %i[delay delay_if_production].include?(method_name)

          return add_offense(node, message: PREDEPLOY_MSG, severity: :error) if tags.include?(:predeploy)

          return unless method_name == :delay

          add_offense(node,
                      message: "All `delay`s in migrations should be `delay_if_production`",
                      severity: :error)
        end
      end
    end
  end
end
