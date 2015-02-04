#
# Copyright (C) 2015 Instructure, Inc.
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

class SubmissionCommentInteraction
  # returns an array mapping [user_id, author_id] => time of last submission
  # comment
  #
  # warning: user_id comes back as a string for some reason, so the actual
  # object looks like: {["3", 1]=>2015-02-03 22:52:51 UTC}
  def self.in_course_between(course, teacher_or_ids, student_or_ids)
    course.submission_comments.
      joins(:submission).
      group([:user_id, :author_id]).
      where({
        submission_comments: { author_id: teacher_or_ids },
        submissions: { user_id: student_or_ids }
      }).
      maximum(:created_at)
  end
end
