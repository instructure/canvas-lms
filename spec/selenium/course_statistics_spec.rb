#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course statistics" do
  include_context "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    @student1 = student_in_course(:active_all => true, :name => "Sheldon Cooper").user
    @student2 = student_in_course(:active_all => true, :name => "Leonard Hofstadter").user
    @student3 = student_in_course(:active_all => true, :name => "Howard Wolowitz").user
  end

  it "should show most recent logged in users" do
    pseudonym(@student1) # no login info
    pseudonym(@student2).tap{|p| p.current_login_at = 1.days.ago; p.save!}
    pseudonym(@student3).tap{|p| p.current_login_at = 2.days.ago; p.save!}

    get "/courses/#{@course.id}/statistics"
    wait_for_ajaximations
    f('#students_stats_tab').click

    users = ff('.item_list li')
    expect(users[0]).to include_text @student2.name
    expect(users[0]).not_to include_text "unknown"
    expect(users[1]).to include_text @student3.name
    expect(users[1]).not_to include_text "unknown"
    expect(users[2]).to include_text @student1.name
    expect(users[2]).to include_text "unknown"

    links = ff('.item_list li a')
    expect(links[0]['href'].end_with?("/courses/#{@course.id}/users/#{@student2.id}")).to eq true
    expect(links[1]['href'].end_with?("/courses/#{@course.id}/users/#{@student3.id}")).to eq true
    expect(links[2]['href'].end_with?("/courses/#{@course.id}/users/#{@student1.id}")).to eq true
  end
end
