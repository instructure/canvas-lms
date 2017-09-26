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
#

module Api::V1::SubmissionComment

  def submission_comment_json(submission_comment, user)
    sc_hash = submission_comment.as_json(
      :include_root => false,
      :only => %w(id author_id author_name created_at edited_at comment)
    )

    if submission_comment.media_comment?
      sc_hash['media_comment'] = media_comment_json(
        :media_id => submission_comment.media_comment_id,
        :media_type => submission_comment.media_comment_type
      )
    end

    sc_hash['attachments'] = submission_comment.attachments.map do |a|
      attachment_json(a, user)
    end unless submission_comment.attachments.blank?
    if submission_comment.grants_right?(@current_user, :read_author)
      sc_hash['author'] = user_display_json(submission_comment.author, submission_comment.context)
    else
      if sc_hash.delete('avatar_path')
        sc_hash['avatar_path'] = User.default_avatar_fallback
      end
      sc_hash.merge!({
                      author: {},
                      author_id: nil,
                      author_name: I18n.t("Anonymous User")
                     })
    end
    sc_hash
  end

  def submission_comments_json(submission_comments, user)
    submission_comments.map{ |submission_comment| submission_comment_json(submission_comment, user) }
  end
end
