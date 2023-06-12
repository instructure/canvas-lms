# frozen_string_literal: true

#
# Copyright (C) 2012 Instructure, Inc.
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

describe TabsController, type: :request do
  describe "index" do
    it "requires read permissions on the context" do
      course_factory(active_all: true)
      user_factory(active_all: true)
      api_call(:get,
               "/api/v1/courses/#{@course.id}/tabs",
               { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
               { include: ["external"] },
               {},
               { expected_status: 404 })
    end

    it "lists navigation tabs for a course" do
      course_with_teacher(active_all: true)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/tabs",
                      { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                      { include: ["external"] })
      expect(json).to eq [
        {
          "id" => "home",
          "html_url" => "/courses/#{@course.id}",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}",
          "position" => 1,
          "visibility" => "public",
          "label" => "Home",
          "type" => "internal"
        },
        {
          "id" => "announcements",
          "html_url" => "/courses/#{@course.id}/announcements",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/announcements",
          "position" => 2,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Announcements",
          "type" => "internal"
        },
        {
          "id" => "assignments",
          "html_url" => "/courses/#{@course.id}/assignments",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments",
          "position" => 3,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Assignments",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/courses/#{@course.id}/discussion_topics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/discussion_topics",
          "position" => 4,
          "visibility" => "public",
          "label" => "Discussions",
          "type" => "internal"
        },
        {
          "id" => "grades",
          "html_url" => "/courses/#{@course.id}/grades",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/grades",
          "position" => 5,
          "visibility" => "public",
          "label" => "Grades",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/courses/#{@course.id}/users",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/users",
          "position" => 6,
          "visibility" => "public",
          "label" => "People",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/courses/#{@course.id}/wiki",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/wiki",
          "position" => 7,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Pages",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/courses/#{@course.id}/files",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/files",
          "position" => 8,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Files",
          "type" => "internal"
        },
        {
          "id" => "syllabus",
          "html_url" => "/courses/#{@course.id}/assignments/syllabus",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/syllabus",
          "position" => 9,
          "visibility" => "public",
          "label" => "Syllabus",
          "type" => "internal"
        },
        {
          "id" => "outcomes",
          "html_url" => "/courses/#{@course.id}/outcomes",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/outcomes",
          "position" => 10,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Outcomes",
          "type" => "internal"
        },
        {
          "id" => "rubrics",
          "html_url" => "/courses/#{@course.id}/rubrics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/rubrics",
          "position" => 11,
          "visibility" => "admins",
          "label" => "Rubrics",
          "type" => "internal"
        },
        {
          "id" => "quizzes",
          "html_url" => "/courses/#{@course.id}/quizzes",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/quizzes",
          "position" => 12,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Quizzes",
          "type" => "internal"
        },
        {
          "id" => "modules",
          "html_url" => "/courses/#{@course.id}/modules",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/modules",
          "position" => 13,
          "unused" => true,
          "visibility" => "admins",
          "label" => "Modules",
          "type" => "internal"
        },
        {
          "id" => "settings",
          "html_url" => "/courses/#{@course.id}/settings",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/settings",
          "position" => 14,
          "visibility" => "admins",
          "label" => "Settings",
          "type" => "internal"
        }
      ]
    end

    it "includes tabs for institution-visible courses" do
      course_factory(active_all: true)
      @course.update_attribute(:is_public_to_auth_users, true)
      user_with_pseudonym
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/tabs",
                      { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                      {},
                      {},
                      { expected_status: 200 })
      expect(json.pluck("id")).to include "home"
    end

    it "includes external tools" do
      course_with_teacher(active_all: true)
      @tool = @course.context_external_tools.new({
                                                   name: "Example",
                                                   url: "http://www.example.com",
                                                   consumer_key: "key",
                                                   shared_secret: "secret",
                                                 })
      @tool.settings[:course_navigation] = {
        enabled: "true",
        url: "http://www.example.com",
      }
      @tool.save!

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/tabs",
                      { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                      { include: ["external"] })

      external_tabs = json.select { |tab| tab["type"] == "external" }
      expect(external_tabs.length).to eq 1
      external_tabs.each do |tab|
        expect(tab).to include("url")
        uri = URI(tab["url"])
        expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        expect(uri.query).to include("id=")
        expect(uri.query).to include("launch_type=course_navigation")
      end
    end

    it "launches account navigation external tools with launch_type=account_navigation" do
      account_admin_user(active_all: true)
      @account = @user.account
      @tool = @account.context_external_tools.new(name: "Ex", url: "http://example.com", consumer_key: "k", shared_secret: "s")
      @tool.settings[:account_navigation] = { enabled: "true", url: "http://example.com" }
      @tool.save!
      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/tabs",
                      controller: "tabs",
                      action: "index",
                      account_id: @account.to_param,
                      format: "json")
      external_tabs = json.select { |tab| tab["type"] == "external" }
      expect(external_tabs.length).to eq 1
      expect(external_tabs.first["url"]).to match(
        %r{/api/v1/accounts/#{@account.id}/external_tools/sessionless_launch\?.*launch_type=account_navigation}
      )
    end

    it "includes collaboration tab if configured" do
      course_with_teacher active_all: true
      @course.enable_feature! "new_collaborations"
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/tabs",
                      { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                      { include: ["external"] })
      expect(json.pluck("id")).to include "collaborations"
    end

    it "includes webconferences tab if configured" do
      course_with_teacher active_all: true
      allow_any_instance_of(ApplicationController).to receive(:feature_enabled?).with(:web_conferences).and_return(true)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/tabs",
                      { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                      { include: ["external"] })
      expect(json.pluck("id")).to include "conferences"
    end

    it "lists navigation tabs for a group" do
      group_with_user(active_all: true)
      json = api_call(:get,
                      "/api/v1/groups/#{@group.id}/tabs",
                      { controller: "tabs", action: "index", group_id: @group.to_param, format: "json" })
      expect(json).to eq [
        {
          "id" => "home",
          "html_url" => "/groups/#{@group.id}",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}",
          "type" => "internal",
          "label" => "Home",
          "position" => 1,
          "visibility" => "public"
        },
        {
          "id" => "announcements",
          "label" => "Announcements",
          "html_url" => "/groups/#{@group.id}/announcements",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/announcements",
          "position" => 2,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "pages",
          "html_url" => "/groups/#{@group.id}/wiki",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/wiki",
          "label" => "Pages",
          "position" => 3,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "people",
          "html_url" => "/groups/#{@group.id}/users",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/users",
          "label" => "People",
          "position" => 4,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "discussions",
          "html_url" => "/groups/#{@group.id}/discussion_topics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/discussion_topics",
          "label" => "Discussions",
          "position" => 5,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "files",
          "html_url" => "/groups/#{@group.id}/files",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@group)}/groups/#{@group.id}/files",
          "label" => "Files",
          "position" => 6,
          "visibility" => "public",
          "type" => "internal"
        }
      ]
    end

    it "lists navigation tabs for an account" do
      account_admin_user(active_all: true)
      @account = @user.account
      json = api_call(:get,
                      "/api/v1/accounts/#{@account.id}/tabs",
                      { controller: "tabs", action: "index", account_id: @account.to_param, format: "json" })
      expect(json).to eq [
        {
          "id" => "courses",
          "html_url" => "/accounts/#{@account.id}",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}",
          "type" => "internal",
          "label" => "Courses",
          "position" => 1,
          "visibility" => "public"
        },
        {
          "id" => "users",
          "label" => "People",
          "html_url" => "/accounts/#{@account.id}/users",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/users",
          "position" => 2,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "statistics",
          "html_url" => "/accounts/#{@account.id}/statistics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/statistics",
          "label" => "Statistics",
          "position" => 3,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "permissions",
          "html_url" => "/accounts/#{@account.id}/permissions",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/permissions",
          "label" => "Permissions",
          "position" => 4,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "outcomes",
          "html_url" => "/accounts/#{@account.id}/outcomes",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/outcomes",
          "label" => "Outcomes",
          "position" => 5,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "rubrics",
          "html_url" => "/accounts/#{@account.id}/rubrics",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/rubrics",
          "label" => "Rubrics",
          "position" => 6,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "grading_standards",
          "html_url" => "/accounts/#{@account.id}/grading_standards",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/grading_standards",
          "label" => "Grading",
          "position" => 7,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "question_banks",
          "html_url" => "/accounts/#{@account.id}/question_banks",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/question_banks",
          "label" => "Question Banks",
          "position" => 8,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "sub_accounts",
          "html_url" => "/accounts/#{@account.id}/sub_accounts",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/sub_accounts",
          "label" => "Sub-Accounts",
          "position" => 9,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "account_calendars",
          "html_url" => "/accounts/#{@account.id}/calendar_settings",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/calendar_settings",
          "label" => "Account Calendars",
          "position" => 10,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "terms",
          "html_url" => "/accounts/#{@account.id}/terms",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/terms",
          "label" => "Terms",
          "position" => 11,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "authentication",
          "html_url" => "/accounts/#{@account.id}/authentication_providers",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/authentication_providers",
          "label" => "Authentication",
          "position" => 12,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "sis_import",
          "html_url" => "/accounts/#{@account.id}/sis_import",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/sis_import",
          "label" => "SIS Import",
          "position" => 13,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "brand_configs",
          "html_url" => "/accounts/#{@account.id}/brand_configs",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/brand_configs",
          "label" => "Themes",
          "position" => 14,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "developer_keys",
          "html_url" => "/accounts/#{@account.id}/developer_keys",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/developer_keys",
          "label" => "Developer Keys",
          "position" => 15,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "admin_tools",
          "html_url" => "/accounts/#{@account.id}/admin_tools",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/admin_tools",
          "label" => "Admin Tools",
          "position" => 16,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "eportfolio_moderation",
          "html_url" => "/accounts/#{@account.id}/eportfolio_moderation",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/eportfolio_moderation",
          "label" => "ePortfolio Moderation",
          "position" => 17,
          "visibility" => "public",
          "type" => "internal"
        },
        {
          "id" => "settings",
          "html_url" => "/accounts/#{@account.id}/settings",
          "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@account)}/accounts/#{@account.id}/settings",
          "label" => "Settings",
          "position" => 18,
          "visibility" => "admins",
          "type" => "internal"
        }
      ]
    end

    it "doesn't include hidden tabs for student" do
      course_with_student(active_all: true)
      tab_ids = [
        Course::TAB_HOME,
        Course::TAB_SYLLABUS,
        Course::TAB_ASSIGNMENTS,
        Course::TAB_DISCUSSIONS,
        Course::TAB_GRADES,
        Course::TAB_PEOPLE,
        Course::TAB_ANNOUNCEMENTS,
        Course::TAB_PAGES,
        Course::TAB_FILES,
        Course::TAB_OUTCOMES,
        Course::TAB_QUIZZES,
        Course::TAB_MODULES,
        Course::TAB_OUTCOMES
      ]
      hidden_tabs = [Course::TAB_ASSIGNMENTS, Course::TAB_DISCUSSIONS, Course::TAB_GRADES]

      @course.tab_configuration = tab_ids.map do |n|
        hash = { "id" => n }
        hash["hidden"] = true if hidden_tabs.include?(n)
        hash
      end
      @course.save
      json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                    action: "index",
                                                                    course_id: @course.to_param,
                                                                    format: "json" })
      expect(json).to match_array([
                                    a_hash_including({ "id" => "home" }),
                                    a_hash_including({ "id" => "syllabus" }),
                                    a_hash_including({ "id" => "people" }),
                                  ])
    end

    describe "canvas for elementary" do
      before(:once) do
        course_with_teacher(active_all: true)
        @course.account.enable_as_k5_account!
      end

      it "lists a select subset of tabs if it is an elementary course and has the include[]=course_subject_tabs param" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/tabs",
                        { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" },
                        { include: ["course_subject_tabs"] })
        expect(json).to eq [
          {
            "id" => "home",
            "html_url" => "/courses/#{@course.id}",
            "full_url" => "http://localhost/courses/#{@course.id}",
            "position" => 1,
            "visibility" => "public",
            "label" => "Home",
            "type" => "internal"
          },
          {
            "id" => "schedule",
            "html_url" => "/courses/#{@course.id}",
            "full_url" => "http://localhost/courses/#{@course.id}",
            "position" => 2,
            "visibility" => "public",
            "label" => "Schedule",
            "type" => "internal"
          },
          {
            "id" => "modules",
            "html_url" => "/courses/#{@course.id}/modules",
            "full_url" => "http://localhost/courses/#{@course.id}/modules",
            "position" => 3,
            "visibility" => "public",
            "label" => "Modules",
            "type" => "internal"
          },
          {
            "id" => "grades",
            "html_url" => "/courses/#{@course.id}/grades",
            "full_url" => "http://localhost/courses/#{@course.id}/grades",
            "position" => 4,
            "visibility" => "public",
            "label" => "Grades",
            "type" => "internal"
          },
          {
            "id" => "groups",
            "html_url" => "/courses/#{@course.id}/groups",
            "full_url" => "http://localhost/courses/#{@course.id}/groups",
            "position" => 5,
            "visibility" => "public",
            "label" => "Groups",
            "type" => "internal"
          }
        ]
      end

      it "lists navigation tabs without home for an elementary course" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/tabs",
                        { controller: "tabs", action: "index", course_id: @course.to_param, format: "json" })
        expect(json).to eq [
          {
            "id" => "announcements",
            "html_url" => "/courses/#{@course.id}/announcements",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/announcements",
            "position" => 1,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Announcements",
            "type" => "internal"
          },
          {
            "id" => "assignments",
            "html_url" => "/courses/#{@course.id}/assignments",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments",
            "position" => 2,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Assignments",
            "type" => "internal"
          },
          {
            "id" => "discussions",
            "html_url" => "/courses/#{@course.id}/discussion_topics",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/discussion_topics",
            "position" => 3,
            "visibility" => "public",
            "label" => "Discussions",
            "type" => "internal"
          },
          {
            "id" => "grades",
            "html_url" => "/courses/#{@course.id}/grades",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/grades",
            "position" => 4,
            "visibility" => "public",
            "label" => "Grades",
            "type" => "internal"
          },
          {
            "id" => "people",
            "html_url" => "/courses/#{@course.id}/users",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/users",
            "position" => 5,
            "visibility" => "public",
            "label" => "People",
            "type" => "internal"
          },
          {
            "id" => "pages",
            "html_url" => "/courses/#{@course.id}/wiki",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/wiki",
            "position" => 6,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Pages",
            "type" => "internal"
          },
          {
            "id" => "files",
            "html_url" => "/courses/#{@course.id}/files",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/files",
            "position" => 7,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Files",
            "type" => "internal"
          },
          {
            "id" => "syllabus",
            "html_url" => "/courses/#{@course.id}/assignments/syllabus",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/assignments/syllabus",
            "position" => 8,
            "visibility" => "public",
            "label" => "Important Info",
            "type" => "internal"
          },
          {
            "id" => "outcomes",
            "html_url" => "/courses/#{@course.id}/outcomes",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/outcomes",
            "position" => 9,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Outcomes",
            "type" => "internal"
          },
          {
            "id" => "rubrics",
            "html_url" => "/courses/#{@course.id}/rubrics",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/rubrics",
            "position" => 10,
            "visibility" => "admins",
            "label" => "Rubrics",
            "type" => "internal"
          },
          {
            "id" => "quizzes",
            "html_url" => "/courses/#{@course.id}/quizzes",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/quizzes",
            "position" => 11,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Quizzes",
            "type" => "internal"
          },
          {
            "id" => "modules",
            "html_url" => "/courses/#{@course.id}/modules",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/modules",
            "position" => 12,
            "unused" => true,
            "visibility" => "admins",
            "label" => "Modules",
            "type" => "internal"
          },
          {
            "id" => "settings",
            "html_url" => "/courses/#{@course.id}/settings",
            "full_url" => "#{HostUrl.protocol}://#{HostUrl.context_host(@course)}/courses/#{@course.id}/settings",
            "position" => 13,
            "visibility" => "admins",
            "label" => "Settings",
            "type" => "internal"
          }
        ]
      end
    end

    describe "teacher in a course" do
      before :once do
        course_with_teacher(active_all: true)
        @tab_ids = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 18, 4, 10, 13]
        @tab_lookup = {}.with_indifferent_access
        @course.tabs_available(@teacher, api: true).each do |t|
          t = t.with_indifferent_access
          @tab_lookup[t["css_class"]] = t["id"]
        end
      end

      it "has the correct position" do
        tab_order = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 18, 4, 10, 13]
        @course.tab_configuration = tab_order.map { |n| { "id" => n } }
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                      action: "index",
                                                                      course_id: @course.to_param,
                                                                      format: "json" })
        json.each { |t| expect(t["position"]).to eq tab_order.find_index(@tab_lookup[t["id"]]) + 1 }
      end

      it "correctly labels navigation items as unused" do
        unused_tabs = %w[announcements assignments pages files outcomes quizzes modules]
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                      action: "index",
                                                                      course_id: @course.to_param,
                                                                      format: "json" })
        json.each do |t|
          if unused_tabs.include? t["id"]
            expect(t["unused"]).to be_truthy
          else
            expect(t["unused"]).to be_falsey
          end
        end
      end

      it "labels hidden items correctly" do
        hidden_tabs = [3, 8, 5]
        @course.tab_configuration = @tab_ids.map do |n|
          hash = { "id" => n }
          hash["hidden"] = true if hidden_tabs.include?(n)
          hash
        end
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                      action: "index",
                                                                      course_id: @course.to_param,
                                                                      format: "json" })
        json.each do |t|
          if hidden_tabs.include? @tab_lookup[t["id"]]
            expect(t["hidden"]).to be_truthy
          else
            expect(t["hidden"]).to be_falsey
          end
        end
      end

      it "correctly sets visibility" do
        hidden_tabs = [3, 8, 5]
        public_visibility = %w[home people syllabus]
        admins_visibility = %w[announcements assignments pages files outcomes rubrics quizzes modules settings discussions grades]
        @course.tab_configuration = @tab_ids.map do |n|
          hash = { "id" => n }
          hash["hidden"] = true if hidden_tabs.include?(n)
          hash
        end
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                      action: "index",
                                                                      course_id: @course.to_param,
                                                                      format: "json" })
        json.each do |t|
          case t["visibility"]
          when "public"
            expect(public_visibility).to include(t["id"])
          when "admins"
            expect(admins_visibility).to include(t["id"])
          else
            expect(true).to be_falsey
          end
        end
      end

      it "sorts tabs correctly" do
        course_with_teacher(active_all: true)
        tab_order = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
        @course.tab_configuration = tab_order.map { |n| { "id" => n } }
        @course.save
        json = api_call(:get, "/api/v1/courses/#{@course.id}/tabs", { controller: "tabs",
                                                                      action: "index",
                                                                      course_id: @course.to_param,
                                                                      format: "json" })
        json.each_with_index { |t, i| expect(t["position"]).to eq i + 1 }
      end
    end

    describe "user profile" do
      before { user_model }

      let(:tool) do
        Account.default.context_external_tools.new(
          {
            name: "Example",
            url: "http://www.example.com",
            consumer_key: "key",
            shared_secret: "secret",
          }
        )
      end

      it "returns 404 if current user is unauthorized" do
        target = user_model
        user_session(user_model)

        api_call(:get,
                 "/api/v1/users/#{target.id}/tabs",
                 { controller: "tabs", action: "index", user_id: target.to_param, format: "json" })

        expect(response).to have_http_status(:not_found)
      end

      it "includes external tools" do
        tool.settings[:user_navigation] = {
          enabled: "true",
          url: "http://www.example.com",
        }
        tool.save!

        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/tabs",
                        { controller: "tabs", action: "index", user_id: @user.to_param, format: "json" })

        expect(json).to include(include("type" => "external", "label" => "Example"))
      end

      it "handles external tools with windowTarget: _blank" do
        tool.settings[:user_navigation] = {
          enable: true,
          url: "http://www.example.com/foo",
          windowTarget: "_blank"
        }
        tool.save!

        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/tabs",
                        { controller: "tabs", action: "index", user_id: @user.to_param, format: "json" })

        tab = json.find { |j| j["type"] == "external" }
        expect(tab["html_url"]).to match(%r{^/users/[0-9]+/external_tools/[0-9]+\?display=borderless$})
        expect(tab["full_url"]).to match(%r{^http.*users/[0-9]+/external_tools/[0-9]+\?display=borderless$})
      end

      it "handles LTI 2 tools" do
        course_model

        expect(Lti::MessageHandler).to receive(:lti_apps_tabs).and_return([
                                                                            {
                                                                              id: "dontcare",
                                                                              label: "dontcare",
                                                                              css_class: "dontcare",
                                                                              href: :course_basic_lti_launch_request_path,
                                                                              visibility: nil,
                                                                              external: true,
                                                                              hidden: false,
                                                                              args: { message_handler_id: 123, resource_link_fragment: "nav", course_id: @course.id }
                                                                            }
                                                                          ])
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/tabs",
                        { controller: "tabs", action: "index", course_id: @course.id, format: "json" })
        expect(json.to_json).not_to include("internal_server_error")
        tab = json.find { |j| j["id"] == "dontcare" }
        expect(tab["html_url"]).to eql("/courses/#{@course.id}/lti/basic_lti_launch_request/123?resource_link_fragment=nav")
      end
    end
  end

  describe "update" do
    it "sets the people tab to hidden" do
      tab_id = "people"
      course_with_teacher(active_all: true)
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                              action: "update",
                                                                              course_id: @course.to_param,
                                                                              tab_id:,
                                                                              format: "json",
                                                                              hidden: true })
      expect(json["hidden"]).to be true
      expect(@course.reload.tab_configuration[json["position"] - 1]["hidden"]).to be true
    end

    it "only unhides one tab and not all when first updating" do
      course_with_teacher(active_all: true)
      tools = []

      3.times do |i|
        tool = @course.context_external_tools.new({
                                                    name: "Example #{i}",
                                                    url: "http://www.example.com",
                                                    consumer_key: "key",
                                                    shared_secret: "secret"
                                                  })
        tool.settings[:course_navigation] = {
          default: "disabled",
          url: "http://www.example.com",
        }
        tool.save!
        tools << tool.reload
      end

      tab_id = "context_external_tool_#{tools.first.id}"
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                              action: "update",
                                                                              course_id: @course.to_param,
                                                                              tab_id:,
                                                                              format: "json",
                                                                              hidden: false })
      expect(json["hidden"]).to be_nil
      expect(@course.reload.tab_configuration[json["position"] - 1]["hidden"]).to be_nil
      expect(@course.reload.tab_configuration.count { |t| t["hidden"] }).to eql(tools.count - 1)
    end

    it "allows updating new tabs not in the configuration yet" do
      course_with_teacher(active_all: true)
      tab_ids = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
      @course.tab_configuration = tab_ids.map { |id| { "id" => id } }
      @course.save!

      @tool = @course.context_external_tools.new({
                                                   name: "Example",
                                                   url: "http://www.example.com",
                                                   consumer_key: "key",
                                                   shared_secret: "secret",
                                                 })
      @tool.settings[:course_navigation] = {
        enabled: "true",
        url: "http://www.example.com",
      }
      @tool.save!
      tab_id = "context_external_tool_#{@tool.id}"

      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                              action: "update",
                                                                              course_id: @course.to_param,
                                                                              tab_id:,
                                                                              format: "json",
                                                                              hidden: true })
      expect(json["hidden"]).to be true
      expect(@course.reload.tab_configuration[json["position"] - 1]["hidden"]).to be true
    end

    it "changes the position of the people tab to 2" do
      tab_id = "people"
      course_with_teacher(active_all: true)
      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                              action: "update",
                                                                              course_id: @course.to_param,
                                                                              tab_id:,
                                                                              format: "json",
                                                                              position: 2 })
      expect(json["position"]).to eq 2
      expect(@course.reload.tab_configuration[1]["id"]).to eq @course.class::TAB_PEOPLE
    end

    it "won't allow you to hide the home tab" do
      tab_id = "home"
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                                    action: "update",
                                                                                    course_id: @course.to_param,
                                                                                    tab_id:,
                                                                                    format: "json",
                                                                                    hidden: true })
      expect(result).to eq 400
    end

    it "won't allow you to move a tab to the first position" do
      tab_id = "people"
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                                    action: "update",
                                                                                    course_id: @course.to_param,
                                                                                    tab_id:,
                                                                                    format: "json",
                                                                                    position: 1 })
      expect(result).to eq 400
    end

    it "won't allow you to move a tab to an invalid position" do
      tab_id = "people"
      course_with_teacher(active_all: true)
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                                    action: "update",
                                                                                    course_id: @course.to_param,
                                                                                    tab_id:,
                                                                                    format: "json",
                                                                                    position: 400 })
      expect(result).to eq 400
    end

    it "doesn't allow a student to modify a tab" do
      course_with_student(active_all: true)
      tab_id = "people"
      result = raw_api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                                    action: "update",
                                                                                    course_id: @course.to_param,
                                                                                    tab_id:,
                                                                                    format: "json",
                                                                                    position: 4 })
      expect(result).to eq 401
    end

    it "allows updating tabs to a new LTI position when the penultimate tab is hidden" do
      course_with_teacher(active_all: true)
      tab_ids = [0, 1, 3, 8, 5, 6, 14, 2, 11, 15, 4, 10, 13]
      @course.tab_configuration = tab_ids.each_with_index.map do |id, i|
        { "id" => id, "hidden" => (i == tab_ids.count - 2) }
      end
      @course.save!

      @tool = @course.context_external_tools.new({
                                                   name: "Example",
                                                   url: "http://www.example.com",
                                                   consumer_key: "key",
                                                   shared_secret: "secret",
                                                   course_navigation: {
                                                     enabled: "true",
                                                     url: "http://www.example.com",
                                                   }
                                                 })
      @tool.save!
      tab_id = "rubrics"
      position = 14

      json = api_call(:put, "/api/v1/courses/#{@course.id}/tabs/#{tab_id}", { controller: "tabs",
                                                                              action: "update",
                                                                              position:,
                                                                              course_id: @course.to_param,
                                                                              tab_id:,
                                                                              format: "json" })
      expect(json["position"]).to eq position
    end
  end
end
