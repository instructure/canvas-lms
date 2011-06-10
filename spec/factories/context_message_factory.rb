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

def context_message_model(opts={})
  @course = opts[:course] || course_model(:reusable => true)
  @sender = opts[:sender] || User.create!(:name => "sender")
  @recipient = opts[:recipient] || User.create!(:name => "recipient")
  @enrollment = @course.enroll_student(@sender) unless opts[:sender]
  @enrollment = @course.enroll_student(@recipient) unless opts[:recipient]
  @context_message = @sender.context_messages.create(:context => @course, :recipients => [ @recipient ], :subject => 'hi', :body => 'hello')
end
