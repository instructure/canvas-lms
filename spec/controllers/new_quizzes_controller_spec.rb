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

describe NewQuizzesController do
  let(:course) { course_model }
  let(:teacher) { teacher_in_course(course:, active_all: true).user }
  let(:student) { student_in_course(course:, active_all: true).user }
  let(:tool) do
    course.context_external_tools.create!(
      name: "New Quizzes",
      url: "http://example.com/launch",
      consumer_key: "key",
      shared_secret: "secret",
      tool_id: "Quizzes 2",
      course_navigation: { enabled: true }
    )
  end
  let(:assignment) do
    assignment = assignment_model(context: course, submission_types: "external_tool")
    assignment.external_tool_tag = ContentTag.create!(
      context: assignment,
      content: tool,
      url: tool.url,
      content_type: "ContextExternalTool"
    )
    assignment.save!
    assignment
  end

  before do
    course.enable_feature!(:new_quizzes_native_experience)
  end

  describe "#launch" do
    context "when feature flag is disabled" do
      before do
        course.disable_feature!(:new_quizzes_native_experience)
        user_session(teacher)
      end

      it "returns unauthorized" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        assert_unauthorized
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to redirect_to(login_url)
      end
    end

    context "when user is logged in and feature flag is enabled" do
      before do
        user_session(teacher)
      end

      it "renders the native new quizzes view" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to render_template("assignments/native_new_quizzes")
      end

      it "sets the NEW_QUIZZES js_env" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns[:js_env][:NEW_QUIZZES]).to be_present
      end

      it "sets the basename in js_env" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        expect(assigns[:js_env][:NEW_QUIZZES][:basename]).to eq("/courses/#{course.id}/assignments/#{assignment.id}")
      end

      it "calculates basename correctly when path param is present" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id, path: "settings" }
        # Basename should NOT include the workflow segment (e.g., /build, /moderation)
        # React Router uses this as a prefix, and routes are matched after it
        expect(assigns[:js_env][:NEW_QUIZZES][:basename]).to eq("/courses/#{course.id}/assignments/#{assignment.id}")
      end

      it "removes workflow segment from basename for subroutes" do
        # Test that subroutes like moderation, reporting, exports have workflow removed from basename
        %w[build moderation reporting exports taking observing errors].each do |workflow|
          get :launch, params: { course_id: course.id, assignment_id: assignment.id, path: "123" }
          allow(request).to receive(:path).and_return("/courses/#{course.id}/assignments/#{assignment.id}/#{workflow}/123")
          expect(assigns[:js_env][:NEW_QUIZZES][:basename]).to eq("/courses/#{course.id}/assignments/#{assignment.id}")
        end
      end

      context "when assignment is not quiz_lti" do
        let(:regular_assignment) { assignment_model(context: course) }

        it "returns unauthorized" do
          get :launch, params: { course_id: course.id, assignment_id: regular_assignment.id }
          assert_unauthorized
        end
      end

      context "with different route actions" do
        %w[build reporting moderation exports taking observing].each do |action|
          it "renders native new quizzes for #{action} route" do
            get :launch, params: { course_id: course.id, assignment_id: assignment.id }
            expect(response).to render_template("assignments/native_new_quizzes")
          end
        end
      end

      context "with module_item_id" do
        let(:context_module) { course.context_modules.create!(name: "Test Module") }
        let(:module_tag) do
          context_module.add_item(type: "assignment", id: assignment.id)
        end

        it "uses the specific module tag when module_item_id is provided" do
          get :launch, params: {
            course_id: course.id,
            assignment_id: assignment.id,
            module_item_id: module_tag.id
          }
          expect(response).to render_template("assignments/native_new_quizzes")
        end
      end
    end

    context "when user is a student" do
      before do
        course.offer!
        user_session(student)
      end

      it "renders the native new quizzes view for authorized students" do
        get :launch, params: { course_id: course.id, assignment_id: assignment.id }
        expect(response).to render_template("assignments/native_new_quizzes")
      end
    end
  end

  describe "#banks" do
    context "when feature flag is disabled" do
      before do
        course.disable_feature!(:new_quizzes_native_experience)
        user_session(teacher)
      end

      it "returns unauthorized" do
        get :banks, params: { course_id: course.id }
        assert_unauthorized
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get :banks, params: { course_id: course.id }
        expect(response).to redirect_to(login_url)
      end
    end

    context "when user is logged in and feature flag is enabled" do
      before do
        user_session(teacher)
        # Ensure quiz_lti tool exists for the course
        tool
      end

      it "renders the native new quizzes view" do
        get :banks, params: { course_id: course.id }
        expect(response).to render_template("assignments/native_new_quizzes")
      end

      it "sets the NEW_QUIZZES js_env" do
        get :banks, params: { course_id: course.id }
        expect(assigns[:js_env][:NEW_QUIZZES]).to be_present
      end

      it "sets the basename in js_env for course context" do
        get :banks, params: { course_id: course.id }
        expect(assigns[:js_env][:NEW_QUIZZES][:basename]).to eq("/courses/#{course.id}")
      end

      context "when no quiz_lti tool is found" do
        before do
          allow(Lti::ToolFinder).to receive(:from_context).and_return(nil)
        end

        it "returns unauthorized" do
          get :banks, params: { course_id: course.id }
          assert_unauthorized
        end
      end

      context "when tool is not quiz_lti" do
        before do
          regular_tool = course.context_external_tools.create!(
            name: "Regular Tool",
            url: "http://example.com/launch",
            consumer_key: "key",
            shared_secret: "secret",
            course_navigation: { enabled: true }
          )
          allow(Lti::ToolFinder).to receive(:from_context).and_return(regular_tool)
        end

        it "returns unauthorized" do
          get :banks, params: { course_id: course.id }
          assert_unauthorized
        end
      end
    end

    context "with account context" do
      let(:account) { Account.default }
      let(:account_tool) do
        account.context_external_tools.create!(
          name: "New Quizzes",
          url: "http://example.com/launch",
          consumer_key: "key",
          shared_secret: "secret",
          tool_id: "Quizzes 2",
          account_navigation: { enabled: true }
        )
      end

      before do
        account.enable_feature!(:new_quizzes_native_experience)
        account_admin_user(account:, active_all: true)
        user_session(@user)
        # Ensure quiz_lti tool exists for the account
        account_tool
      end

      it "renders the native new quizzes view" do
        get :banks, params: { account_id: account.id }
        expect(response).to render_template("assignments/native_new_quizzes")
      end

      it "sets the basename in js_env for account context" do
        get :banks, params: { account_id: account.id }
        expect(assigns[:js_env][:NEW_QUIZZES][:basename]).to eq("/accounts/#{account.id}")
      end

      it "sets the NEW_QUIZZES js_env" do
        get :banks, params: { account_id: account.id }
        expect(assigns[:js_env][:NEW_QUIZZES]).to be_present
      end
    end
  end
end
