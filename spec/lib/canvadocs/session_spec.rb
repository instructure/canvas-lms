# frozen_string_literal: true

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

describe Canvadocs::Session do
  include Canvadocs::Session

  def submissions
    [@submission]
  end

  attr_reader :attachment

  describe ".observing?" do
    it "returns true if the user is acting as an observer" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: "active")
      observer = user_factory(active_all: true, active_state: "active")
      assignment = course.assignments.create!(title: "assignment 1", name: "assignment 1")
      section = course.course_sections.create!(name: "Section A")
      observer_enrollment = course.enroll_user(
        observer,
        "ObserverEnrollment",
        enrollment_state: "active",
        section:
      )
      observer_enrollment.update!(associated_user_id: student.id)
      assignment.update!(submission_types: "online_upload")
      @submission = submission_model(user: student, course:, assignment:)
      expect(observing?(observer)).to be true
    end

    it "returns false if the user is not an observer" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: "active")
      not_observer = user_factory(active_all: true, active_state: "active")
      assignment = course.assignments.create!(title: "assignment 1", name: "assignment 1")
      section = course.course_sections.create!(name: "Section A")
      course.enroll_user(
        not_observer,
        "StudentEnrollment",
        enrollment_state: "active",
        section:
      )
      assignment.update!(submission_types: "online_upload")
      @submission = submission_model(user: student, course:, assignment:)
      expect(observing?(not_observer)).to be false
    end
  end

  describe ".managing?" do
    it "returns true if the user has TeacherEnrollment" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: "active")
      teacher = user_factory(active_all: true, active_state: "active")
      assignment = course.assignments.create!(title: "assignment 1", name: "assignment 1")
      section = course.course_sections.create!(name: "Section A")
      course.enroll_user(
        teacher,
        "TeacherEnrollment",
        enrollment_state: "active",
        section:
      )
      assignment.update!(submission_types: "online_upload")
      @submission = submission_model(user: student, course:, assignment:)
      expect(managing?(teacher)).to be true
    end

    it "returns false if the user does not have a TeacherEnrollment" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: "active")
      not_teacher = user_factory(active_all: true, active_state: "active")
      assignment = course.assignments.create!(title: "assignment 1", name: "assignment 1")
      section = course.course_sections.create!(name: "Section A")
      course.enroll_user(
        not_teacher,
        "DesignerEnrollment",
        enrollment_state: "active",
        section:
      )
      assignment.update!(submission_types: "online_upload")
      @submission = submission_model(user: student, course:, assignment:)
      expect(managing?(not_teacher)).to be false
    end
  end

  describe ".canvadoc_permissions_for_user" do
    before(:once) do
      @course = course_factory(active_all: true)
      @student = user_factory(active_all: true, active_state: "active")
      @assignment = @course.assignments.create!(title: "assignment 1", name: "assignment 1", submission_types: "online_upload")
      @submission = submission_model(user: @student, course: @course, assignment: @assignment)
    end

    it "returns read permissions for observers" do
      observer = user_factory(active_all: true, active_state: "active")
      section = @course.course_sections.create!(name: "Section A")
      observer_enrollment = @course.enroll_user(
        observer,
        "ObserverEnrollment",
        enrollment_state: "active",
        section:
      )
      observer_enrollment.update!(associated_user_id: @student.id)
      permissions = canvadoc_permissions_for_user(observer, true)
      expect(permissions[:permissions]).to eq "read"
    end

    it "returns readwrite permissions for owner" do
      permissions = canvadoc_permissions_for_user(@student, true)
      expect(permissions[:permissions]).to eq "readwrite"
    end

    it "returns readwritemanage permissions for teacher" do
      teacher = user_factory(active_all: true, active_state: "active")
      section = @course.course_sections.create!(name: "Section A")
      @course.enroll_user(
        teacher,
        "TeacherEnrollment",
        enrollment_state: "active",
        section:
      )
      permissions = canvadoc_permissions_for_user(teacher, true)
      expect(permissions[:permissions]).to eq "readwritemanage"
    end

    it "returns 'read' permissions when read_only is true" do
      permissions = canvadoc_permissions_for_user(@student, true, true)
      expect(permissions[:permissions]).to eq "read"
    end

    it "does not return 'read' permissions when read_only is false" do
      permissions = canvadoc_permissions_for_user(@student, true, false)
      expect(permissions[:permissions]).not_to eq "read"
    end

    it "does not return 'read' permissions when read_only is not included" do
      permissions = canvadoc_permissions_for_user(@student, true)
      expect(permissions[:permissions]).not_to eq "read"
    end

    it "includes a user_filter if the user cannot read grades" do
      @assignment.ensure_post_policy(post_manually: true)
      permissions = canvadoc_permissions_for_user(@student, true)
      expect(permissions).to have_key(:user_filter)
    end

    it "does not include a user_filter if the user can read grades" do
      @assignment.ensure_post_policy(post_manually: false)
      permissions = canvadoc_permissions_for_user(@student, true)
      expect(permissions).not_to have_key(:user_filter)
    end

    # specific logic had to be added for "student annotation" assignments because the same document
    # is shared among multiple students (and associated with multiple submissions)
    context "student annotation assignments" do
      before do
        @attachment = attachment_model(context: @course)
        @assignment = @course.assignments.create!(title: "annotation assignment", submission_types: "student_annotation", anonymous_peer_reviews: true, peer_reviews: true, annotatable_attachment: @attachment)
        @peer_student = user_factory(active_all: true, active_state: "active")
        @submitted_student = user_factory(active_all: true, active_state: "active")

        # create submissions and assessment request
        peer_submission = submission_model(user: @peer_student, course: @course, assignment: @assignment)
        @submission = submission_model(user: @submitted_student, course: @course, assignment: @assignment)
        @submission.assessment_requests.create!(assessor: @peer_student, user: @submitted_student, asset: @submission, assessor_asset: peer_submission)
      end

      it "returns 'read' for peer reviewers on student annotation assignments" do
        permissions = canvadoc_permissions_for_user(@peer_student, true)
        expect(permissions[:permissions]).to eq "read"
      end

      it "returns 'readwrite' for students on student annotation assignments" do
        permissions = canvadoc_permissions_for_user(@submitted_student, true)
        expect(permissions[:permissions]).to eq "readwrite"
      end
    end

    context "cross-shard user" do
      specs_require_sharding

      before(:once) do
        @shard1.activate do
          @xs_user = User.create!(name: "cross-shard user")
        end
      end

      it "returns 'readwritemanage' for cross-shard teacher" do
        @course.enroll_teacher(@xs_user, enrollment_state: "active")
        permissions = canvadoc_permissions_for_user(@xs_user, true)
        expect(permissions[:permissions]).to eq "readwritemanage"
      end

      it "returns 'read' for cross-shard observer" do
        @course.enroll_user(@xs_user, "ObserverEnrollment", enrollment_state: "active", associated_user_id: @student.id)
        permissions = canvadoc_permissions_for_user(@xs_user, true)
        expect(permissions[:permissions]).to eq "read"
      end
    end
  end
end
