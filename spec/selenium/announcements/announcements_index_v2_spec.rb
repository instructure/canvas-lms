#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../common'

describe "announcements index v2" do
  include_context "in-process server selenium tests"
  let(:url) { "/courses/#{@course.id}/announcements/" }

  context "announcements as a teacher" do
    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    end

    before :each do
      user_session(@teacher)
    end

    it 'should display the old announcements if the feature flas is off' do
      @course.account.set_feature_flag! :section_specific_announcements, 'off'
      get url
      expect(f('#external_feed_url')).not_to be_nil
    end

    it 'should display the new announcements if the feature flas is on' do
      @course.account.set_feature_flag! :section_specific_announcements, 'on'
      get url
      expect(f('.announcements-v2__wrapper')).not_to be_nil
    end
  end
end
