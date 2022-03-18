# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../api_spec_helper"
require_relative "../locked_spec"
require_relative "../../lti_spec_helper"

describe WikiPagesApiController, type: :request do
  include Api
  include Api::V1::Assignment
  include Api::V1::WikiPage
  include LtiSpecHelper

  ["post", "put"].each do |http_verb|
    describe "creating a wiki page via #{http_verb}" do
      before :once do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)

        if http_verb == "post"
          @action = "create"
          @http_verb = :post
          @url = "/api/v1/courses/#{@course.id}/pages"
        else
          @action = "update"
          @http_verb = :put
          @url = "/api/v1/courses/#{@course.id}/pages/new-page"
        end
      end

      def create_wiki_page(user, wiki_params, expected_status = 200)
        path = {
          controller: "wiki_pages_api",
          action: @action,
          format: "json",
          course_id: @course.id.to_s,
        }
        path[:url] = "new-page" if @http_verb == :put
        params = { wiki_page: wiki_params }
        api_call_as_user(user, @http_verb, @url, path, params, {}, { expected_status: expected_status })
      end

      context "with a title containing charaters from the Katakana script" do
        let(:created_page) do
          create_wiki_page(
            @teacher,
            { title: "グループ映画プロジェクトの概要hi", body: "banana" }
          )
          WikiPage.last
        end

        it "uses the unicode titles in the url" do
          expect(created_page.url).to eq "グループ映画プロジェクトの概要hi"
        end
      end

      context "with the user having manage_wiki_create permission" do
        it "succeeds" do
          create_wiki_page(@teacher, { title: "New Page", body: "banana" })
          expect(WikiPage.last.title).to eq "New Page"
          expect(WikiPage.last.body).to eq "banana"
        end

        context "when the page content is too deeply nested" do
          before do
            stub_const("CanvasSanitize::SANITIZE", { parser_options: { max_tree_depth: 1 } })
          end

          it "responds with bad request" do
            create_wiki_page(@teacher, { title: "New Page", body: "<div><p>too long</p></div>" }, 400)
          end
        end

        context "when the user also has manage_wiki_update permission" do
          it "is not published by default" do
            create_wiki_page(@teacher, { title: "New Page" })
            expect(WikiPage.last.workflow_state).to eq "unpublished"
          end

          it "can be explictly published" do
            create_wiki_page(@teacher, { title: "New Page", published: true })
            expect(WikiPage.last.workflow_state).to eq "active"
          end

          it 'allows the "editing_roles" field to be set' do
            create_wiki_page(@teacher, { title: "New Page", editing_roles: "public" })
            expect(WikiPage.last.editing_roles).to eq "public"
          end
        end

        context "when the user does not have manage_wiki_update permission" do
          before :once do
            teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
            RoleOverride.create!(
              permission: "manage_wiki_update",
              enabled: false,
              role: teacher_role,
              account: @course.root_account
            )
          end

          it "is published by default when created" do
            create_wiki_page(@teacher, { title: "New Page" })
            expect(WikiPage.last.workflow_state).to eq "active"
          end

          it "cannot be explictly unpublished when created" do
            create_wiki_page(@teacher, { title: "New Page", published: false }, 401)
            expect(WikiPage.last).to be_nil
          end

          it 'does not allow the "editing_roles" field to be set' do
            create_wiki_page(@teacher, { title: "New Page", editing_roles: "public" }, 401)
            expect(WikiPage.last).to be_nil
          end
        end

        context "with the user not having manage_wiki_create permission" do
          it "fails if the course does not grant create wiki page permission" do
            create_wiki_page(@student, { title: "New Page" }, 401)
            expect(WikiPage.last).to be_nil
          end

          it "succeeds if the course grants create wiki page permission" do
            @course.update!({ default_wiki_editing_roles: "teachers,students" })
            create_wiki_page(@student, { title: "New Page", body: "banana" })
            expect(WikiPage.last.title).to eq "New Page"
            expect(WikiPage.last.body).to eq "banana"
          end

          it 'does not allow the "who can edit" field to be set' do
            @course.update!({ default_wiki_editing_roles: "teachers,students" })
            create_wiki_page(@student, { title: "New Page", editing_roles: "public" }, 401)
            expect(WikiPage.last).to be_nil
          end

          it "is published automatically when created" do
            @course.update!({ default_wiki_editing_roles: "teachers,students" })
            create_wiki_page(@student, { title: "New Page" })
            expect(WikiPage.last.workflow_state).to eq "active"
          end

          it "cannot be set as unpublished when created" do
            @course.update!({ default_wiki_editing_roles: "teachers,students" })
            create_wiki_page(@student, { title: "New Page", published: false }, 401)
            expect(WikiPage.last).to be_nil
          end
        end
      end
    end
  end

  describe "DELETE" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      wiki_page_model({ title: "Wiki Page" })
    end

    def delete_wiki_page(user, expected_status = 200)
      url = "/api/v1/courses/#{@course.id}/pages/#{@page.url}"
      path = {
        controller: "wiki_pages_api",
        action: "destroy",
        format: "json",
        course_id: @course.id.to_s,
        url: @page.url,
      }
      api_call_as_user(user, :delete, url, path, {}, {}, { expected_status: expected_status })
    end

    it "allows you to destroy a wiki page if you have the manage_wiki_delete permission" do
      delete_wiki_page(@teacher)
      expect(@page.reload.workflow_state).to eq "deleted"
    end

    it "does not allow you to destroy a wiki page if you do not have the manage_wiki_delete permission" do
      teacher_role = Role.get_built_in_role("TeacherEnrollment", root_account_id: Account.default.id)
      RoleOverride.create!(
        permission: "manage_wiki_delete",
        enabled: false,
        role: teacher_role,
        account: @course.root_account
      )
      delete_wiki_page(@teacher, 401)
      expect(@page.reload.workflow_state).to eq "active"
    end
  end

  describe "GET" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      wiki_page_model({ title: "Wiki Page" })
    end

    def get_wiki_page(user, expected_status = 200)
      url = "/api/v1/courses/#{@course.id}/pages/#{@page.url}"
      path = {
        controller: "wiki_pages_api",
        action: "show",
        format: "json",
        course_id: @course.id.to_s,
        url: @page.url,
      }
      api_call_as_user(user, :get, url, path, {}, {}, { expected_status: expected_status })
    end

    it "works for teachers" do
      json = get_wiki_page(@teacher)
      expect(json["url"]).to eq @page.url
    end

    it "works for students" do
      json = get_wiki_page(@student)
      expect(json["url"]).to eq @page.url
    end

    it "fails for a student if the wiki page is unpublished" do
      @page.update!(workflow_state: "unpublished")
      json = get_wiki_page(@student, 401)
      expect(json["url"]).to be_nil
    end

    it "fails if you do not have read permissions" do
      user = User.create!
      json = get_wiki_page(user, 401)
      expect(json["url"]).to be_nil
    end
  end

  describe "POST 'duplicate'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      wiki_page_model({ title: "Wiki Page" })
    end

    it "returns unauthorized if not a teacher" do
      api_call_as_user(@student, :post,
                       "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
                       { controller: "wiki_pages_api",
                         action: "duplicate",
                         format: "json",
                         course_id: @course.id.to_s,
                         url: @page.url },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "can duplicate wiki non-assignment if teacher" do
      json = api_call_as_user(@teacher, :post,
                              "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
                              { controller: "wiki_pages_api",
                                action: "duplicate",
                                format: "json",
                                course_id: @course.id.to_s,
                                url: @page.url },
                              {},
                              {},
                              { expected_status: 200 })
      expect(json["title"]).to eq "Wiki Page Copy"
    end

    it "can duplicate wiki assignment if teacher" do
      wiki_page_assignment_model({ title: "Assignment Wiki" })
      json = api_call_as_user(@teacher, :post,
                              "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
                              { controller: "wiki_pages_api",
                                action: "duplicate",
                                format: "json",
                                course_id: @course.id.to_s,
                                url: @page.url },
                              {},
                              {},
                              { expected_status: 200 })
      expect(json["title"]).to eq "Assignment Wiki Copy"
    end
  end
end
