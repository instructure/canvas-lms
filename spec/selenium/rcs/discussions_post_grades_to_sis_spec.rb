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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "sync grades to sis" do
  include_context "in-process server selenium tests"

  before :each do
    course_with_admin_logged_in
    enable_all_rcs @course.account
    stub_rcs_config
    Account.default.set_feature_flag!('post_grades', 'on')
    @course.sis_source_id = 'xyz'
    @course.save
    @assignment_group = @course.assignment_groups.create!(name: 'Assignment Group')
  end

  it "does not display Sync to SIS option when feature not configured", priority: "1", test_id: 246614 do
    Account.default.set_feature_flag!('post_grades', 'off')
    get "/courses/#{@course.id}/discussion_topics/new"
    f('#use_for_grading').click
    expect(f("#content")).not_to contain_css('#assignment_post_to_sis')
  end
end
