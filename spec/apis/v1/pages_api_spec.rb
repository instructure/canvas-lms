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

require_relative "../api_spec_helper"
require_relative "../locked_examples"

describe "Pages API", type: :request do
  include Api::V1::User
  include AvatarHelper

  context "locked api item" do
    let(:item_type) { "page" }

    let(:locked_item) do
      wiki = @course.wiki
      wiki.set_front_page_url!("front-page")
      front_page = wiki.front_page
      front_page.workflow_state = "active"
      front_page.save!
      front_page
    end

    def api_get_json
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/pages/#{locked_item.url}",
        { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: locked_item.url }
      )
    end

    include_examples "a locked api item"
  end

  before :once do
    course_factory
    @course.offer!
    @wiki = @course.wiki
    @wiki.set_front_page_url!("front-page")
    @front_page = @wiki.front_page
    @front_page.workflow_state = "active"
    @front_page.save!
    @front_page.set_as_front_page!
    @hidden_page = @course.wiki_pages.create!(title: "Hidden Page", body: "Body of hidden page")
    @hidden_page.unpublish!
  end

  context "versions" do
    before :once do
      @page = @course.wiki_pages.create!(title: "Test Page", body: "Test content")
    end

    example "creates initial version of the page" do
      expect(@page.versions.count).to eq 1
      version = @page.current_version.model
      expect(version.title).to eq "Test Page"
      expect(version.body).to eq "Test content"
    end

    example "creates a version when the title changes" do
      @page.title = "New Title"
      @page.save!
      expect(@page.versions.count).to eq 2
      version = @page.current_version.model
      expect(version.title).to eq "New Title"
      expect(version.body).to eq "Test content"
    end

    example "creates a verison when the body changes" do
      @page.body = "New content"
      @page.save!
      expect(@page.versions.count).to eq 2
      version = @page.current_version.model
      expect(version.title).to eq "Test Page"
      expect(version.body).to eq "New content"
    end

    example "does not create a version when workflow_state changes" do
      @page.workflow_state = "active"
      @page.save!
      expect(@page.versions.count).to eq 1
    end

    example "does not create a version when editing_roles changes" do
      @page.editing_roles = "teachers,students,public"
      @page.save!
      expect(@page.versions.count).to eq 1
    end

    example "does not create a version when notify_of_update changes" do
      @page.notify_of_update = true
      @page.save!
      expect(@page.versions.count).to eq 1
    end

    example "does not create a version when just the user_id changes" do
      user1 = user_factory(active_all: true)
      @page.user_id = user1.id
      @page.title = "New Title"
      @page.save!
      expect(@page.versions.count).to eq 2
      current_version = @page.current_version.model
      expect(current_version.user_id).to eq user1.id

      user2 = user_factory(active_all: true)
      @page.user_id = user2.id
      @page.save!
      expect(@page.versions.count).to eq 2
    end
  end

  context "as a teacher" do
    before :once do
      course_with_teacher(course: @course, active_all: true)
    end

    describe "index" do
      it "lists pages, including hidden ones", priority: "1" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param)
        expect(json.map { |entry| entry.slice(*%w[hide_from_students url created_at updated_at title front_page]) }).to eq(
          [{ "hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.revised_at.as_json, "title" => @front_page.title, "front_page" => true },
           { "hide_from_students" => true, "url" => @hidden_page.url, "created_at" => @hidden_page.created_at.as_json, "updated_at" => @hidden_page.revised_at.as_json, "title" => @hidden_page.title, "front_page" => false }]
        )
      end

      it "paginates" do
        2.times { |i| @course.wiki_pages.create!(title: "New Page #{i}") }
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?per_page=2",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        per_page: "2")
        expect(json.size).to eq 2
        urls = json.pluck("url")

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?per_page=2&page=2",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        per_page: "2",
                        page: "2")
        expect(json.size).to eq 2
        urls += json.pluck("url")

        expect(urls).to eq @wiki.wiki_pages.sort_by(&:id).collect(&:url)
      end

      it "searches for pages by title" do
        new_pages = []
        3.times { |i| new_pages << @course.wiki_pages.create!(title: "New Page #{i}") }

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?search_term=new",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        search_term: "new")
        expect(json.size).to eq 3
        expect(json.pluck("url")).to eq new_pages.sort_by(&:id).collect(&:url)

        # Should also paginate
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?search_term=New&per_page=2",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        search_term: "New",
                        per_page: "2")
        expect(json.size).to eq 2
        urls = json.pluck("url")

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?search_term=New&per_page=2&page=2",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.to_param,
                        search_term: "New",
                        per_page: "2",
                        page: "2")
        expect(json.size).to eq 1
        urls += json.pluck("url")

        expect(urls).to eq new_pages.sort_by(&:id).collect(&:url)
      end

      it "returns an error if the search term is fewer than 2 characters" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?search_term=a",
                        { controller: "wiki_pages_api", action: "index", format: "json", course_id: @course.to_param, search_term: "a" },
                        {},
                        {},
                        { expected_status: 400 })
        error = json["errors"].first
        verify_json_error(error, "search_term", "invalid", "2 or more characters is required")
      end

      describe "page body" do
        it "is not included by default" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param)
          json.each do |page|
            expect(page.key?("body")).to be false
          end
        end

        it "is included when include[]=body is specified" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages?include[]=body",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          include: ["body"])
          json.each do |page|
            expect(page.key?("body")).to be true
          end
          expect(json.find { |page| page["title"] == "Hidden Page" }["body"]).to eq "Body of hidden page"
        end
      end

      describe "sorting" do
        it "sorts by title (case-insensitive)" do
          @course.wiki_pages.create! title: "gIntermediate Page"
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages?sort=title",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          sort: "title")
          expect(json.pluck("title")).to eq ["Front Page", "gIntermediate Page", "Hidden Page"]

          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages?sort=title&order=desc",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          sort: "title",
                          order: "desc")
          expect(json.pluck("title")).to eq ["Hidden Page", "gIntermediate Page", "Front Page"]
        end

        it "sorts by created_at" do
          @hidden_page.update_attribute(:created_at, 1.hour.ago)
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages?sort=created_at&order=asc",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          sort: "created_at",
                          order: "asc")
          expect(json.pluck("url")).to eq [@hidden_page.url, @front_page.url]
        end

        it "sorts by updated_at" do
          Timecop.freeze(1.hour.ago) { @hidden_page.touch }
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages?sort=updated_at&order=desc",
                          controller: "wiki_pages_api",
                          action: "index",
                          format: "json",
                          course_id: @course.to_param,
                          sort: "updated_at",
                          order: "desc")
          expect(json.pluck("url")).to eq [@front_page.url, @hidden_page.url]
        end

        context "planner feature enabled" do
          it "creates a page with a todo_date" do
            todo_date = Time.zone.local(2008, 9, 1, 12, 0, 0)
            json = api_call(:post,
                            "/api/v1/courses/#{@course.id}/pages",
                            { controller: "wiki_pages_api",
                              action: "create",
                              format: "json",
                              course_id: @course.to_param },
                            { wiki_page: { title: "New Wiki Page!",
                                           student_planner_checkbox: "1",
                                           body: "hello new page",
                                           student_todo_at: todo_date } })
            page = @course.wiki_pages.where(url: json["url"]).first!
            expect(page.todo_date).to eq todo_date
          end

          it "creates a new front page with a todo date" do
            # we need a new course that does not already have a front page, in an account with planner enabled
            course_with_teacher(active_all: true, account: @course.account)
            todo_date = 1.week.from_now.beginning_of_day
            api_call(:put,
                     "/api/v1/courses/#{@course.id}/front_page",
                     { controller: "wiki_pages_api",
                       action: "update_front_page",
                       format: "json",
                       course_id: @course.to_param },
                     { wiki_page: { title: "New Wiki Page!",
                                    student_planner_checkbox: "1",
                                    body: "hello new page",
                                    student_todo_at: todo_date } })
            page = @course.wiki.front_page
            expect(page.todo_date).to eq todo_date
          end

          it "updates a page with a todo_date" do
            todo_date = Time.zone.local(2008, 9, 1, 12, 0, 0)
            todo_date_2 = Time.zone.local(2008, 9, 2, 12, 0, 0)
            page = @course.wiki_pages.create!(title: "hrup", todo_date:)

            api_call(:put,
                     "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                     { controller: "wiki_pages_api",
                       action: "update",
                       format: "json",
                       course_id: @course.to_param,
                       url_or_id: page.url },
                     { wiki_page: { student_todo_at: todo_date_2, student_planner_checkbox: "1" } })

            page.reload
            expect(page.todo_date).to eq todo_date_2
          end

          it "unsets page todo_date" do
            page = @course.wiki_pages.create!(title: "hrup", todo_date: Time.zone.now)
            api_call(:put,
                     "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                     { controller: "wiki_pages_api",
                       action: "update",
                       format: "json",
                       course_id: @course.to_param,
                       url_or_id: page.url },
                     { wiki_page: { student_planner_checkbox: false } })
            page.reload
            expect(page.todo_date).to be_nil
          end

          it "unsets page todo_date only if explicitly asked for" do
            now = Time.zone.now
            page = @course.wiki_pages.create!(title: "hrup", todo_date: now)
            api_call(:put,
                     "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                     { controller: "wiki_pages_api",
                       action: "update",
                       format: "json",
                       course_id: @course.to_param,
                       url_or_id: page.url },
                     { wiki_page: {} })
            page.reload
            expect(page.todo_date).to eq now
          end
        end
      end
    end

    describe "show" do
      before :once do
        @teacher.short_name = "the teacher"
        @teacher.save!
        @hidden_page.user_id = @teacher.id
        @hidden_page.save!
      end

      it "retrieves page content and attributes", priority: "1" do
        @hidden_page.publish
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                        controller: "wiki_pages_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: @hidden_page.url)
        expected = { "hide_from_students" => false,
                     "editing_roles" => "teachers",
                     "last_edited_by" => user_display_json(@teacher, @course).stringify_keys!,
                     "url" => @hidden_page.url,
                     "html_url" => "http://www.example.com/courses/#{@course.id}/#{@course.wiki.path}/#{@hidden_page.url}",
                     "created_at" => @hidden_page.created_at.as_json,
                     "updated_at" => @hidden_page.revised_at.as_json,
                     "title" => @hidden_page.title,
                     "body" => @hidden_page.body,
                     "published" => true,
                     "front_page" => false,
                     "locked_for_user" => false,
                     "page_id" => @hidden_page.id,
                     "todo_date" => nil,
                     "publish_at" => nil }
        expect(json).to eq expected
      end

      it "retrieves front_page", priority: "1" do
        page = @course.wiki_pages.create!(title: "hrup", body: "blooop")
        page.set_as_front_page!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/front_page",
                        controller: "wiki_pages_api",
                        action: "show_front_page",
                        format: "json",
                        course_id: @course.id.to_s)

        expected = { "hide_from_students" => false,
                     "editing_roles" => "teachers",
                     "url" => page.url,
                     "html_url" => "http://www.example.com/courses/#{@course.id}/#{@course.wiki.path}/#{page.url}",
                     "created_at" => page.created_at.as_json,
                     "updated_at" => page.revised_at.as_json,
                     "title" => page.title,
                     "body" => page.body,
                     "published" => true,
                     "front_page" => true,
                     "locked_for_user" => false,
                     "page_id" => page.id,
                     "todo_date" => nil,
                     "publish_at" => nil }
        expect(json).to eq expected
      end

      it "gives a meaningful error if there is no front page" do
        @front_page.workflow_state = "deleted"
        @front_page.save!
        wiki = @front_page.wiki
        wiki.unset_front_page!

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "show_front_page", format: "json", course_id: @course.id.to_s },
                        {},
                        {},
                        { expected_status: 404 })

        expect(json["message"]).to eq "No front page has been set"
      end
    end

    describe "revisions" do
      before :once do
        @timestamps = %w[2013-01-01 2013-01-02 2013-01-03].map { |d| Time.zone.parse(d) }
        course_with_ta course: @course, active_all: true
        Timecop.freeze(@timestamps[0]) do      # rev 1
          @vpage = @course.wiki_pages.build title: "version test page"
          @vpage.workflow_state = "unpublished"
          @vpage.body = "draft"
          @vpage.save!
        end

        Timecop.freeze(@timestamps[1]) do      # rev 2
          @vpage.workflow_state = "active"
          @vpage.body = "published by teacher"
          @vpage.user = @teacher
          @vpage.save!
        end

        Timecop.freeze(@timestamps[2]) do      # rev 3
          @vpage.body = "revised by ta"
          @vpage.user = @ta
          @vpage.save!
        end
        @user = @teacher
      end

      it "lists revisions of a page" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                        controller: "wiki_pages_api",
                        action: "revisions",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @vpage.url)
        expect(json).to eq [
          {
            "revision_id" => 3,
            "latest" => true,
            "updated_at" => @timestamps[2].as_json,
            "edited_by" => user_display_json(@ta, @course).stringify_keys!,
          },
          {
            "revision_id" => 2,
            "latest" => false,
            "updated_at" => @timestamps[1].as_json,
            "edited_by" => user_display_json(@teacher, @course).stringify_keys!,
          },
          {
            "revision_id" => 1,
            "latest" => false,
            "updated_at" => @timestamps[0].as_json,
          }
        ]
      end

      it "summarizes the latest revision" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest?summary=true",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @vpage.url,
                        summary: "true")
        expect(json).to eq({
                             "revision_id" => 3,
                             "latest" => true,
                             "updated_at" => @timestamps[2].as_json,
                             "edited_by" => user_display_json(@ta, @course).stringify_keys!,
                           })
      end

      it "paginates the revision list" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions?per_page=2",
                        controller: "wiki_pages_api",
                        action: "revisions",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @vpage.url,
                        per_page: "2")
        expect(json.size).to eq 2
        json += api_call(:get,
                         "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions?per_page=2&page=2",
                         controller: "wiki_pages_api",
                         action: "revisions",
                         format: "json",
                         course_id: @course.to_param,
                         url_or_id: @vpage.url,
                         per_page: "2",
                         page: "2")
        expect(json.pluck("revision_id")).to eq [3, 2, 1]
      end

      it "retrieves an old revision" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/1",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: @vpage.url,
                        revision_id: "1")
        expect(json).to eq({
                             "body" => "draft",
                             "title" => "version test page",
                             "url" => @vpage.url,
                             "updated_at" => @timestamps[0].as_json,
                             "revision_id" => 1,
                             "latest" => false
                           })
      end

      it "retrieves the latest revision" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: @vpage.url)
        expect(json).to eq({
                             "body" => "revised by ta",
                             "title" => "version test page",
                             "url" => @vpage.url,
                             "updated_at" => @timestamps[2].as_json,
                             "revision_id" => 3,
                             "latest" => true,
                             "edited_by" => user_display_json(@ta, @course).stringify_keys!
                           })
      end

      it "reverts to a prior revision" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                        controller: "wiki_pages_api",
                        action: "revert",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @vpage.url,
                        revision_id: "2")
        expect(json["body"]).to eq "published by teacher"
        expect(json["revision_id"]).to eq 4
        expect(@vpage.reload.body).to eq "published by teacher"
      end

      it "reverts page content only" do
        @vpage.workflow_state = "unpublished"
        @vpage.title = "booga!"
        @vpage.body = "booga booga!"
        @vpage.editing_roles = "teachers,students,public"
        @vpage.save! # rev 4
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                 controller: "wiki_pages_api",
                 action: "revert",
                 format: "json",
                 course_id: @course.to_param,
                 url_or_id: @vpage.url,
                 revision_id: "3")
        @vpage.reload

        expect(@vpage.editing_roles).to eq "teachers,students,public"
        expect(@vpage.title).to eq "version test page"  # <- reverted
        expect(@vpage.body).to eq "revised by ta"       # <- reverted
        expect(@vpage.user_id).to eq @teacher.id        # the user who performed the revert (not the original author)
      end

      it "show should 404 when given a bad revision number" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/99",
                 { controller: "wiki_pages_api",
                   action: "show_revision",
                   format: "json",
                   course_id: @course.id.to_s,
                   url_or_id: @vpage.url,
                   revision_id: "99" },
                 {},
                 {},
                 { expected_status: 404 })
      end

      it "revert should 404 when given a bad revision number" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/99",
                 { controller: "wiki_pages_api",
                   action: "revert",
                   format: "json",
                   course_id: @course.id.to_s,
                   url_or_id: @vpage.url,
                   revision_id: "99" },
                 {},
                 {},
                 { expected_status: 404 })
      end
    end

    describe "create" do
      it "requires a title" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages",
                 { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                 {},
                 {},
                 { expected_status: 400 })
      end

      it "creates a new page", priority: "1" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Page!", body: "hello new page" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.title).to eq "New Wiki Page!"
        expect(page.url).to eq "new-wiki-page"
        expect(page.body).to eq "hello new page"
        expect(page.user_id).to eq @teacher.id
      end

      it "creates a front page using PUT", priority: "1" do
        front_page_url = "new-wiki-front-page"
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Front Page!", body: "hello front page" } })
        expect(json["url"]).to eq front_page_url
        page = @course.wiki_pages.where(url: front_page_url).first!
        expect(page.is_front_page?).to be_truthy
        expect(page.title).to eq "New Wiki Front Page!"
        expect(page.body).to eq "hello front page"
      end

      it "errors when creating a front page using PUT with no value in title", priority: "3" do
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "", body: "hello front page" } },
                        {},
                        { expected_status: 400 })
        error = json["errors"].first
        # As error is represented as array of arrays
        expect(error[0]).to eq("title")
        expect(error[1][0]["message"]).to eq("Title can't be blank")
      end

      it "creates front page with published set to true using PUT", priority: "3" do
        front_page_url = "new-wiki-front-page"
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Front Page!", published: true } })
        expect(json["url"]).to eq front_page_url
        page = @course.wiki_pages.where(url: front_page_url).first!
        expect(page.published?).to be(true)
      end

      it "errors when creating front page with published set to false using PUT", priority: "3" do
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Front Page!", published: false } },
                        {},
                        { expected_status: 400 })
        error = json["errors"].first
        # As error is represented as array of arrays
        expect(error[0]).to eq("published")
        expect(error[1][0]["message"]).to eq("The front page cannot be unpublished")
      end

      it "does not error when creating a new page with the same name as the front page" do
        page_title = "The Black Keys Fandom 101"
        original_page = @course.wiki_pages.create!(title: page_title, body: "whatever")
        original_page.publish
        original_page.set_as_front_page!

        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: page_title, body: } },
                        {},
                        { expected_status: 200 })
        new_page = @course.wiki_pages.where(url: json["url"]).first!

        expect(@course.wiki.front_page).to eq original_page
        expect(new_page.title).to eq page_title
        expect(new_page.url).to eq "#{original_page.url}-2"
      end

      it "processes body with process_incoming_html_content" do
        allow_any_instance_of(WikiPagesApiController).to receive(:process_incoming_html_content).and_return("processed content")

        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Page", body: "content to process" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.title).to eq "New Wiki Page"
        expect(page.url).to eq "new-wiki-page"
        expect(page.body).to eq "processed content"
      end

      it "does not point group file links to the course" do
        group_model(context: @course)
        body = "<a href='/groups/#{@group.id}/files'>linky</a>"

        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Page", body: } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.title).to eq "New Wiki Page"
        expect(page.url).to eq "new-wiki-page"
        expect(page.body).to include("/groups/#{@group.id}/files")
      end

      it "sets as front page", priority: "1" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Page!", body: "hello new page", published: true, front_page: true } })

        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.is_front_page?).to be_truthy

        wiki = @course.wiki
        wiki.reload
        expect(wiki.get_front_page_url).to eq page.url

        expect(json["front_page"]).to be true
      end

      it "creates a new page in published state", priority: "1" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { published: true, title: "New Wiki Page!", body: "hello new page" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page).to be_active
        expect(json["published"]).to be_truthy
      end

      it "creates a new page in unpublished state (draft state)" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { published: false, title: "New Wiki Page!", body: "hello new page" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page).to be_unpublished
        expect(json["published"]).to be_falsey
      end

      it "creates a published front page, even when published is blank", priority: "1" do
        front_page_url = "my-front-page"
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/front_page",
                        { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                        { wiki_page: { published: "", title: "My Front Page" } })
        expect(json["url"]).to eq front_page_url
        expect(json["published"]).to be_truthy

        expect(@course.wiki.get_front_page_url).to eq front_page_url
        page = @course.wiki_pages.where(url: front_page_url).first!
        expect(page).to be_published
      end

      it "creates a delayed-publish page" do
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                        { wiki_page: { published: false, publish_at: 1.day.from_now.beginning_of_day.iso8601, title: "New Wiki Page!", body: "hello new page" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page).to be_unpublished
        expect(json["published"]).to be false
        expect(json["publish_at"]).to eq page.publish_at.iso8601
      end

      it "allows teachers to set editing_roles" do
        @course.default_wiki_editing_roles = "teachers"
        @course.save
        json = api_call(:post,
                        "/api/v1/courses/#{@course.id}/pages",
                        { controller: "wiki_pages_api",
                          action: "create",
                          format: "json",
                          course_id: @course.to_param },
                        { wiki_page: { title: "New Wiki Page!",
                                       body: "hello new page",
                                       editing_roles: "teachers,students,public" } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.editing_roles.split(",")).to match_array(%w[teachers students public])
      end

      it "does not allow students to set editing_roles" do
        course_with_student(course: @course, active_all: true)
        @course.default_wiki_editing_roles = "teachers,students"
        @course.save
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages",
                 { controller: "wiki_pages_api",
                   action: "create",
                   format: "json",
                   course_id: @course.to_param },
                 { wiki_page: { title: "New Wiki Page!",
                                body: "hello new page",
                                editing_roles: "teachers,students,public" } },
                 {},
                 { expected_status: 401 })
      end

      describe "should create a linked assignment" do
        let(:page) do
          json = api_call(:post,
                          "/api/v1/courses/#{@course.id}/pages",
                          { controller: "wiki_pages_api",
                            action: "create",
                            format: "json",
                            course_id: @course.to_param },
                          { wiki_page: { title: "Assignable Page",
                                         assignment: { set_assignment: true, only_visible_to_overrides: true } } })
          @course.wiki_pages.where(url: json["url"]).first!
        end

        it "unless setting is disabled" do
          expect(page.assignment).to be_nil
        end

        it "if setting is enabled" do
          @course.conditional_release = true
          @course.save!
          expect(page.assignment).not_to be_nil
          expect(page.assignment.title).to eq "Assignable Page"
          expect(page.assignment.submission_types).to eq "wiki_page"
          expect(page.assignment.only_visible_to_overrides).to be true
        end
      end
    end

    describe "update" do
      it "updates page content and attributes", priority: "1" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { title: "No Longer Hidden Page",
                                body: "Information wants to be free" } })
        @hidden_page.reload
        expect(@hidden_page.title).to eq "No Longer Hidden Page"
        expect(@hidden_page.body).to eq "Information wants to be free"
        expect(@hidden_page.user_id).to eq @teacher.id
      end

      it "updates front_page" do
        page = @course.wiki_pages.create!(title: "hrup", body: "blooop")
        page.publish
        page.set_as_front_page!

        new_title = "blah blah blah"

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/front_page",
                 { controller: "wiki_pages_api", action: "update_front_page", format: "json", course_id: @course.to_param },
                 { wiki_page: { title: new_title } })

        page.reload
        expect(page.title).to eq new_title
      end

      it "does not crash updating front page if the wiki_page param is not available with student planner enabled" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/front_page",
                 { controller: "wiki_pages_api",
                   action: "update_front_page",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 {},
                 {},
                 { expected_status: 200 })
      end

      it "sets as front page", priority: "3" do
        wiki = @course.wiki
        expect(wiki.unset_front_page!).to be true

        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                        { controller: "wiki_pages_api",
                          action: "update",
                          format: "json",
                          course_id: @course.to_param,
                          url_or_id: @hidden_page.url },
                        { wiki_page: { title: "No Longer Hidden Page",
                                       body: "Information wants to be free",
                                       front_page: true,
                                       published: true } })
        no_longer_hidden_page = @hidden_page
        no_longer_hidden_page.reload
        expect(no_longer_hidden_page.is_front_page?).to be_truthy

        wiki.reload
        expect(wiki.front_page).to eq no_longer_hidden_page

        expect(json["front_page"]).to be true
      end

      it "un-sets as front page" do
        wiki = @course.wiki
        wiki.reload
        expect(wiki.has_front_page?).to be_truthy

        front_page = wiki.front_page

        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/pages/#{front_page.url}",
                        { controller: "wiki_pages_api",
                          action: "update",
                          format: "json",
                          course_id: @course.to_param,
                          url_or_id: front_page.url },
                        { wiki_page: { title: "No Longer Front Page", body: "Information wants to be free", front_page: false } })

        front_page.reload
        expect(front_page.is_front_page?).to be_falsey

        wiki.reload
        expect(wiki.has_front_page?).to be_falsey

        expect(json["front_page"]).to be false
      end

      it "does not change the front page unless set differently" do
        # make sure we don't catch the default 'front-page'
        @front_page.title = "Different Front Page"
        @front_page.save!

        wiki = @course.wiki.reload
        wiki.set_front_page_url!(@front_page.url)

        # create and update another page
        other_page = @course.wiki_pages.create!(title: "Other Page", body: "Body of other page")
        other_page.workflow_state = "active"
        other_page.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{other_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: other_page.url },
                 { wiki_page: { title: "Another Page", body: "Another page body", front_page: false } })

        # the front page url should remain unchanged
        expect(wiki.reload.get_front_page_url).to eq @front_page.url
      end

      it "updates wiki front page url if page url is updated" do
        page = @course.wiki_pages.create!(title: "hrup")
        page.set_as_front_page!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: page.url },
                 { wiki_page: { url: "noooo" } })

        page.reload
        expect(page.is_front_page?).to be_truthy

        wiki = @course.wiki
        wiki.reload
        expect(wiki.get_front_page_url).to eq page.url
      end

      it "does not set hidden page as front page" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { title: "Actually Still Hidden Page",
                                body: "Information wants to be free",
                                front_page: true } },
                 {},
                 { expected_status: 400 })

        @hidden_page.reload
        expect(@hidden_page.is_front_page?).not_to be_truthy
      end

      context "hide_from_students" do
        before :once do
          @test_page = @course.wiki_pages.build(title: "Test Page")
          @test_page.workflow_state = "active"
          @test_page.save!
        end

        context "with draft state" do
          it "accepts published" do
            json = api_call(:put,
                            "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                            { controller: "wiki_pages_api", action: "update", format: "json", course_id: @course.to_param, url_or_id: @test_page.url },
                            { wiki_page: { "published" => "false" } })
            expect(json["published"]).to be_falsey
            expect(json["hide_from_students"]).to be_truthy

            @test_page.reload
            expect(@test_page).to be_unpublished
          end

          it "ignores hide_from_students" do
            json = api_call(:put,
                            "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                            { controller: "wiki_pages_api", action: "update", format: "json", course_id: @course.to_param, url_or_id: @test_page.url },
                            { wiki_page: { "hide_from_students" => "true" } })
            expect(json["published"]).to be_truthy
            expect(json["hide_from_students"]).to be_falsey

            @test_page.reload
            expect(@test_page).to be_active
          end
        end
      end

      context "with unpublished page" do
        before :once do
          @unpublished_page = @course.wiki_pages.build(title: "Unpublished Page", body: "Body of unpublished page")
          @unpublished_page.workflow_state = "unpublished"
          @unpublished_page.save!

          @unpublished_page.reload
        end

        it "publishes a page with published=true" do
          json = api_call(:put,
                          "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                          { controller: "wiki_pages_api", action: "update", format: "json", course_id: @course.to_param, url_or_id: @unpublished_page.url },
                          { wiki_page: { "published" => "true" } })
          expect(json["published"]).to be_truthy
          expect(@unpublished_page.reload).to be_active
        end

        it "does not publish a page otherwise" do
          json = api_call(:put,
                          "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                          { controller: "wiki_pages_api", action: "update", format: "json", course_id: @course.to_param, url_or_id: @unpublished_page.url })
          expect(json["published"]).to be_falsey
          expect(@unpublished_page.reload).to be_unpublished
        end

        it "schedules future publication" do
          json = api_call(:put,
                          "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                          { controller: "wiki_pages_api", action: "update", format: "json", course_id: @course.to_param, url_or_id: @unpublished_page.url },
                          { wiki_page: { "publish_at" => 1.day.from_now.beginning_of_day.iso8601 } })
          expect(@unpublished_page.reload).to be_unpublished
          expect(json["published"]).to be false
          expect(json["publish_at"]).to eq @unpublished_page.publish_at.iso8601
        end
      end

      it "unpublishes a page" do
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[published]=false",
                        controller: "wiki_pages_api",
                        action: "update",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @hidden_page.url,
                        wiki_page: { "published" => "false" })
        expect(json["published"]).to be_falsey
        expect(@hidden_page.reload).to be_unpublished
      end

      it "sanitizes page content" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { body: "<p>lolcats</p><script>alert('what')</script>" } })
        @hidden_page.reload
        expect(@hidden_page.body).to eq "<p>lolcats</p>"
      end

      it "processes body with process_incoming_html_content" do
        allow_any_instance_of(WikiPagesApiController).to receive(:process_incoming_html_content).and_return("processed content")

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { body: "content to process" } })
        @hidden_page.reload
        expect(@hidden_page.body).to eq "processed content"
      end

      it "does not allow invalid editing_roles" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { editing_roles: "teachers, chimpanzees, students" } },
                 {},
                 { expected_status: 400 })
      end

      it "creates a page if the page doesn't exist", priority: "1" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/nonexistent-url",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: "nonexistent-url" },
                 { wiki_page: { body: "Nonexistent page content" } })
        page = @wiki.wiki_pages.where(url: "nonexistent-url").first!
        expect(page).not_to be_nil
        expect(page.body).to eq "Nonexistent page content"
      end

      describe "notify_of_update" do
        before :once do
          @notify_page = @hidden_page
          @notify_page.publish!

          @front_page.update_attribute(:created_at, 1.hour.ago)
          @notify_page.update_attribute(:created_at, 1.hour.ago)
          @notification = Notification.create!(name: "Updated Wiki Page", category: "TestImmediately")
          @teacher.communication_channels.create(path: "teacher@instructure.com").confirm!
        end

        it "notifies iff the notify_of_update flag is set" do
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}?wiki_page[body]=updated+front+page",
                   controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @front_page.url,
                   wiki_page: { "body" => "updated front page" })
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[body]=updated+hidden+page&wiki_page[notify_of_update]=true",
                   controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @notify_page.url,
                   wiki_page: { "body" => "updated hidden page", "notify_of_update" => "true" })
          expect(@teacher.messages.map(&:context_id)).to eq [@notify_page.id]
        end
      end

      context "feature enabled" do
        before do
          @course.conditional_release = true
          @course.save!
        end

        it "updates a linked assignment" do
          wiki_page_assignment_model(wiki_page: @hidden_page)
          json = api_call(:put,
                          "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                          { controller: "wiki_pages_api",
                            action: "update",
                            format: "json",
                            course_id: @course.to_param,
                            url_or_id: @hidden_page.url },
                          { wiki_page: { title: "Changin' the Title",
                                         assignment: { only_visible_to_overrides: true } } })
          page = @course.wiki_pages.where(url: json["url"]).first!
          expect(page.assignment.title).to eq "Changin' the Title"
          expect(page.assignment.only_visible_to_overrides).to be true
        end

        it "destroys and restore a linked assignment" do
          wiki_page_assignment_model(wiki_page: @hidden_page)
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                   { controller: "wiki_pages_api",
                     action: "update",
                     format: "json",
                     course_id: @course.to_param,
                     url_or_id: @hidden_page.url },
                   { wiki_page: { assignment: { set_assignment: false } } })
          @hidden_page.reload
          expect(@hidden_page.assignment).to be_nil
          expect(@hidden_page.old_assignment_id).to eq @assignment.id
          expect(@assignment.reload).to be_deleted
          expect(@assignment.wiki_page).to be_nil

          # Restore it
          api_call(:put,
                   "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                   { controller: "wiki_pages_api",
                     action: "update",
                     format: "json",
                     course_id: @course.to_param,
                     url_or_id: @hidden_page.url },
                   { wiki_page: { assignment: { set_assignment: true } } })
          @hidden_page.reload
          expect(@hidden_page.assignment).not_to be_nil
          expect(@hidden_page.old_assignment_id).to eq @assignment.id
          expect(@assignment.reload).not_to be_deleted
          expect(@assignment.wiki_page).to eq @hidden_page
        end
      end

      it "does not update a linked assignment" do
        wiki_page_assignment_model(wiki_page: @hidden_page)
        json = api_call(:put,
                        "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                        { controller: "wiki_pages_api",
                          action: "update",
                          format: "json",
                          course_id: @course.to_param,
                          url_or_id: @hidden_page.url },
                        { wiki_page: { title: "Can't Change It",
                                       assignment: { only_visible_to_overrides: true } } })
        page = @course.wiki_pages.where(url: json["url"]).first!
        expect(page.assignment.title).to eq "Content Page Assignment"
        expect(page.assignment.only_visible_to_overrides).to be false
      end

      it "does not destroy linked assignment" do
        wiki_page_assignment_model(wiki_page: @hidden_page)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url },
                 { wiki_page: { assignment: { set_assignment: false } } })
        @hidden_page.reload
        expect(@hidden_page.assignment).not_to be_nil
        expect(@assignment.reload).not_to be_deleted
        expect(@assignment.wiki_page).not_to be_nil
      end
    end

    describe "delete" do
      it "deletes a page", priority: "1" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { controller: "wiki_pages_api",
                   action: "destroy",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @hidden_page.url })
        expect(@hidden_page.reload).to be_deleted
      end

      it "does not delete the front_page" do
        page = @course.wiki_pages.create!(title: "hrup", body: "blooop")
        page.set_as_front_page!

        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                 { controller: "wiki_pages_api", action: "destroy", format: "json", course_id: @course.to_param, url_or_id: page.url },
                 {},
                 {},
                 { expected_status: 400 })

        page.reload
        expect(page).not_to be_deleted

        wiki = @course.wiki
        wiki.reload
        expect(wiki.has_front_page?).to be true
      end
    end

    context "unpublished pages" do
      before :once do
        @deleted_page = @course.wiki_pages.create! title: "Deleted page"
        @deleted_page.destroy
        @unpublished_page = @course.wiki_pages.create(title: "Draft Page", body: "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "is in index" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s)
        expect(json.select { |w| w["title"] == @unpublished_page.title }).not_to be_empty
        expect(json.select { |w| w["title"] == @hidden_page.title }).not_to be_empty
        expect(json.select { |w| w["title"] == @deleted_page.title }).to be_empty
        expect(json.select { |w| w["published"] == true }).not_to be_empty
        expect(json.select { |w| w["published"] == false }).not_to be_empty
      end

      it "is not in index if ?published=true" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?published=true",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s,
                        published: "true")
        expect(json.select { |w| w["title"] == @unpublished_page.title }).to be_empty
        expect(json.select { |w| w["title"] == @hidden_page.title }).to be_empty
        expect(json.select { |w| w["title"] == @deleted_page.title }).to be_empty
        expect(json.select { |w| w["published"] == true }).not_to be_empty
        expect(json.select { |w| w["published"] == false }).to be_empty
      end

      it "is in index exclusively if ?published=false" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?published=false",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s,
                        published: "false")
        expect(json.select { |w| w["title"] == @unpublished_page.title }).not_to be_empty
        expect(json.select { |w| w["title"] == @hidden_page.title }).not_to be_empty
        expect(json.select { |w| w["title"] == @deleted_page.title }).to be_empty
        expect(json.select { |w| w["published"] == true }).to be_empty
        expect(json.select { |w| w["published"] == false }).not_to be_empty
      end

      it "shows" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                        controller: "wiki_pages_api",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        url_or_id: @unpublished_page.url)
        expect(json["title"]).to eq @unpublished_page.title
      end
    end
  end

  context "as a student" do
    before :once do
      course_with_student(course: @course, active_all: true)
    end

    it "lists pages, excluding hidden ones" do
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/pages",
                      controller: "wiki_pages_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s)
      expect(json.map { |entry| entry.slice(*%w[hide_from_students url created_at updated_at title]) }).to eq(
        [{ "hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.revised_at.as_json, "title" => @front_page.title }]
      )
    end

    it "does not allow update to page todo_date if student" do
      todo_date = Time.zone.local(2008, 9, 1, 12, 0, 0)
      page = @course.wiki_pages.create!(title: "hrup", todo_date:)
      api_call(:put,
               "/api/v1/courses/#{@course.id}/pages/#{page.url}",
               { controller: "wiki_pages_api",
                 action: "update",
                 format: "json",
                 course_id: @course.to_param,
                 url_or_id: page.url },
               { wiki_page: { student_planner_checkbox: "0" } })
      expect(response).to be_unauthorized
      page.reload
      expect(page.todo_date).to eq todo_date
    end

    it "paginates excluding hidden" do
      2.times { |i| @course.wiki_pages.create!(title: "New Page #{i}") }
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/pages?per_page=2",
                      controller: "wiki_pages_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      per_page: "2")
      expect(json.size).to eq 2
      urls = json.pluck("url")

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/pages?per_page=2&page=2",
                      controller: "wiki_pages_api",
                      action: "index",
                      format: "json",
                      course_id: @course.id.to_s,
                      per_page: "2",
                      page: "2")
      expect(json.size).to eq 1
      urls += json.pluck("url")

      expect(urls).to eq @wiki.wiki_pages.select(&:published?).sort_by(&:id).collect(&:url)
    end

    it "refuses to show a hidden page" do
      api_call(:get,
               "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
               { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: @hidden_page.url },
               {},
               {},
               { expected_status: 401 })
    end

    it "refuses to list pages in an unpublished course" do
      @course.workflow_state = "created"
      @course.save!
      api_call(:get,
               "/api/v1/courses/#{@course.id}/pages",
               { controller: "wiki_pages_api", action: "index", format: "json", course_id: @course.id.to_s },
               {},
               {},
               { expected_status: 401 })
    end

    it "denies access to wiki in an unenrolled course" do
      other_course = course_factory
      other_course.offer!
      other_wiki = other_course.wiki
      other_wiki.set_front_page_url!("front-page")
      other_page = other_wiki.front_page
      other_page.workflow_state = "active"
      other_page.save!

      api_call(:get,
               "/api/v1/courses/#{other_course.id}/pages",
               { controller: "wiki_pages_api", action: "index", format: "json", course_id: other_course.id.to_s },
               {},
               {},
               { expected_status: 401 })

      api_call(:get,
               "/api/v1/courses/#{other_course.id}/pages/front-page",
               { controller: "wiki_pages_api", action: "show", format: "json", course_id: other_course.id.to_s, url_or_id: "front-page" },
               {},
               {},
               { expected_status: 401 })
    end

    it "allows access to a wiki in a public unenrolled course" do
      other_course = course_factory
      other_course.is_public = true
      other_course.offer!
      other_wiki = other_course.wiki
      other_wiki.set_front_page_url!("front-page")
      other_page = other_wiki.front_page
      other_page.workflow_state = "active"
      other_page.save!

      json = api_call(:get,
                      "/api/v1/courses/#{other_course.id}/pages",
                      { controller: "wiki_pages_api", action: "index", format: "json", course_id: other_course.id.to_s })
      expect(json).not_to be_empty

      api_call(:get,
               "/api/v1/courses/#{other_course.id}/pages/front-page",
               { controller: "wiki_pages_api", action: "show", format: "json", course_id: other_course.id.to_s, url_or_id: "front-page" })
    end

    describe "module progression" do
      before :once do
        @mod = @course.context_modules.create!(name: "some module")
        @tag = @mod.add_item(id: @front_page.id, type: "wiki_page")
        @mod.completion_requirements = { @tag.id => { type: "must_view" } }
        @mod.save!
      end

      it "does not fulfill requirements with index" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages",
                 { controller: "wiki_pages_api", action: "index", format: "json", course_id: @course.id.to_s })
        expect(@mod.evaluate_for(@user).requirements_met).not_to include({ id: @tag.id, type: "must_view" })
      end

      it "fulfills requirements with view on an unlocked page" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
                 { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: @front_page.url })
        expect(@mod.evaluate_for(@user).requirements_met).to include({ id: @tag.id, type: "must_view" })
      end

      it "does not fulfill requirements with view on a locked page" do
        @mod.unlock_at = 1.year.from_now
        @mod.save!
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
                 { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: @front_page.url })
        expect(@mod.evaluate_for(@user).requirements_met).not_to include({ id: @tag.id, type: "must_view" })
      end
    end

    it "does not allow editing a page" do
      api_call(:put,
               "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
               { controller: "wiki_pages_api",
                 action: "update",
                 format: "json",
                 course_id: @course.to_param,
                 url_or_id: @front_page.url },
               { publish: false, wiki_page: { body: "!!!!" } },
               {},
               { expected_status: 401 })
      expect(@front_page.reload.body).not_to eq "!!!!"
    end

    describe "with students in editing_roles" do
      before :once do
        @editable_page = @course.wiki_pages.create! title: "Editable Page", editing_roles: "students"
        @editable_page.workflow_state = "active"
        @editable_page.save!
      end

      it "allows editing the body" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 { wiki_page: { body: "?!?!" } })
        @editable_page.reload
        expect(@editable_page).to be_active
        expect(@editable_page.title).to eq "Editable Page"
        expect(@editable_page.body).to eq "?!?!"
        expect(@editable_page.user_id).to eq @student.id
      end

      it "does not allow editing attributes (with draft state)" do
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 { wiki_page: { published: false } },
                 {},
                 { expected_status: 401 })
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 { wiki_page: { title: "Broken Links" } },
                 {},
                 { expected_status: 401 })
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 { wiki_page: { editing_roles: "teachers" } },
                 {},
                 { expected_status: 401 })
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 { wiki_page: { editing_roles: "teachers,students,public" } },
                 {},
                 { expected_status: 401 })

        @editable_page.reload
        expect(@editable_page).to be_active
        expect(@editable_page.published?).to be_truthy
        expect(@editable_page.title).to eq "Editable Page"
        expect(@editable_page.user_id).not_to eq @student.id
        expect(@editable_page.editing_roles).to eq "students"
      end

      it "fulfills module completion requirements" do
        mod = @course.context_modules.create!(name: "some module")
        tag = mod.add_item(id: @editable_page.id, type: "wiki_page")
        mod.completion_requirements = { tag.id => { type: "must_contribute" } }
        mod.save!

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "update",
                   format: "json",
                   course_id: @course.id.to_s,
                   url_or_id: @editable_page.url },
                 { wiki_page: { body: "edited by student" } })
        expect(mod.evaluate_for(@user).workflow_state).to eq "completed"
      end

      it "does not allow creating pages" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages",
                 { controller: "wiki_pages_api", action: "create", format: "json", course_id: @course.to_param },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "does not allow deleting pages" do
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { controller: "wiki_pages_api",
                   action: "destroy",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @editable_page.url },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "unpublished pages" do
      before :once do
        @unpublished_page = @course.wiki_pages.create(title: "Draft Page", body: "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "is not in index" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s)
        expect(json.select { |w| w["title"] == @unpublished_page.title }).to eq []
        expect(json.select { |w| w["title"] == @hidden_page.title }).to eq []
      end

      it "is not in index even with ?published=false" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages?published=0",
                        controller: "wiki_pages_api",
                        action: "index",
                        format: "json",
                        course_id: @course.id.to_s,
                        published: "0")
        expect(json).to be_empty
      end

      it "does not show" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                 { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: @unpublished_page.url },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "does not show unpublished on public courses" do
        @course.is_public = true
        @course.save!
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                 { controller: "wiki_pages_api", action: "show", format: "json", course_id: @course.id.to_s, url_or_id: @unpublished_page.url },
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    context "revisions" do
      before :once do
        @vpage = @course.wiki_pages.build title: "student version test page", body: "draft"
        @vpage.workflow_state = "unpublished"
        @vpage.save! # rev 1

        @vpage.workflow_state = "active"
        @vpage.body = "published but hidden"
        @vpage.save! # rev 2

        @vpage.body = "now visible to students"
        @vpage.save! # rev 3
      end

      it "refuses to list revisions" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                 { controller: "wiki_pages_api",
                   action: "revisions",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @vpage.url },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "refuses to retrieve a revision" do
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                 { controller: "wiki_pages_api",
                   action: "show_revision",
                   format: "json",
                   course_id: @course.id.to_s,
                   url_or_id: @vpage.url,
                   revision_id: "3" },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "refuses to revert a page" do
        api_call(:post,
                 "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                 { controller: "wiki_pages_api",
                   action: "revert",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @vpage.url,
                   revision_id: "2" },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "describes the latest version" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        course_id: @course.to_param,
                        url_or_id: @vpage.url)
        expect(json["revision_id"]).to eq 3
      end

      context "with page-level student editing role" do
        before :once do
          @vpage.editing_roles = "teachers,students"
          @vpage.body = "with student editing roles"
          @vpage.save! # rev 4
        end

        it "lists revisions" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                          controller: "wiki_pages_api",
                          action: "revisions",
                          format: "json",
                          course_id: @course.to_param,
                          url_or_id: @vpage.url)
          expect(json.pluck("revision_id")).to eq [4, 3, 2, 1]
        end

        it "retrieves an old revision" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                          controller: "wiki_pages_api",
                          action: "show_revision",
                          format: "json",
                          course_id: @course.id.to_s,
                          url_or_id: @vpage.url,
                          revision_id: "3")
          expect(json["body"]).to eq "now visible to students"
        end

        it "retrieves a (formerly) hidden revision" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                          controller: "wiki_pages_api",
                          action: "show_revision",
                          format: "json",
                          course_id: @course.id.to_s,
                          url_or_id: @vpage.url,
                          revision_id: "2")
          expect(json["body"]).to eq "published but hidden"
        end

        it "retrieves a (formerly) unpublished revision" do
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/1",
                          controller: "wiki_pages_api",
                          action: "show_revision",
                          format: "json",
                          course_id: @course.id.to_s,
                          url_or_id: @vpage.url,
                          revision_id: "1")
          expect(json["body"]).to eq "draft"
        end

        it "does not retrieve a version of a locked page" do
          mod = @course.context_modules.create! name: "bad module"
          mod.add_item(id: @vpage.id, type: "wiki_page")
          mod.unlock_at = 1.year.from_now
          mod.save!
          api_call(:get,
                   "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                   { controller: "wiki_pages_api",
                     action: "show_revision",
                     format: "json",
                     course_id: @course.id.to_s,
                     url_or_id: @vpage.url,
                     revision_id: "3" },
                   {},
                   {},
                   { expected_status: 401 })
        end

        it "does not revert page content" do
          api_call(:post,
                   "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                   { controller: "wiki_pages_api",
                     action: "revert",
                     format: "json",
                     course_id: @course.to_param,
                     url_or_id: @vpage.url,
                     revision_id: "2" },
                   {},
                   {},
                   { expected_status: 401 })
        end
      end

      context "with course-level student editing role" do
        before :once do
          @course.default_wiki_editing_roles = "teachers,students"
          @course.save!
        end

        it "reverts page content" do
          api_call(:post,
                   "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                   controller: "wiki_pages_api",
                   action: "revert",
                   format: "json",
                   course_id: @course.to_param,
                   url_or_id: @vpage.url,
                   revision_id: "2")
          @vpage.reload
          expect(@vpage.body).to eq "published but hidden"
        end
      end
    end
  end

  context "group" do
    before :once do
      group_with_user(active_all: true)
      5.times { |i| @group.wiki_pages.create!(title: "Group Wiki Page #{i}", body: "<blink>Content of page #{i}</blink>") }
    end

    it "lists the contents of a group wiki" do
      json = api_call(:get,
                      "/api/v1/groups/#{@group.id}/pages",
                      { controller: "wiki_pages_api", action: "index", format: "json", group_id: @group.to_param })
      expect(json.pluck("title")).to eq @group.wiki_pages.active.order_by_id.collect(&:title)
    end

    it "retrieves page content from a group wiki" do
      testpage = @group.wiki_pages.last
      json = api_call(:get,
                      "/api/v1/groups/#{@group.id}/pages/#{testpage.url}",
                      { controller: "wiki_pages_api", action: "show", format: "json", group_id: @group.to_param, url_or_id: testpage.url })
      expect(json["body"]).to eq testpage.body
    end

    it "creates a group wiki page" do
      json = api_call(:post,
                      "/api/v1/groups/#{@group.id}/pages?wiki_page[title]=newpage",
                      { controller: "wiki_pages_api", action: "create", format: "json", group_id: @group.to_param, wiki_page: { "title" => "newpage" } })
      page = @group.wiki_pages.where(url: json["url"]).first!
      expect(page.title).to eq "newpage"
    end

    it "updates a group wiki page" do
      testpage = @group.wiki_pages.first
      api_call(:put,
               "/api/v1/groups/#{@group.id}/pages/#{testpage.url}?wiki_page[body]=lolcats",
               { controller: "wiki_pages_api", action: "update", format: "json", group_id: @group.to_param, url_or_id: testpage.url, wiki_page: { "body" => "lolcats" } })
      expect(testpage.reload.body).to eq "lolcats"
    end

    it "deletes a group wiki page" do
      count = @group.wiki_pages.not_deleted.size
      testpage = @group.wiki_pages.last
      api_call(:delete,
               "/api/v1/groups/#{@group.id}/pages/#{testpage.url}",
               { controller: "wiki_pages_api", action: "destroy", format: "json", group_id: @group.to_param, url_or_id: testpage.url })
      expect(@group.reload.wiki_pages.not_deleted.size).to eq count - 1
    end

    context "revisions" do
      before :once do
        @vpage = @group.wiki_pages.create! title: "revision test page", body: "old version"
        @vpage.body = "new version"
        @vpage.save!
      end

      it "lists revisions for a page" do
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions",
                        controller: "wiki_pages_api",
                        action: "revisions",
                        format: "json",
                        group_id: @group.to_param,
                        url_or_id: @vpage.url)
        expect(json.pluck("revision_id")).to eq [2, 1]
      end

      it "retrieves an old revision of a page" do
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/1",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        group_id: @group.to_param,
                        url_or_id: @vpage.url,
                        revision_id: "1")
        expect(json["body"]).to eq "old version"
      end

      it "retrieves the latest version of a page" do
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/latest",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        group_id: @group.to_param,
                        url_or_id: @vpage.url)
        expect(json["body"]).to eq "new version"
      end

      it "reverts to an old version of a page" do
        api_call(:post,
                 "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/1",
                 { controller: "wiki_pages_api",
                   action: "revert",
                   format: "json",
                   group_id: @group.to_param,
                   url_or_id: @vpage.url,
                   revision_id: "1" })
        expect(@vpage.reload.body).to eq "old version"
      end

      it "summarizes the latest version" do
        json = api_call(:get,
                        "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/latest?summary=1",
                        controller: "wiki_pages_api",
                        action: "show_revision",
                        format: "json",
                        group_id: @group.to_param,
                        url_or_id: @vpage.url,
                        summary: "1")
        expect(json["revision_id"]).to eq 2
        expect(json["body"]).to be_nil
      end
    end
  end

  context "differentiated assignments" do
    def create_page_for_da(assignment_opts = {})
      assignment = @course.assignments.create!(assignment_opts)
      assignment.submission_types = "wiki_page"
      assignment.save!
      page = @course.wiki_pages.build(
        user: @teacher,
        editing_roles: "teachers,students",
        title: assignment_opts[:title]
      )
      page.assignment = assignment
      page.save!
      [assignment, page]
    end

    def get_index
      raw_api_call(:get,
                   api_v1_course_wiki_pages_path(@course.id, format: :json),
                   controller: "wiki_pages_api",
                   action: "index",
                   format: :json,
                   course_id: @course.id)
    end

    def get_show(page)
      raw_api_call(:get,
                   api_v1_course_wiki_page_path(@course.id, page.url, format: :json),
                   controller: "wiki_pages_api",
                   action: "show",
                   format: :json,
                   course_id: @course.id,
                   url_or_id: page.url)
    end

    def put_update(page)
      raw_api_call(:put,
                   "/api/v1/courses/#{@course.id}/pages/#{page.url}.json",
                   { controller: "wiki_pages_api",
                     action: "update",
                     format: :json,
                     course_id: @course.id,
                     url_or_id: page.url },
                   { wiki_page: {} })
    end

    def get_revisions(page)
      raw_api_call(:get,
                   "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions.json",
                   controller: "wiki_pages_api",
                   action: "revisions",
                   format: :json,
                   course_id: @course.id,
                   url_or_id: page.url)
    end

    def get_show_revision(page)
      raw_api_call(:get,
                   "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions/latest.json",
                   controller: "wiki_pages_api",
                   action: "show_revision",
                   format: :json,
                   course_id: @course.id,
                   url_or_id: page.url)
    end

    def post_revert(page)
      raw_api_call(:post,
                   "/api/v1/courses/#{@course.id}/pages/#{page.url}/revisions/1.json",
                   controller: "wiki_pages_api",
                   action: "revert",
                   format: :json,
                   course_id: @course.id,
                   url_or_id: page.url,
                   revision_id: 1)
    end

    let(:calls) { %i[get_show put_update get_revisions get_show_revision post_revert] }

    def calls_succeed(page, opts = { except: [] })
      get_index
      expect(JSON.parse(response.body).to_s).to include(page.title)

      calls.reject! { |call| opts[:except].include?(call) }
      calls.each { |call| expect(send(call, page).to_s).to eq "200" }
    end

    def calls_fail(page)
      get_index
      expect(JSON.parse(response.body).to_s).not_to include(page.title.to_s)

      calls.each { |call| expect(send(call, page).to_s).to eq "401" }
    end

    before :once do
      course_with_teacher(active_all: true, user: user_with_pseudonym)
      @student_with_override, @student_without_override = create_users(2, return_type: :record)

      @assignment_1, @page_assigned_to_override = create_page_for_da(
        title: "assigned to student_with_override",
        only_visible_to_overrides: true
      )
      @assignment_2, @page_assigned_to_all = create_page_for_da(
        title: "assigned to all",
        only_visible_to_overrides: false
      )
      @page_unassigned = @course.wiki_pages.create!(
        title: "definitely not assigned",
        user: @teacher,
        editing_roles: "teachers,students"
      )

      @course.enroll_student(@student_without_override, enrollment_state: "active")
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student_with_override)
      create_section_override_for_assignment(@assignment_1, course_section: @section)

      @observer = User.create
      @observer_enrollment = @course.enroll_user(@observer,
                                                 "ObserverEnrollment",
                                                 section: @course.course_sections.first,
                                                 enrollment_state: "active")
    end

    context "enabled" do
      before(:once) do
        @course.conditional_release = true
        @course.save!
      end

      it "lets the teacher see all pages" do
        @user = @teacher
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each { |p| calls_succeed(p) }
      end

      it "lets students with visibility see pages" do
        @user = @student_with_override
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: [:post_revert])
        end
      end

      it "restricts access to students without visibility" do
        @user = @student_without_override
        calls_fail(@page_assigned_to_override)
        calls_succeed(@page_assigned_to_all, except: [:post_revert])
        calls_succeed(@page_unassigned, except: [:post_revert])
      end

      it "gives observers same visibility as unassigned student" do
        @observer_enrollment.update_attribute(:associated_user_id, @student_without_override.id)
        @user = @observer
        calls_fail(@page_assigned_to_override)
        [@page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end

      it "gives observers same visibility as assigned student" do
        @observer_enrollment.update_attribute(:associated_user_id, @student_with_override.id)
        @user = @observer
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end

      it "gives observers without visibility all the things" do
        @observer_enrollment.update_attribute(:associated_user_id, nil)
        @user = @observer
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p,
                        except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end
    end

    context "disabled" do
      before(:once) do
        @course.conditional_release = false
        @course.save!
      end

      it "lets the teacher see all pages" do
        @user = @teacher
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each { |p| calls_succeed(p) }
      end

      it "lets students with visibility see pages" do
        @user = @student_with_override
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: [:post_revert])
        end
      end

      it "lets students without visibility see pages" do
        @user = @student_without_override
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: [:post_revert])
        end
      end

      it "gives observers same visibility as unassigned student" do
        @observer_enrollment.update_attribute(:associated_user_id, @student_without_override.id)
        @user = @observer
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end

      it "gives observers same visibility as assigned student" do
        @observer_enrollment.update_attribute(:associated_user_id, @student_with_override.id)
        @user = @observer
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p, except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end

      it "gives observers without visibility all the things" do
        @observer_enrollment.update_attribute(:associated_user_id, nil)
        @user = @observer
        [@page_assigned_to_override, @page_assigned_to_all, @page_unassigned].each do |p|
          calls_succeed(p,
                        except: %i[post_revert put_update get_revisions get_show_revision])
        end
      end
    end
  end
end
