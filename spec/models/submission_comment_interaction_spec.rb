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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe SubmissionCommentInteraction do
  context '.in_course_between' do
    it 'finds the date of the latest submission comment' do
      course_with_student_submissions
      sub = @course.assignments.first.submissions.
        where(user_id: @student).first
      comment = sub.add_comment(comment: 'hi', author: @teacher)
      res = SubmissionCommentInteraction.in_course_between(@course, @teacher, @student)
      expect(res.length).to eq 1
      expect(res[[@student.id.to_s, @teacher.id]].to_i).to eq comment.created_at.to_i

    end
  end
end
