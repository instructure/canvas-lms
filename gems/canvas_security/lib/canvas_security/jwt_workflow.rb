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

module CanvasSecurity
  class JWTWorkflow
    def initialize(&token_state)
      @token_state = token_state
    end

    def state_for(context, user)
      @token_state ? @token_state.call(context, user) : {}
    end

    def self.state_for(workflows, context, user)
      workflows.inject({}) do |memo, label|
        workflow = get(label)
        workflow ? memo.merge(workflow.state_for(context, user)) : memo
      end
    end

    def self.get(label)
      @workflows&.dig(label.to_sym, :workflow)
    end

    def self.register(label, requires_context: false, requires_symmetric_encryption: false, &)
      @workflows ||= {}
      @workflows[label.to_sym] = { workflow: JWTWorkflow.new(&), requires_context:, requires_symmetric_encryption: }
    end

    def self.workflow_requires_context?(workflow)
      !!@workflows&.dig(workflow.to_sym, :requires_context)
    end

    def self.workflow_requires_symmetric_encryption?(workflow)
      !!@workflows&.dig(workflow.to_sym, :requires_symmetric_encryption)
    end
  end
end
