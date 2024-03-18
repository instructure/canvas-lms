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

require_relative "../helpers/k5_common"

describe ContentExportsController do
  include K5Common

  describe "POST 'create'" do
    before do
      course_with_teacher_logged_in(active_all: true)
      allow_any_instance_of(Course).to receive(:feature_enabled?).with(:quizzes_next).and_return(true)
    end

    it "exports everything explicitly" do
      post "create", params: { course_id: @course.id }
      expect(response).to be_successful

      expect(ContentExport.last.selected_content[:everything]).to be_present
    end

    context "new_quizzes_common_cartridge FF is disabled" do
      before do
        allow(@course).to receive(:feature_enabled?).and_call_original
        Account.site_admin.disable_feature!(:new_quizzes_common_cartridge)
      end

      context "common cartridge export type" do
        before do
          assignment_model(submission_types: "external_tool", course: @course)
          tool = @c.context_external_tools.create!(
            name: "Quizzes.Next",
            consumer_key: "test_key",
            shared_secret: "test_secret",
            tool_id: "Quizzes 2",
            url: "http://example.com/launch"
          )
          @a.external_tool_tag_attributes = { content: tool }
          @a.save!
        end

        it "sets worflow_state to waiting_for_external_tool" do
          post "create", params: { course_id: @course.id, export_type: "common_cartridge" }
          expect(response).to be_successful

          expect(ContentExport.last.workflow_state).to eq "created"
        end
      end

      context "any other export type" do
        it "does not interfere with other export types" do
          post "create", params: { course_id: @course.id }
          expect(response).to be_successful

          expect(ContentExport.last.workflow_state).to eq "created"
        end
      end
    end

    context "new_quizzes_common_cartridge FF is enabled" do
      before do
        allow(@course).to receive(:feature_enabled?).and_call_original
        Account.site_admin.enable_feature!(:new_quizzes_common_cartridge)
      end

      context "common cartridge export type" do
        before do
          assignment_model(submission_types: "external_tool", course: @course)
          tool = @c.context_external_tools.create!(
            name: "Quizzes.Next",
            consumer_key: "test_key",
            shared_secret: "test_secret",
            tool_id: "Quizzes 2",
            url: "http://example.com/launch"
          )
          @a.external_tool_tag_attributes = { content: tool }
          @a.save!
        end

        it "sets worflow_state to waiting_for_external_tool" do
          post "create", params: { course_id: @course.id, export_type: "common_cartridge" }
          expect(response).to be_successful

          expect(ContentExport.last.workflow_state).to eq "waiting_for_external_tool"
        end
      end

      context "any other export type" do
        it "does not interfere with other export types" do
          post "create", params: { course_id: @course.id }
          expect(response).to be_successful

          expect(ContentExport.last.workflow_state).to eq "created"
        end
      end
    end
  end

  describe "GET 'index'" do
    before :once do
      course_factory(active_all: true)
    end

    before do
      user_session(@teacher)
    end

    it "loads classic theming in a classic course" do
      get :index, params: { course_id: @course.id }
      expect(assigns(:css_bundles)).to be_nil
      expect(assigns(:js_bundles)).to be_nil
    end

    it "loads k5 theming in a k5 course" do
      toggle_k5_setting(@course.account)
      get :index, params: { course_id: @course.id }
      expect(assigns(:css_bundles).flatten).to include(:k5_theme)
      expect(assigns(:js_bundles).flatten).to include(:k5_theme)
    end
  end

  describe "GET xml_schema" do
    describe "with a valid file" do
      let(:filename) { "cccv1p0" }
      let(:full_path) { Rails.root.join("lib/cc/xsd/#{filename}.xsd") }

      before { get "xml_schema", params: { version: filename } }

      it "sends in the entire file" do
        expect(response.header["Content-Length"].to_i).to eq File.size?(full_path)
      end

      it "recognizes the file as xml" do
        expect(response.header["Content-Type"]).to eq "text/xml"
      end
    end

    describe "with a nonexistant file" do
      before { get "xml_schema", params: { version: "notafile" } }

      it "returns a 404" do
        expect(response).not_to be_successful
      end

      it "renders the 404 template" do
        expect(response).to render_template("shared/errors/404_message")
      end
    end
  end

  describe "export visibility" do
    context "course" do
      before(:once) do
        course_factory active_all: true
        course_with_ta(course: @course, active_all: true)
        student_in_course(course: @course, active_all: true)
        @acx = factory_with_protected_attributes(@course.content_exports, user: @ta, export_type: "common_cartridge")
        @tcx = factory_with_protected_attributes(@course.content_exports, user: @teacher, export_type: "common_cartridge")
        @tzx = factory_with_protected_attributes(@course.content_exports, user: @teacher, export_type: "zip")
        @szx = factory_with_protected_attributes(@course.content_exports, user: @student, export_type: "zip")
      end

      describe "index" do
        it "returns all course exports + the teacher's file exports" do
          user_session(@teacher)
          get :index, params: { course_id: @course.id }
          expect(response).to be_successful
          expect(assigns(:exports).map(&:id)).to match_array [@acx.id, @tcx.id, @tzx.id]
        end
      end

      describe "show" do
        it "finds course exports" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @acx.id }
          expect(response).to be_successful
        end

        it "finds teacher's file exports" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @tzx.id }
          expect(response).to be_successful
        end

        it "does not find other's file exports" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @szx.id }
          assert_status(404)
        end
      end
    end

    context "user" do
      before(:once) do
        course_factory active_all: true
        student_in_course(course: @course, active_all: true)
        @tzx = factory_with_protected_attributes(@student.content_exports, user: @teacher, export_type: "zip")
        @sdx = factory_with_protected_attributes(@student.content_exports, user: @student, export_type: "user_data")
        @szx = factory_with_protected_attributes(@student.content_exports, user: @student, export_type: "zip")
      end

      describe "index" do
        it "shows one's own exports" do
          user_session(@student)
          get :index
          expect(response).to be_successful
          expect(assigns(:exports).map(&:id)).to match_array [@sdx.id, @szx.id]
        end
      end

      describe "show" do
        it "finds one's own export" do
          user_session(@student)
          get :show, params: { id: @sdx.id }
          expect(response).to be_successful
        end

        it "does not find another's export" do
          user_session(@student)
          get :show, params: { id: @tzx.id }
          assert_status(404)
        end
      end
    end
  end
end
