# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module PeerReview
  class PeerReviewError < StandardError; end
  class InvalidParentAssignmentError < PeerReviewError; end
  class FeatureDisabledError < PeerReviewError; end
  class InvalidAssignmentSubmissionTypesError < PeerReviewError; end
  class SubAssignmentExistsError < PeerReviewError; end
  class SubAssignmentNotExistError < PeerReviewError; end
  class InvalidDatesError < PeerReviewError; end
  class SetTypeRequiredError < PeerReviewError; end
  class SetIdRequiredError < PeerReviewError; end
  class OverrideNotFoundError < PeerReviewError; end
  class SectionNotFoundError < PeerReviewError; end
  class StudentIdsRequiredError < PeerReviewError; end
  class SetTypeNotSupportedError < PeerReviewError; end
  class PeerReviewsNotEnabledError < PeerReviewError; end
  class StudentIdsNotInCourseError < PeerReviewError; end
  class GroupAssignmentRequiredError < PeerReviewError; end
  class GroupNotFoundError < PeerReviewError; end
  class CourseNotFoundError < PeerReviewError; end
  class ParentOverrideNotFoundError < PeerReviewError; end
end
