#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/assignments/_syllabus_content" do
  context 'js_env CAN_READ' do
    def setup_and_render_context(type, opts={})
      case type
      when :anonymous
        course :active_all => true
      when :non_enrolled_user
        course :active_all => true
        user
      when :enrolled_user
        course_with_student :active_all => true
      end

      if opts[:is_public]
        @course.is_public = true
        @course.save!
      end

      user_session(@user) if @user
      view_context(@course, @user)

      render '/assignments/_syllabus_content'
    end

    before(:each) do
      course :active_all => true
      @course.is_public = true
      @course.save!
    end

    example 'anonymous user (public course)' do
      setup_and_render_context :anonymous, :is_public => true
      @controller.js_env.should include(:CAN_READ => true)
    end

    example 'non-enrolled user (public course)' do
      setup_and_render_context :non_enrolled_user, :is_public => true
      @controller.js_env.should include(:CAN_READ => true)
    end

    example 'enrolled user (non-public course)' do
      setup_and_render_context :enrolled_user
      @controller.js_env.should include(:CAN_READ => true)
    end
  end
end
