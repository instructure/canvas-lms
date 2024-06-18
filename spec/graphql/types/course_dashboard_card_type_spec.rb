# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::CourseDashboardCardType do
  before do
    Account.site_admin.enable_feature! :dashboard_graphql_integration
  end

  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let(:course_type) { GraphQLTypeTester.new(course, current_user: @student) }

  let!(:presenter) { CourseForMenuPresenter.new(course, @student, nil, nil).to_h }

  it "resolves all fields correctly" do
    expect(course_type.resolve("_id")).to eq course.id.to_s
    expect(course_type.resolve("name")).to eq course.name
    expect(course_type.resolve("courseNickname")).to be_nil
    expect(course_type.resolve("dashboardCard { longName }")).to eq presenter[:longName]
    expect(course_type.resolve("dashboardCard { shortName }")).to eq presenter[:shortName]
    expect(course_type.resolve("dashboardCard { originalName }")).to eq presenter[:originalName]
    expect(course_type.resolve("dashboardCard { courseCode }")).to eq presenter[:courseCode]
    expect(course_type.resolve("dashboardCard { assetString }")).to eq presenter[:assetString]
    expect(course_type.resolve("dashboardCard { href }")).to eq presenter[:href]
    expect(course_type.resolve("dashboardCard { isFavorited }")).to eq presenter[:isFavorited]
    expect(course_type.resolve("dashboardCard { isK5Subject }")).to eq presenter[:isK5Subject]
    expect(course_type.resolve("dashboardCard { isHomeroom }")).to eq presenter[:isHomeroom]
    expect(course_type.resolve("dashboardCard { useClassicFont }")).to eq presenter[:useClassicFont]
    expect(course_type.resolve("dashboardCard { canManage }")).to eq presenter[:canManage]
    expect(course_type.resolve("dashboardCard { canReadAnnouncements }")).to eq presenter[:canReadAnnouncements]
    expect(course_type.resolve("dashboardCard { image }")).to eq presenter[:image]
    expect(course_type.resolve("dashboardCard { color }")).to eq presenter[:color]
    expect(course_type.resolve("dashboardCard { position }")).to eq presenter[:position]
    expect(course_type.resolve("dashboardCard { published }")).to eq presenter[:published]
    expect(course_type.resolve("dashboardCard { canChangeCoursePublishState }")).to eq presenter[:canChangeCoursePublishState]
    expect(course_type.resolve("dashboardCard { defaultView }")).to eq presenter[:defaultView]
    expect(course_type.resolve("dashboardCard { pagesUrl }")).to eq presenter[:pagesUrl]
    expect(course_type.resolve("dashboardCard { frontPageTitle }")).to eq presenter[:frontPageTitle]
  end

  context "with a term" do
    before(:once) do
      course.enrollment_term.update(start_at: 1.month.ago)
    end

    it "correctly resolves term" do
      expect(
        course_type.resolve("dashboardCard { term { _id } }")
      ).to eq course.enrollment_term.id.to_s
      expect(
        course_type.resolve("dashboardCard { term { name } }")
      ).to eq course.enrollment_term.name
      expect(
        course_type.resolve("dashboardCard { term { startAt } }")
      ).to eq course.enrollment_term.start_at.iso8601
    end
  end
end
