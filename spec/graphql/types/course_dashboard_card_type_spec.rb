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
require_relative "../../helpers/k5_common"

describe Types::CourseDashboardCardType do
  include K5Common

  before do
    Account.site_admin.enable_feature! :dashboard_graphql_integration
  end

  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let_once(:user) { User.create! }
  let_once(:account) { Account.default }

  describe "links" do
    it "only shows the tabs a student has access to to students" do
      course.offer
      course.assignments.create!
      course.attachments.create! filename: "blah", uploaded_data: StringIO.new("blah")
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)

      expect(cur_resolver.resolve("dashboardCard { links { label } }")).to match_array(%w[Assignments Discussions Files])
      expect(cur_resolver.resolve("dashboardCard { links { icon } }")).to match_array(%w[icon-assignment icon-discussion icon-folder])
      expect(cur_resolver.resolve("dashboardCard { links { cssClass } }")).to match_array(%w[assignments discussions files])
    end

    it "shows all the tab links to a teacher" do
      new_teacher = User.create!
      course.enroll_teacher(new_teacher).accept
      course.assignments.create!
      course.discussion_topics.create!
      course.announcements.create! title: "hear ye!", message: "wat"
      course.attachments.create! filename: "blah", uploaded_data: StringIO.new("blah")
      cur_resolver = GraphQLTypeTester.new(course, current_user: new_teacher)

      expect(cur_resolver.resolve("dashboardCard { links { label } }")).to match_array(%w[Announcements Assignments Discussions Files])
      expect(cur_resolver.resolve("dashboardCard { links { icon } }")).to match_array(%w[icon-announcement icon-assignment icon-discussion icon-folder])
      expect(cur_resolver.resolve("dashboardCard { links { cssClass } }")).to match_array(%w[announcements assignments discussions files])
    end
  end

  it "returns the course nickname if one is set" do
    @student.set_preference(:course_nicknames, course.id, "nickname")
    cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
    expect(cur_resolver.resolve("dashboardCard { originalName }")).to eq course.name
    expect(cur_resolver.resolve("dashboardCard { shortName }")).to eq "nickname"
  end

  it "sets isFavorited to true if course is favorited" do
    course.enroll_student(@student)
    Favorite.create!(user: @student, context: course)
    cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
    expect(cur_resolver.resolve("dashboardCard { isFavorited }")).to be true
  end

  it "sets isFavorited to false if course is unfavorited" do
    course.enroll_student(@student)
    cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
    expect(cur_resolver.resolve("dashboardCard { isFavorited }")).to be false
  end

  it "sets the published value" do
    cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
    expect(cur_resolver.resolve("dashboardCard { published }")).not_to be_nil
  end

  context "isK5Subject" do
    it "is set for k5 subjects" do
      toggle_k5_setting(course.account)
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { isK5Subject }")).to be_truthy
    end

    it "is false for classic courses" do
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { isK5Subject }")).to be_falsey
    end
  end

  context "useClassicFont" do
    before :once do
      toggle_k5_setting(course.account)
    end

    it "is true when the course's account has use_classic_font?" do
      toggle_classic_font_setting(course.account)
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { useClassicFont }")).to be_truthy
    end

    it "is false if the course's account does not have use_classic_font?" do
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { useClassicFont }")).to be_falsey
    end
  end

  context "with `homeroom_course` setting enabled" do
    before do
      course.update! homeroom_course: true
    end

    it "sets `isHomeroom` to `true`" do
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { isHomeroom }")).to be true
    end
  end

  context "course color" do
    before do
      course.update! settings: course.settings.merge(course_color: "#789")
    end

    it "sets `color` to nil if the course is not associated with a K-5 account" do
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { color }")).to be_nil
    end

    it "sets `color` if the course is associated with a K-5 account" do
      toggle_k5_setting(course.account)

      cure_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cure_resolver.resolve("dashboardCard { color }")).to eq "#789"
    end
  end

  context "Dashcard Reordering" do
    it "returns a position if one is set" do
      @student.set_dashboard_positions(course.asset_string => 3)
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { position }")).to eq 3
    end

    it "returns nil when no position is set" do
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(cur_resolver.resolve("dashboardCard { position }")).to be_nil
    end
  end

  describe "observee" do
    it "works with observee" do
      cur_user = User.create!
      course.enroll_user(cur_user, "ObserverEnrollment", associated_user_id: @student.id, enrollment_state: "active")

      dashboard_filter = { observed_user_id: @student.id.to_s }
      context = { current_user: cur_user, domain_root_account: account, session: {}, dashboard_filter: }
      # Need to use favoriteCoursesConnection here because this is where the enrollment gets loaded
      user_type = GraphQLTypeTester.new(cur_user, context)
      expect(user_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { enrollmentType } } }")).to eq ["ObserverEnrollment"]
      expect(user_type.resolve("favoriteCoursesConnection { nodes { dashboardCard { observee } } }")).to eq [@student.name]
    end
  end

  context "with a term" do
    it "correctly resolves term" do
      course.enrollment_term.update(start_at: 1.month.ago)
      cur_resolver = GraphQLTypeTester.new(course, current_user: @student)
      expect(
        cur_resolver.resolve("dashboardCard { term { _id } }")
      ).to eq course.enrollment_term.id.to_s
      expect(
        cur_resolver.resolve("dashboardCard { term { name } }")
      ).to eq course.enrollment_term.name
      expect(
        cur_resolver.resolve("dashboardCard { term { startAt } }")
      ).to eq course.enrollment_term.start_at.iso8601
    end
  end
end
