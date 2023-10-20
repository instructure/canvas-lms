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
  end

  context "with page" do
    before do
      @page = @course.wiki_pages.create!(title: "ponies5ever", body: "")
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

      context "permanent_page_links enabled" do
        before :once do
          Account.site_admin.enable_feature!(:permanent_page_links)
        end

        before do
          @page.wiki_page_lookups.create!(slug: "an-old-url")
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        it "redirects to current page url" do
          get "show", params: { course_id: @course.id, id: "an-old-url" }
          expect(response).to redirect_to(course_wiki_page_url(@course, "ponies5ever"))
        end

        it "emits wikipage.show.page_url_resolved to statsd when finding a page from a stale URL" do
          get "show", params: { course_id: @course.id, id: "an-old-url" }
          expect(InstStatsd::Statsd).to have_received(:increment).once.with("wikipage.show.page_url_resolved")
        end

        it "does not emit wikipage.show.page_url_resolved to statsd when using the current page URL" do
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("wikipage.show.page_url_resolved")
        end
      end
    end

    describe "GET 'edit'" do
      it "renders" do
        get "edit", params: { course_id: @course.id, id: @page.url }
        expect(response).to be_successful
      end
    end

    describe "GET 'revisions'" do
      it "renders" do
        get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
        expect(response).to be_successful
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

    context "differentiated assignments" do
      before do
        assignment = @course.assignments.create!(
          submission_types: "wiki_page",
          only_visible_to_overrides: true
        )
        @page.assignment = assignment
        @page.editing_roles = "teachers,students"
        @page.save!

        @student_with_override, @student_without_override = create_users(2, return_type: :record)
        @section = @course.course_sections.create!(name: "test section")
        create_section_override_for_assignment(assignment, course_section: @section)
      end

      context "for unassigned students" do
        before do
          @course.enroll_student(@student_without_override, enrollment_state: "active")
          user_session(@student_without_override)
        end

        it "allows show" do
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(response).to have_http_status :ok
        end

        it "allows edit" do
          get "edit", params: { course_id: @course.id, id: @page.url }
          expect(response).to have_http_status :ok
        end

        it "allows revisions" do
          get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
          expect(response).to have_http_status :ok
        end

        context "feature enabled" do
          before do
            allow(ConditionalRelease::Service).to receive(:service_configured?).and_return(true)
            @course.conditional_release = true
            @course.save!
          end

          it "forbids show" do
            get "show", params: { course_id: @course.id, id: @page.url }
            expect(response).to be_redirect
            expect(response.location).to eq course_wiki_pages_url(@course)
          end

          it "forbids edit" do
            get "edit", params: { course_id: @course.id, id: @page.url }
            expect(response).to be_redirect
            expect(response.location).to eq course_wiki_pages_url(@course)
          end

          it "forbids revisions" do
            get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
            expect(response).to be_redirect
            expect(response.location).to eq course_wiki_pages_url(@course)
          end
        end
      end

      context "for assigned students" do
        before do
          student_in_section(@section, user: @student_with_override)
          user_session(@student_with_override)
        end

        it "allows show" do
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(response).to have_http_status :ok
        end

        it "allows edit" do
          get "edit", params: { course_id: @course.id, id: @page.url }
          expect(response).to have_http_status :ok
          expect(controller.js_env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to be false
        end

        it "allows revisions" do
          get "revisions", params: { course_id: @course.id, wiki_page_id: @page.url }
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe "metrics" do
    before do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
    end

    context "show" do
      context "with edit rights" do
        it "increments the count metric for a nonexistent page" do
          course_with_teacher_logged_in(active_all: true)
          bad_page_url = "something-that-doesnt-really-exist"
          get "show", params: { course_id: @course.id, id: bad_page_url }
          expect(InstStatsd::Statsd).to have_received(:increment).with("wikipage.show.page_does_not_exist.with_edit_rights")
        end

        it "does not increment the count metric when page is deleted" do
          course_with_teacher_logged_in(active_all: true)
          @page = @course.wiki_pages.create!(title: "delete me")
          @page.update(workflow_state: "deleted")
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("wikipage.show.page_does_not_exist.with_edit_rights")
        end
      end

      context "without edit rights" do
        it "increments the count metric for a nonexistent page" do
          course_with_student_logged_in(active_all: true)
          bad_page_url = "something-else-that-doesnt-really-exist"
          get "show", params: { course_id: @course.id, id: bad_page_url }
          expect(InstStatsd::Statsd).to have_received(:increment).with("wikipage.show.page_does_not_exist.without_edit_rights")
        end

        it "does not increment the count metric when page is deleted" do
          course_with_student_logged_in(active_all: true)
          @page = @course.wiki_pages.create!(title: "delete me too")
          @page.update(workflow_state: "deleted")
          get "show", params: { course_id: @course.id, id: @page.url }
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("wikipage.show.page_does_not_exist.without_edit_rights")
        end
      end
    end
  end
end
