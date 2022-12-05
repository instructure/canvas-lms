# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/collaborations_common"
require_relative "../helpers/collaborations_specs_common"
require_relative "../helpers/google_drive_common"

describe "collaborations" do
  include_context "in-process server selenium tests"
  include CollaborationsCommon
  include CollaborationsSpecsCommon
  include GoogleDriveCommon

  context "a Student's" do
    title = "Google Docs"
    type = "google_docs"

    context "#{title} collaboration" do
      before do
        course_with_student_logged_in
        setup_google_drive
      end

      it "is editable", priority: "1" do
        be_editable(type, title)
      end

      it "is delete-able", priority: "1" do
        be_deletable(type, title)
      end

      it "displays available collaborators", priority: "1" do
        display_available_collaborators(type)
      end

      it "start collaboration with people", priority: "1" do
        skip_if_safari(:alert)
        select_collaborators_and_look_for_start(type)
      end
    end

    context "Google Docs collaborations with google docs not having access" do
      before do
        course_with_teacher_logged_in
        setup_google_drive(false, false)
      end

      it "is not editable if google drive does not have access to your account", priority: "1" do
        no_edit_with_no_access
      end

      it "is not delete-able if google drive does not have access to your account", priority: "2" do
        no_delete_with_no_access
      end
    end
  end

  context "a student's etherpad collaboration" do
    before do
      course_with_teacher(active_all: true, name: "teacher@example.com")
      student_in_course(course: @course, name: "Don Draper")
    end

    it "is visible to the student", priority: "1" do
      PluginSetting.create!(name: "etherpad", settings: {})

      @collaboration = Collaboration.typed_collaboration_instance("EtherPad")
      @collaboration.context = @course
      @collaboration.attributes = { title: "My collaboration",
                                    user: @teacher }
      @collaboration.update_members([@student])
      @collaboration.save!

      user_session(@student)
      get "/courses/#{@course.id}/collaborations"

      expect(ff("#collaborations .collaboration")).to have_size(1)
    end
  end

  context "lti_collaborations" do
    before do
      course_with_teacher(active_all: true, name: "teacher@example.com")
      student_in_course(course: @course, name: "Don Draper", active_all: true)
      @course.account.set_feature_flag!(:new_collaborations, "on")
      @course.tab_configuration = [{ id: Course::TAB_COLLABORATIONS_NEW, hidden: true }]
      @course.save!
    end

    it "does not allow to navigate if page is disabled" do
      user_session(@student)
      get "/courses/#{@course.id}/lti_collaborations"
      assert_flash_notice_message "That page has been disabled for this course"
    end
  end
end
