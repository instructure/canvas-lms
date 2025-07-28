# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::CourseSettingsType do
  let_once(:course) do
    course_with_student(active_all: true)
    @course
  end
  let(:course_type) { GraphQLTypeTester.new(course, current_user: @student) }

  context "course settings fields" do
    it "returns all course settings" do
      course.update!(grading_standard_enabled: true, grading_standard_id: 1)
      course.update!(course_color: "#123456", alt_name: "My Friendly Course")
      course.update!(default_due_time: "21:30:00")

      expect(course_type.resolve("settings { allowFinalGradeOverride }")).to eq course.allow_final_grade_override?
      expect(course_type.resolve("settings { allowStudentAnonymousDiscussionTopics }")).to eq course.allow_student_anonymous_discussion_topics?
      expect(course_type.resolve("settings { allowStudentDiscussionEditing }")).to eq course.allow_student_discussion_editing?
      expect(course_type.resolve("settings { allowStudentDiscussionReporting }")).to eq course.allow_student_discussion_reporting?
      expect(course_type.resolve("settings { allowStudentDiscussionTopics }")).to eq course.allow_student_discussion_topics?
      expect(course_type.resolve("settings { allowStudentForumAttachments }")).to eq course.allow_student_forum_attachments?
      expect(course_type.resolve("settings { allowStudentOrganizedGroups }")).to eq course.allow_student_organized_groups?
      expect(course_type.resolve("settings { conditionalRelease }")).to eq course.conditional_release?
      expect(course_type.resolve("settings { courseColor }")).to eq "#123456"
      expect(course_type.resolve("settings { defaultDueTime }")).to eq "21:30:00"
      expect(course_type.resolve("settings { filterSpeedGraderByStudentGroup }")).to eq course.filter_speed_grader_by_student_group?
      expect(course_type.resolve("settings { friendlyName }")).to eq "My Friendly Course"
      expect(course_type.resolve("settings { gradePassbackSetting }")).to eq course.grade_passback_setting
      expect(course_type.resolve("settings { gradingStandardEnabled }")).to be true
      expect(course_type.resolve("settings { gradingStandardId }")).to eq "1"
      expect(course_type.resolve("settings { hideDistributionGraphs }")).to eq course.hide_distribution_graphs?
      expect(course_type.resolve("settings { hideFinalGrades }")).to eq course.hide_final_grades?
      expect(course_type.resolve("settings { hideSectionsOnCourseUsersPage }")).to eq course.hide_sections_on_course_users_page?
      expect(course_type.resolve("settings { homePageAnnouncementLimit }")).to eq course.home_page_announcement_limit
      expect(course_type.resolve("settings { homeroomCourse }")).to eq course.homeroom_course?
      expect(course_type.resolve("settings { lockAllAnnouncements }")).to eq course.lock_all_announcements?
      expect(course_type.resolve("settings { showAnnouncementsOnHomePage }")).to eq course.show_announcements_on_home_page?
      expect(course_type.resolve("settings { syllabusCourseSummary }")).to eq course.syllabus_course_summary?
      expect(course_type.resolve("settings { usageRightsRequired }")).to eq course.usage_rights_required?

      expect(course_type.resolve("settings { imageId }")).to eq course.image_id
      expect(course_type.resolve("settings { imageUrl }")).to eq course.image_url
      expect(course_type.resolve("settings { bannerImageId }")).to eq course.banner_image_id
      expect(course_type.resolve("settings { bannerImageUrl }")).to eq course.banner_image_url
    end

    it "returns privacy-related settings" do
      expect(course_type.resolve("settings { hideFinalGrades }")).to eq course.hide_final_grades?
      expect(course_type.resolve("settings { restrictStudentPastView }")).to eq course.restrict_student_past_view?
      expect(course_type.resolve("settings { restrictStudentFutureView }")).to eq course.restrict_student_future_view?
      # restrictQuantitativeData is converted to Boolean in the resolver
      val = course.restrict_quantitative_data
      expected = if val == "true"
                   true
                 elsif val == "false"
                   false
                 else
                   val
                 end
      expect(course_type.resolve("settings { restrictQuantitativeData }")).to eq expected
    end

    it "returns grading settings" do
      course.update!(grading_standard_enabled: true, grading_standard_id: 1)
      expect(course_type.resolve("settings { gradingStandardEnabled }")).to be true
      expect(course_type.resolve("settings { gradingStandardId }")).to eq "1"
    end

    it "returns appearance settings" do
      course.update!(course_color: "#123456", alt_name: "My Friendly Course")
      expect(course_type.resolve("settings { courseColor }")).to eq "#123456"
      expect(course_type.resolve("settings { friendlyName }")).to eq "My Friendly Course"
    end

    it "returns the default due time" do
      course.update!(default_due_time: "21:30:00")
      expect(course_type.resolve("settings { defaultDueTime }")).to eq "21:30:00"

      course.update!(default_due_time: nil)
      expect(course_type.resolve("settings { defaultDueTime }")).to eq "23:59:59"
    end
  end

  context "module IDs" do
    it "returns teacher and student only module IDs when set" do
      new_settings = course.settings.to_h.merge({
                                                  show_teacher_only_module_id: "123",
                                                  show_student_only_module_id: "456"
                                                })
      course.settings = new_settings
      course.save!

      expect(course_type.resolve("settings { showTeacherOnlyModuleId }", current_user: @teacher)).to eq "123"
      expect(course_type.resolve("settings { showStudentOnlyModuleId }", current_user: @teacher)).to eq "456"
    end

    it "returns nil when module IDs are not set" do
      expect(course_type.resolve("settings { showTeacherOnlyModuleId }")).to be_nil
      expect(course_type.resolve("settings { showStudentOnlyModuleId }")).to be_nil
    end
  end

  context "permissions" do
    it "returns nil when user doesn't have read permissions" do
      course_with_student
      @course2, @student2 = @course, @student

      course_type2 = GraphQLTypeTester.new(course, current_user: @student2)
      expect(course_type2.resolve("settings { allowFinalGradeOverride }")).to be_nil
    end
  end
end
