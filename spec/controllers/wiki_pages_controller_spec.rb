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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WikiPagesController do
  before do
    course_with_teacher_logged_in(active_all: true)
    @wiki = @course.wiki
  end

  describe "GET 'front_page'" do
    it "should redirect" do
      get 'front_page', :course_id => @course.id
      expect(response).to be_redirect
      expect(response.location).to match(%r{/courses/#{@course.id}/pages})
    end

    it "sets up js_env for view_all_pages link" do
      front_page = @wiki.wiki_pages.create!(title: "ponies4ever")
      @wiki.set_front_page_url!(front_page.url)
      get 'front_page', course_id: @course.id
      expect(response).to be_success
      expect(assigns[:js_env][:DISPLAY_SHOW_ALL_LINK]).to be(true)
    end
  end

  context "with page" do
    before do
      @page = @wiki.wiki_pages.create!(title: "ponies5ever", body: "")
    end

    describe "GET 'show_redirect'" do
      it "should redirect" do
        get 'show_redirect', :course_id => @course.id, :id => @page.url
        expect(response).to be_redirect
        expect(response.location).to match(%r{/courses/#{@course.id}/pages/#{@page.url}})
      end
    end

    describe "GET 'show'" do
      it "should render" do
        get 'show', course_id: @course.id, id: @page.url
        expect(response).to be_successful
      end
    end

    describe "GET 'edit'" do
      it "should render" do
        get 'edit', course_id: @course.id, id: @page.url
        expect(response).to be_successful
      end
    end

    describe "GET 'revisions'" do
      it "should render" do
        get 'revisions', course_id: @course.id, wiki_page_id: @page.url
        expect(response).to be_successful
      end
    end

    context "differentiated assignments" do
      before do
        assignment = @course.assignments.create!(
          submission_types: 'wiki_page',
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
          @course.enroll_student(@student_without_override, enrollment_state: 'active')
          user_session(@student_without_override)
        end

        it "should allow show" do
          get 'show', course_id: @course.id, id: @page.url
          expect(response.code).to eq "200"
        end

        it "should allow edit" do
          get 'edit', course_id: @course.id, id: @page.url
          expect(response.code).to eq "200"
        end

        it "should allow revisions" do
          get 'revisions', course_id: @course.id, wiki_page_id: @page.url
          expect(response.code).to eq "200"
        end

        context "feature enabled" do
          before do
            ConditionalRelease::Service.stubs(:configured?).returns(true)
            @course.enable_feature!(:conditional_release)
          end

          it "should forbid show" do
            get 'show', course_id: @course.id, id: @page.url
            expect(response).to be_redirect
            expect(response.location).to eq course_wiki_pages_url(@course)
          end

          it "should forbid edit" do
            get 'edit', course_id: @course.id, id: @page.url
            expect(response).to be_redirect
            expect(response.location).to eq course_wiki_pages_url(@course)
          end

          it "should forbid revisions" do
            get 'revisions', course_id: @course.id, wiki_page_id: @page.url
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

        it "should allow show" do
          get 'show', course_id: @course.id, id: @page.url
          expect(response.code).to eq "200"
        end

        it "should allow edit" do
          get 'edit', course_id: @course.id, id: @page.url
          expect(response.code).to eq "200"
          expect(controller.js_env[:CONDITIONAL_RELEASE_SERVICE_ENABLED]).to eq false
        end

        it "should allow revisions" do
          get 'revisions', course_id: @course.id, wiki_page_id: @page.url
          expect(response.code).to eq "200"
        end
      end
    end
  end
end
