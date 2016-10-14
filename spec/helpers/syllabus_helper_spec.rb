#
# Copyright (C) 2016 Instructure, Inc.
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

require 'spec_helper'

describe SyllabusHelper do
  describe '#syllabus_user_content' do
    before :once do
      course_with_teacher(active_all: true)
      @course.syllabus_body = '<p>Here is your syllabus</p>'
      @course.save!
      assign(:context, @course)
    end

    context 'when context grants :read permission to current_user' do
      before :once do
        assign(:current_user, @user)
      end

      it 'sends two arguments to `pulic_user_content`' do
        helper.expects(:public_user_content).with(@course.syllabus_body, @course).once
        helper.syllabus_user_content
      end
    end

    context 'when context does not grant :read permission to current_user' do
      before :once do
        assign(:current_user, nil)
      end

      it 'sends two arguments to `pulic_user_content`' do
        helper.expects(:public_user_content).with(@course.syllabus_body, @course, nil, true).once
        helper.syllabus_user_content
      end
    end
  end
end
