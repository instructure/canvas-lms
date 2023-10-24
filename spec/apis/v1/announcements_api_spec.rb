# frozen_string_literal: true

#
# Copyright (C) 2016 Instructure, Inc.
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

describe "Announcements API", type: :request do
  before :once do
    course_with_teacher active_all: true
    student_in_course active_enrollment: true
    @course1 = @course
    @ann1 = @course1.announcements.build title: "Announcement 1", message: "1"
    @ann1.posted_at = 7.days.ago
    @ann1.save!

    # For testing chronological ordering
    @anns = []

    1.upto(5) do |i|
      ann = @course1.announcements.build title: "Accountment 1.#{i}", message: i
      ann.posted_at = (7 - i).days.ago # To make them more recent each time
      ann.save!

      @anns << ann
    end

    course_with_teacher active_all: true, user: @teacher
    student_in_course active_enrollment: true, user: @student
    @course2 = @course
    @ann2 = @course2.announcements.build title: "Announcement 2", message: "2"
    @ann2.workflow_state = "post_delayed"
    @ann2.posted_at = Time.now
    @ann2.delayed_post_at = 21.days.from_now
    @ann2.save!

    @params = { controller: "announcements_api", action: "index", format: "json" }
  end

  context "as teacher" do
    it "requires course_ids argument" do
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements", @params, {}, {}, { expected_status: 400 })
      expect(json["message"]).to eq "Missing context_codes"
    end

    it "does not accept contexts other than courses" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["user_#{@teacher.id}"]),
                              {},
                              {},
                              { expected_status: 400 })
      expect(json["message"]).to include "Invalid context_codes"
    end

    it "filters out announcements with :read_announcements permission lacking" do
      @account = Account.default
      custom_role = custom_teacher_role("No Announcement Viewing")
      @account.role_overrides.create!(role: custom_role, enabled: false, permission: :read_announcements)

      course_with_teacher(active_all: true, user: @teacher, role: custom_role)

      @other_course = @course
      @other_course.announcements.create title: "Announcement That Should Be Filtered", message: "1"

      context_codes = ["course_#{@course1.id}", "course_#{@course2.id}", "course_#{@other_course.id}"]
      json = api_call_as_user @teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes:),
                              {},
                              {},
                              { expected_status: 200 }
      expect(json.length).to eq 6
    end

    it "returns announcements for the the surrounding 14 days by default" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"]))
      expect(json.length).to eq 6
      expect(json[0]["context_code"]).to eq "course_#{@course1.id}"
    end

    it "returns announcements for the given date range" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))

      all_anns = @anns.map { |e| [e["context_code"], e["id"]] }
      all_anns.push(["course_#{@course1.id}", @ann1.id], ["course_#{@course2.id}", @ann2.id])
      expect(json.length).to eq 7
      expect(json.map { |e| [e["context_code"], e["id"]] }).to match_array all_anns
    end

    it "validates date formats" do
      start_date = "next sursdai"
      end_date = "y'all biscuitheads"
      api_call_as_user(@teacher,
                       :get,
                       "/api/v1/announcements",
                       @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                     start_date:,
                                     end_date:),
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "matches dates inclusive" do
      start_date = end_date = @ann2.delayed_post_at.strftime("%F")
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))
      expect(json.pluck("id")).to eq [@ann2.id]
    end

    it "paginates" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:,
                                            per_page: 1))
      expect(json.length).to eq 1
      next_link = response.headers["Link"].split(",").detect { |link| link.include?('rel="next"') }
      expect(next_link).to match(%r{/api/v1/announcements})
      expect(next_link).to include "page=2"
    end

    it "orders by reverse chronological order" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}"]))
      expect(json.length).to eq 6
      expect(json[0]["context_code"]).to eq "course_#{@course1.id}"
      expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
    end

    describe "active_only" do
      it "excludes delayed-post announcements" do
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                              start_date:,
                                              end_date:,
                                              active_only: true))
        expect(json.length).to eq 6
        expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
      end

      it "includes 'active' announcements with past `delayed_post_at`" do
        @ann1.update_attribute(:delayed_post_at, 7.days.ago)
        expect(@ann1).to be_active
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                              start_date:,
                                              end_date:,
                                              active_only: true))
        expect(json.length).to eq 6
        expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
      end

      it "excludes courses not in the context_ids list" do
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(context_codes: ["course_#{@course2.id}"],
                                              start_date:,
                                              end_date:,
                                              active_only: true))
        expect(json).to be_empty
      end
    end

    describe "latest_only" do
      before :once do
        course_with_teacher active_all: true, user: @teacher
        student_in_course active_enrollment: true, user: @student
        @course3 = @course
        @ann3 = @course3.announcements.build title: "Announcement New", message: "<p>This is the latest</p>"
        @ann3.posted_at = 2.days.ago
        @ann3.save!
        old = @course3.announcements.build title: "Announcement Old", message: "<p>This is older</p>"
        old.posted_at = 5.days.ago
        old.save!
      end

      let(:start_date) { 10.days.ago.iso8601 }
      let(:end_date) { 30.days.from_now.iso8601 }

      it "only returns the latest announcement by posted date" do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(:context_codes => %W[course_#{@course1.id} course_#{@course2.id} course_#{@course3.id}],
                                              start_date => start_date,
                                              :end_date => end_date,
                                              :latest_only => true))

        expect(json.length).to be 3
        expect(json.pluck("id")).to include(@anns.last[:id], @ann2[:id], @ann3[:id])
      end

      it "excludes courses not in the context_ids list" do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(:context_codes => %W[course_#{@course1.id} course_#{@course3.id}],
                                              start_date => start_date,
                                              :end_date => end_date,
                                              :latest_only => true))

        expect(json.length).to be 2
        expect(json.pluck("id")).to include(@anns.last[:id], @ann3[:id])
      end

      it "works properly in conjunction with the active_only param" do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                @params.merge(:context_codes => %W[course_#{@course1.id} course_#{@course2.id} course_#{@course3.id}],
                                              start_date => start_date,
                                              :end_date => end_date,
                                              :active_only => true,
                                              :latest_only => true))

        expect(json.length).to be 2
        expect(json.pluck("id")).to include(@anns.last[:id], @ann3[:id])
      end
    end
  end

  context "as student" do
    it "excludes delayed-post announcements" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))
      expect(json.length).to eq 6
      expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
    end

    it "excludes 'active' announcements with future `delayed_post_at`" do
      @ann2.update_attribute(:workflow_state, "active")
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))
      expect(json.length).to eq 6
      expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
    end

    it "includes 'active' announcements with past `delayed_post_at`" do
      @ann1.update_attribute(:delayed_post_at, 7.days.ago)
      expect(@ann1).to be_active
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))
      expect(json.length).to eq 6
      expect(json.pluck("id")).to eq @anns.map(&:id).reverse << @ann1.id
    end

    it "excludes courses not in the context_ids list" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student,
                              :get,
                              "/api/v1/announcements",
                              @params.merge(context_codes: ["course_#{@course2.id}"],
                                            start_date:,
                                            end_date:))
      expect(json).to be_empty
    end
  end

  context "sharding" do
    specs_require_sharding

    before(:once) do
      @shard2.activate do
        course_with_teacher(active_course: true)
        @announcement = @course.announcements.create!(user: @teacher, message: "hello from shard 2")
      end
    end

    it "returns announcements across shards" do
      @shard1.activate do
        json = api_call_as_user(@teacher,
                                :get,
                                "/api/v1/announcements",
                                {
                                  controller: "announcements_api",
                                  action: "index",
                                  format: "json",
                                  context_codes: ["course_#{@course.id}"]
                                })
        expect(json.count).to eq(1)
        expect(json[0]["id"]).to eq(@announcement.id)
        expect(json[0]["context_code"]).to eq("course_#{@course.id}")
      end
    end
  end

  describe "section specific announcements" do
    before(:once) do
      course_with_teacher(active_course: true)
      @section = @course.course_sections.create!(name: "test section")

      @announcement = @course.announcements.create!(user: @teacher, message: "hello my favorite section!")
      @announcement.is_section_specific = true
      @announcement.course_sections = [@section]
      @announcement.save!

      @student1, @student2 = create_users(2, return_type: :record)
      @course.enroll_student(@student1, enrollment_state: "active")
      @course.enroll_student(@student2, enrollment_state: "active")
      student_in_section(@section, user: @student1)
    end

    it "teacher should be able to see section specific announcements" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              {
                                controller: "announcements_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"]
                              })

      expect(json.count).to eq(1)
      expect(json[0]["id"]).to eq(@announcement.id)
      expect(json[0]["is_section_specific"]).to be(true)
    end

    it "teacher should be able to see section specific announcements and include sections" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              {
                                controller: "announcements_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"],
                                include: ["sections"],
                              })

      expect(json.count).to eq(1)
      expect(json[0]["id"]).to eq(@announcement.id)
      expect(json[0]["is_section_specific"]).to be(true)
      expect(json[0]["sections"].count).to eq(1)
      expect(json[0]["sections"][0]["id"]).to eq(@section.id)
    end

    it "teacher should be able to see section specific announcements and include sections and sections user count" do
      json = api_call_as_user(@teacher,
                              :get,
                              "/api/v1/announcements",
                              {
                                controller: "announcements_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"],
                                include: ["sections", "sections_user_count"],
                              })

      expect(json.count).to eq(1)
      expect(json[0]["id"]).to eq(@announcement.id)
      expect(json[0]["is_section_specific"]).to be(true)
      expect(json[0]["sections"].count).to eq(1)
      expect(json[0]["sections"][0]["id"]).to eq(@section.id)
      expect(json[0]["sections"][0]["user_count"]).to eq(1)
    end

    it "student in section should be able to see section specific announcements" do
      json = api_call_as_user(@student1,
                              :get,
                              "/api/v1/announcements",
                              {
                                controller: "announcements_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"]
                              })

      expect(json.count).to eq(1)
      expect(json[0]["id"]).to eq(@announcement.id)
      expect(json[0]["is_section_specific"]).to be(true)
    end

    it "student not in section should not be able to see section specific announcements" do
      json = api_call_as_user(@student2,
                              :get,
                              "/api/v1/announcements",
                              {
                                controller: "announcements_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"]
                              })

      expect(json.count).to eq(0)
    end
  end
end
