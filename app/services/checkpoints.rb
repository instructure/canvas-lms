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

module Checkpoints
  class DiscussionCheckpointError < StandardError; end

  class FlagDisabledError < DiscussionCheckpointError; end

  class DateTypeRequiredError < DiscussionCheckpointError; end

  class InvalidDateTypeError < DiscussionCheckpointError; end

  class SetTypeRequiredError < DiscussionCheckpointError; end

  class SetTypeNotSupportedError < DiscussionCheckpointError; end

  class GroupAssignmentRequiredError < DiscussionCheckpointError; end

  class SetIdRequiredError < DiscussionCheckpointError; end

  class StudentIdsRequiredError < DiscussionCheckpointError; end

  class CheckpointNotFoundError < DiscussionCheckpointError; end

  class OverrideNotFoundError < DiscussionCheckpointError; end

  class NoCheckpointsFoundError < DiscussionCheckpointError; end
end
