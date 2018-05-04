#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentMigrationsController do
  context 'course' do
    before(:once) do
      course_factory active_all: true
    end

    it 'index exports quizzes_next environment' do
      user_session(@teacher)
      get :index, params: {course_id: @course.id}
      expect(response).to be_success
      expect(assigns[:js_env][:QUIZZES_NEXT_CONFIGURED_ROOT]).not_to be(nil)
      expect(assigns[:js_env][:QUIZZES_NEXT_ENABLED]).not_to be(nil)
    end
  end
end
