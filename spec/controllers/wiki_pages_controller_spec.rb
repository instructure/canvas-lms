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

describe WikiPagesController do
  before do
    course_with_teacher_logged_in(active_all: true)
    @wiki = @course.wiki
  end

  describe "new page" do
    render_views

    context "when 'canvas_content_builder' feature is enabled" do
      before do
        @course.account.enable_feature!(:canvas_content_builder)
      end

      it "renders new page" do
        get :new, params: { course_id: @course.id }
        expect(response).to have_http_status(:ok)
      end

      it "sets rce_js_env" do
        get :new, params: { course_id: @course.id }
        expect(assigns[:js_env]).to have_key :RICH_CONTENT_APP_HOST
      end
    end

    context "when 'canvas_content_builder' feature is disabled" do
      before do
        @course.account.disable_feature!(:canvas_content_builder)
      end

      it "renders error page" do
        get :new, params: { course_id: @course.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET 'front_page'" do
    it "redirects" do
      get "front_page", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages})
    end

    it "sets up js_env for view_all_pages link" do
      front_page = @course.wiki_pages.create!(title: "ponies4ever")
      @wiki.set_front_page_url!(front_page.url)
      get "front_page", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:js_env][:DISPLAY_SHOW_ALL_LINK]).to be(true)
    end

    it "suppresses text editor preferences with block editor FF off" do
      @user.set_preference(:text_editor_preference, "block_editor")
      @course.account.enable_feature!(:block_editor)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env][:text_editor_preference]).to eq "block_editor"
      @course.account.disable_feature!(:block_editor)
      get "index", params: { course_id: @course.id }
      expect(assigns[:js_env].keys).not_to include(:text_editor_preference)
    end

    describe "js_env for EDITOR_FEATURE" do
      context "when the block editor is enabled" do
        it "sets EDITOR_FEATURE to block_editor" do
          @course.account.enable_feature!(:block_editor)
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:EDITOR_FEATURE]).to eq :block_editor
        end
      end

      context "when the canvas content builder is enabled" do
        it "sets EDITOR_FEATURE to canvas_content_builder" do
          @course.account.enable_feature!(:canvas_content_builder)
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:EDITOR_FEATURE]).to eq :canvas_content_builder
        end
      end

      context "when both features are enabled" do
        it "sets EDITOR_FEATURE to canvas_content_builder" do
          @course.account.enable_feature!(:block_editor)
          @course.account.enable_feature!(:canvas_content_builder)
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:EDITOR_FEATURE]).to eq :canvas_content_builder
        end
      end

      context "when neither feature is enabled" do
        it "sets EDITOR_FEATURE to nil" do
          get "index", params: { course_id: @course.id }
          expect(assigns[:js_env][:EDITOR_FEATURE]).to be_nil
        end
      end
    end

    context "assign to differentiation tags" do
      before do
        @course.account.enable_feature! :assign_to_differentiation_tags
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: true }
          a.save!
        end
      end

      it "adds differentiation tags information if account setting is on" do
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS]).to be true
        expect(assigns[:js_env][:CAN_MANAGE_DIFFERENTIATION_TAGS]).to be true
      end

      it "does not add differentiation tags information if user cannot manage tags" do
        course_with_student(active_all: true)
        user_session(@student)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS]).to be_nil
        expect(assigns[:js_env][:CAN_MANAGE_DIFFERENTIATION_TAGS]).to be_nil
      end
    end
  end

  context "with page" do
    before do
      @page = @course.wiki_pages.create!(title: "ponies5ever", body: "")
    end

    shared_examples_for("pages enforcing differentiation") do
      before do
        student_in_course(active_all: true)
        @page.update!(editing_roles: "teachers,students")
        user_session(@student)
      end

      context "regular pages" do
        it "allows access by default" do
          expect(response).to have_http_status :ok
        end

        it "does not allow access if page has only_visible_to_overrides=true" do
          @page.update!(only_visible_to_overrides: true)
          expect(response).to be_redirect
          expect(response.location).to eq course_wiki_pages_url(@course)
        end

        it "allows access if only_visible_to_overrides=true but the user has an override" do
          override = @page.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student)
          expect(response).to have_http_status :ok
        end

        it "does not allow access if page has only_visible_to_overrides=false but user does not have module override" do
          @page.update!(only_visible_to_overrides: false)
          module1 = @course.context_modules.create!(name: "module1")
          module1.add_item(id: @page.id, type: "wiki_page")
          module1.assignment_overrides.create!(set_type: "ADHOC")

          expect(response).to be_redirect
          expect(response.location).to eq course_wiki_pages_url(@course)
        end

        it "allows access if page has only_visible_to_overrides=false and user does have module override" do
          @page.update!(only_visible_to_overrides: false)
          module1 = @course.context_modules.create!(name: "module1")
          module1.add_item(id: @page.id, type: "wiki_page")

          adhoc_override = module1.assignment_overrides.create!(set_type: "ADHOC")
          adhoc_override.assignment_override_students.create!(user: @student)

          expect(response).to have_http_status :ok
        end
      end

      context "pages with an assignment" do
        before do
          assignment = @course.assignments.create!(
            submission_types: "wiki_page",
            only_visible_to_overrides: true
          )
          @page.assignment = assignment
          @page.save!
        end

        it "does not allow access if assignment has only_visible_to_overrides=true" do
          expect(response).to be_redirect
          expect(response.location).to eq course_wiki_pages_url(@course)
        end

        it "allows access if assignment has only_visible_to_overrides=true but the user has an override" do
          override = @page.assignment.assignment_overrides.create!
          override.assignment_override_students.create!(user: @student)
          expect(response).to have_http_status :ok
        end

        it "allows access if assignment has only_visible_to_overrides=false" do
          @page.assignment.update!(only_visible_to_overrides: false)
          expect(response).to have_http_status :ok
        end
      end
    end

    describe "GET 'show_redirect'" do
      it "redirects" do
        get "show_redirect", params: { course_id: @course.id, id: @page.url }
        expect(response).to be_redirect
        expect(response.location).to match(%r{/courses/#{@course.id}/pages/#{@page.url}})
      end
    end

    describe "GET 'show'" do
      it "renders" do
        get "show", params: { course_id: @course.id, id: @page.url }
        expect(response).to be_successful
      end

      context "differentiation" do
        let(:response) do
          get "show", params: { course_id: @course.id, id: @page.url }
        end

        it_behaves_like "pages enforcing differentiation"
      end

      context "permanent_page_links enabled" do
        before :once do
          Account.site_admin.enable_feature!(:permanent_page_links)
        end

        before do
          @page.wiki_page_lookups.create!(slug: "an-old-url")
          allow(InstStatsd::Statsd).to receive(:distributed_increment)
        end

        it "redirects to current page url" do
          get "show", params: { course_id: @course.id, id: "an-old-url" }
          expect(response).to redirect_to(course_wiki_page_url(@course, "ponies5ever"))
        end

        it "emits wikipage.show.page_url_resolved to statsd when finding a page from a stale URL" do
          get "show", params: { course_id: @course.id, id: "an-old-url" }
          expect(InstStatsd::Statsd).to have_received(:distributed_increment).once.with("wikipage.show.page_url_resolved")
        end

        it "does not emit wikipage.show.page_url_resolved to statsd when using the current page URL" do
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with("wikipage.show.page_url_resolved")
        end
      end
    end

    describe "GET 'edit'" do
      it "renders" do
        get "edit", params: { course_id: @course.id, id: @page.url }
        expect(response).to be_successful
      end

      context "differentiation" do
        let(:response) do
          get "edit", params: { course_id: @course.id, id: @page.url }
        end

        it_behaves_like "pages enforcing differentiation"
      end

      context "assign to differentiation tags" do
        before do
          @course.account.enable_feature! :assign_to_differentiation_tags
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: true }
            a.save!
          end
        end

        it "differentiation tags information is true if account setting is on and user can manage tags" do
          course_quiz
          user_session(@teacher)
          get "edit", params: { course_id: @course.id, id: @page.url }
          expect(assigns[:js_env][:ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS]).to be true
          expect(assigns[:js_env][:CAN_MANAGE_DIFFERENTIATION_TAGS]).to be true
        end
      end
    end

    describe "GET 'revisions'" do
      it "renders" do
        get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
        expect(response).to be_successful
      end

      context "differentiation" do
        let(:response) do
          get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
        end

        it_behaves_like "pages enforcing differentiation"
      end
    end

    it "js_env has placements for Commons Favorites Import" do
      allow(controller).to receive(:external_tools_display_hashes).and_return(["tool 1", "tool 2"])
      get "show", params: { course_id: @course.id, id: @page.url }
      expect(response).to be_successful
      expect(controller.js_env[:wiki_index_menu_tools]).to eq ["tool 1", "tool 2"]
    end

    context "when K5 mode is enabled and user is a student" do
      before do
        course_with_student(active_all: true)
        @course.account.enable_as_k5_account!
        @page = @course.wiki_pages.create!(title: "a page", body: "")
        user_session(@user)
      end

      it "hides the view_all_pages link" do
        get "show", params: { course_id: @course.id, id: @page.url }
        expect(response).to be_successful
        expect(controller.js_env[:DISPLAY_SHOW_ALL_LINK]).to be_falsey
      end
    end
  end

  describe "metrics" do
    before do
      allow(InstStatsd::Statsd).to receive(:distributed_increment).and_call_original
    end

    context "show" do
      context "with edit rights" do
        it "increments the count metric for a nonexistent page" do
          course_with_teacher_logged_in(active_all: true)
          bad_page_url = "something-that-doesnt-really-exist"
          get "show", params: { course_id: @course.id, id: bad_page_url }
          expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("wikipage.show.page_does_not_exist.with_edit_rights")
        end

        it "does not increment the count metric when page is deleted" do
          course_with_teacher_logged_in(active_all: true)
          @page = @course.wiki_pages.create!(title: "delete me")
          @page.update(workflow_state: "deleted")
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with("wikipage.show.page_does_not_exist.with_edit_rights")
        end
      end

      context "without edit rights" do
        it "increments the count metric for a nonexistent page" do
          course_with_student_logged_in(active_all: true)
          bad_page_url = "something-else-that-doesnt-really-exist"
          get "show", params: { course_id: @course.id, id: bad_page_url }
          expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("wikipage.show.page_does_not_exist.without_edit_rights")
        end

        it "does not increment the count metric when page is deleted" do
          course_with_student_logged_in(active_all: true)
          @page = @course.wiki_pages.create!(title: "delete me too")
          @page.update(workflow_state: "deleted")
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:distributed_increment).with("wikipage.show.page_does_not_exist.without_edit_rights")
        end
      end
    end
  end
end
