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

module Messages::PeerReviewsHelper

  def reviewee_name(asset, reviewer)
    asset.can_read_assessment_user_name?(reviewer, nil) ? asset.asset.user.name : I18n.t(:anonymous_user, 'Anonymous User')
  end

  def submission_comment_author(submission_comment, user)
     submission_comment.can_read_author?(user, nil) ? (submission_comment.author_name || I18n.t(:someone, "Someone")) : I18n.t(:anonymous_user, 'Anonymous User')
  end

  def submission_comment_submittor(submission_comment, user)
    submission_comment.submission.can_read_submission_user_name?(user, nil) ? submission_comment.submission.user.short_name : I18n.t(:anonymous_user, 'Anonymous User')
  end

end