#
# Copyright (C) 2011 Instructure, Inc.
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

def submission_model(opts={})
  assignment = opts[:assignment] || assignment_model(:course => opts[:course])
  @student = opts.delete(:user) || user_with_pseudonym({:active_user => true, :username => 'student@example.com', :password => 'qwerty'}.merge(opts))
  @course.enroll_user(@student, "StudentEnrollment", {:enrollment_state => 'active'}.merge(opts))
  assignment.reload # it caches the course pre-student enrollment
  @submission = assignment.submit_homework(@student, (opts.presence || { :url => "http://www.instructure.com/" }))
  @submission.save!
  @submission
end
