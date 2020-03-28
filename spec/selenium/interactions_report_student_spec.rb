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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "student interactions report" do
  include_context "in-process server selenium tests"

  before :once do
    PostPolicy.enable_feature!
  end

  context "as a student" do
    before(:each) do
      course_with_teacher_logged_in(active_all: true)
      @student1 = student_in_course(active_all: true).user
      @student2 = student_in_course(active_all: true, name: "zzz student").user

      @assignment = @course.assignments.create(name: "first assignment", points_possible: 10)
      @assignment.unmute!
      @sub1 = @assignment.submissions.find_by!(user: @student1)
      @sub2 = @assignment.submissions.find_by!(user: @student2)

      @sub1.update!({score: 10})
      @sub2.update!({score: 5})

      get "/users/#{@teacher.id}/teacher_activity/course/#{@course.id}"
    end

    it "should have sortable columns, except the email header" do
      ths = ff(".report th")
      expect(ths[0]).to have_class("header")
      expect(ths[1]).to have_class("header")
      expect(ths[2]).to have_class("header")
      expect(ths[3]).to have_class("header")
      expect(ths[4]).to have_class("header")
      expect(ths[5]).to have_class("sorter-false")
    end

    it "should allow sorting by columns" do
      ths = ff(".report th")
      trs = ff(".report tbody tr")
      ths[0].click
      wait_for_ajaximations
      expect(ths[0]).to have_class("tablesorter-headerAsc")
      expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

      ths[0].click
      wait_for_ajaximations
      expect(ths[0]).to have_class("tablesorter-headerDesc")
      expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

      ths[2].click
      wait_for_ajaximations
      expect(ths[2]).to have_class("tablesorter-headerAsc")
      expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

      ths[2].click
      wait_for_ajaximations
      expect(ths[2]).to have_class("tablesorter-headerDesc")
      expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

      ths[3].click
      wait_for_ajaximations
      expect(ths[3]).to have_class("tablesorter-headerAsc")
      expect(ff(".report tbody tr")).to eq [trs[0], trs[1]]

      ths[3].click
      wait_for_ajaximations
      expect(ths[3]).to have_class("tablesorter-headerDesc")
      expect(ff(".report tbody tr")).to eq [trs[1], trs[0]]

      ths[5].click
      wait_for_ajaximations
      expect(ths[5]).to have_class("sorter-false")
    end
  end
end
