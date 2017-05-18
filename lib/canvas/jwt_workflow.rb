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

module Canvas
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
      @workflows ? @workflows[label.to_sym] : nil
    end

    def self.register(label, &token_state)
      @workflows ||= {}
      @workflows[label.to_sym] = JWTWorkflow.new(&token_state)
    end

    # Register jwt token workflows with specific state requirments.
    #
    # - Try to keep workflow state in tokens to a minium. Remember this will be
    #   passed around with every request in the service workflow.
    #
    register(:rich_content) do |context, user|
      {
        usage_rights_required: (
          context &&
          context.feature_enabled?(:usage_rights_required)
        ) || false,
        can_upload_files: (
          user &&
          context &&
          context.grants_any_right?(user, :manage_files)
        ) || false
      }
    end

    register(:ui) do |_, user|
      {
        use_high_contrast: user.try(:prefers_high_contrast?)
      }
    end
  end
end
