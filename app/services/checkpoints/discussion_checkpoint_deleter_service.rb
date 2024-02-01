# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Checkpoints::DiscussionCheckpointDeleterService < ApplicationService
  require_relative "discussion_checkpoint_error"

  def initialize(discussion_topic:)
    super()
    @discussion_topic = discussion_topic
    @assignment = discussion_topic.assignment
  end

  def call
    validate_flag_enabled

    checkpoints = find_checkpoints
    checkpoints.each do |checkpoint|
      checkpoint.active_assignment_overrides.destroy_all
    end

    @assignment.active_assignment_overrides.destroy_all

    checkpoints.destroy_all

    true
  end

  private

  def find_checkpoints
    checkpoints = @assignment.sub_assignments

    raise Checkpoints::NoCheckpointsFoundError, "Checkpoints not found" unless checkpoints.any?

    checkpoints
  end

  def validate_flag_enabled
    unless @discussion_topic.context.root_account.feature_enabled?(:discussion_checkpoints)
      raise Checkpoints::FlagDisabledError, "discussion_checkpoints feature flag must be enabled"
    end
  end
end
