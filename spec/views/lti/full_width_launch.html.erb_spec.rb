# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"
require "views/views_helper"

describe "lti full width launch view" do
  include_context "lti_layout_spec_helper"

  describe "for Quizzes 2 / New Quizzes / Quizzes.Next assignments" do
    let(:course) { course_factory(active_course: true) }
    let(:tool) do
      dev_key = DeveloperKey.create
      tool_id = ContextExternalTool::QUIZ_LTI
      ContextExternalTool.create(developer_key: dev_key, context: course, tool_id:, root_account: course.root_account)
    end
    let(:tag) { LtiLayoutSpecHelper.create_tag(tool) }
    let(:current_user) { user_with_pseudonym }

    before do
      ctrl.instance_variable_set(:@domain_root_account, Account.default)
      ctrl.instance_variable_set(:@current_user, current_user)
    end

    context "when the user is a student" do
      context "in an active course" do
        it "does not warn the student with an active enrollment about a New Quizzes being unavailable" do
          course.enroll_student(current_user, enrollment_state: "active")
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end

        it "warns the student with a concluded enrollment about a New Quizzes being unavailable" do
          course.enroll_student(current_user, enrollment_state: "completed")
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).to include("no longer available")
        end

        context "with sections" do
          let(:active_section) { add_section("Section A", { course: }) }

          let(:completed_section) do
            section = add_section("Section B", { course: })
            section.restrict_enrollments_to_section_dates = true
            section.start_at = 3.days.ago
            section.end_at = 1.day.ago
            section.tap(&:save!)
          end

          it "does not warn the student in an active section about a New Quizzes being unavailable" do
            active_section.enroll_user(current_user, "StudentEnrollment", "active")
            ctrl.send(:content_tag_redirect, Account.default, tag, nil)
            expect(ctrl.response.body).not_to include("no longer available")
          end

          it "warns the student in a completed section about a New Quizzes being unavailable" do
            completed_section.enroll_user(current_user, "StudentEnrollment", "active")
            ctrl.send(:content_tag_redirect, Account.default, tag, nil)
            expect(ctrl.response.body).to include("no longer available")
          end

          it "does not warn the student who has at least one active section about a New Quizzes being unavailable" do
            active_section.enroll_user(current_user, "StudentEnrollment", "active")
            completed_section.enroll_user(current_user, "StudentEnrollment", "active")
            ctrl.send(:content_tag_redirect, Account.default, tag, nil)
            expect(ctrl.response.body).not_to include("no longer available")
          end
        end
      end

      context "in a soft concluded course" do
        it "warns the student about a New Quizzes being unavailable" do
          course.enroll_student(current_user, enrollment_state: "active")
          course.soft_conclude!
          course.save!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).to include("no longer available")
        end
      end

      context "in an concluded course" do
        it "warns the student with an active enrollment about a New Quizzes being unavailable" do
          course.enroll_student(current_user, enrollment_state: "active")
          course.complete!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).to include("no longer available")
        end
      end
    end

    context "when the user is a student view user" do
      let(:current_user) { course.student_view_student }

      before do
        ctrl.instance_variable_set(:@current_user, current_user)
      end

      it "does not warn about quizzes being unavailable when the user is active" do
        ctrl.send(:content_tag_redirect, Account.default, tag, nil)
        expect(ctrl.response.body).not_to include("no longer available")
      end
    end

    context "when the user is an observer" do
      it "warns the observer with a concluded enrollment about a New Quizzes being unavailable" do
        course.enroll_user(current_user, "ObserverEnrollment", enrollment_state: "completed")
        ctrl.send(:content_tag_redirect, Account.default, tag, nil)
        expect(ctrl.response.body).to include("no longer available")
      end
    end

    context "when the user is a teacher" do
      before do
        course.enroll_teacher(current_user, enrollment_state: "active")
      end

      context "in an active course" do
        it "does not warn the teacher about a New Quizzes being unavailable" do
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a soft concluded course" do
        it "does not warn the teacher about a New Quizzes being unavailable" do
          course.soft_conclude!
          course.save!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a concluded course" do
        it "does not warn the teacher about a New Quizzes being unavailable" do
          course.complete!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end
    end

    context "when the user is an account admin" do
      let(:current_user) { account_admin_user }

      context "in an active course" do
        it "does not warn the account admin about a New Quizzes being unavailable" do
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a soft concluded course" do
        it "does not warn the account admin about a New Quizzes being unavailable" do
          course.soft_conclude!
          course.save!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a concluded course" do
        it "does not warn the account admin about a New Quizzes being unavailable" do
          course.complete!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end
    end

    context "when the user is a site admin" do
      let(:current_user) { site_admin_user }

      context "in an active course" do
        it "does not warn the site admin about a New Quizzes being unavailable" do
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a soft concluded course" do
        it "does not warn the site admin about a New Quizzes being unavailable" do
          course.soft_conclude!
          course.save!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end

      context "in a concluded course" do
        it "does not warn the site admin about a New Quizzes being unavailable" do
          course.complete!
          ctrl.send(:content_tag_redirect, Account.default, tag, nil)
          expect(ctrl.response.body).not_to include("no longer available")
        end
      end
    end
  end
end
