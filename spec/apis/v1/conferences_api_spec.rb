# frozen_string_literal: true

#
# Copyright (C) 2013 Instructure, Inc.
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

describe "Conferences API", type: :request do
  include Api::V1::Conferences
  include Api::V1::Json
  include Api

  def named_context_url(context, type, conf)
    raise unless type == :context_conference_url

    "/#{context.class.name.downcase}s/#{context.id}/conferences/#{conf.id}"
  end

  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: "wimba")
    @plugin.update_attribute(:settings, { domain: "wimba.test" })
    @category_path_options = { controller: "conferences", format: "json" }
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @user = @teacher
  end

  describe "GET list of conferences" do
    it "requires authorization" do
      @user = nil
      raw_api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options
        .merge(action: "index", course_id: @course.to_param))
      expect(response).to have_http_status :unauthorized
    end

    it "lists all the conferences" do
      @conferences = (1..2).map do |i|
        @course.web_conferences.create!(conference_type: "Wimba",
                                        duration: 60,
                                        user: @teacher,
                                        title: "Wimba #{i}")
      end

      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options
        .merge(action: "index", course_id: @course.to_param))
      expect(json).to eq api_conferences_json(@conferences.reverse.map { |c| WebConference.find(c.id) }, @course, @user)
    end

    it "does not list conferences for disabled plugins" do
      plugin = PluginSetting.create!(name: "adobe_connect")
      plugin.update_attribute(:settings, { domain: "adobe_connect.test" })
      @conferences = ["AdobeConnect", "Wimba"].map do |ct|
        @course.web_conferences.create!(conference_type: ct,
                                        duration: 60,
                                        user: @teacher,
                                        title: ct)
      end
      plugin.disabled = true
      plugin.save!
      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options
        .merge(action: "index", course_id: @course.to_param))
      expect(json).to eq api_conferences_json([WebConference.find(@conferences[1].id)], @course, @user)
    end

    it "only lists conferences the user is a participant of" do
      @user = @student
      @conferences = (1..2).map do |i|
        @course.web_conferences.create!(conference_type: "Wimba",
                                        duration: 60,
                                        user: @teacher,
                                        title: "Wimba #{i}")
      end
      @conferences[0].users << @user
      @conferences[0].save!
      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options
        .merge(action: "index", course_id: @course.to_param))
      expect(json).to eq api_conferences_json([WebConference.find(@conferences[0].id)], @course, @user)
    end

    it "gets a conferences for a group" do
      @user = @student
      @group = @course.groups.create!(name: "My Group")
      @group.add_user(@student, "accepted", true)
      @conferences = (1..2).map do |i|
        @group.web_conferences.create!(conference_type: "Wimba",
                                       duration: 60,
                                       user: @teacher,
                                       title: "Wimba #{i}")
      end
      json = api_call(:get, "/api/v1/groups/#{@group.to_param}/conferences", @category_path_options
        .merge(action: "index", group_id: @group.to_param))
      expect(json).to eq api_conferences_json(@conferences.reverse.map { |c| WebConference.find(c.id) }, @group, @student)
    end
  end

  describe "GET conferences for a user" do
    let(:request_params) { { controller: "conferences", action: "for_user", format: "json" } }

    it "requires a valid user" do
      @user = nil
      raw_api_call(:get, "/api/v1/conferences.json", { controller: "conferences", action: "for_user", format: "json" })
      assert_unauthorized
    end

    context "within a single shard" do
      let(:response_json) { api_call_as_user(student, :get, "/api/v1/conferences.json", request_params) }
      let(:conference_json_ids) { response_json["conferences"].pluck("id") }

      let(:course) { course_factory(active_course: true) }
      let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
      let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }

      let(:group) do
        group_category = course.group_categories.create!(name: "a category")
        group_category.create_groups(1)

        group = group_category.groups.first
        group.add_user(student)
        group
      end

      it "returns an empty array if conferences are not configured" do
        @plugin.update_attribute(:disabled, true)
        expect(conference_json_ids).to be_empty
      end

      describe "course conferences" do
        let(:conference) { course.web_conferences.create!(conference_type: "Wimba", user: teacher) }

        before do
          conference.add_user(student, "attendee")
        end

        it "includes conferences for courses the user is actively enrolled in" do
          expect(conference_json_ids).to contain_exactly(conference.id)
        end

        it "excludes conferences for courses the user is not actively enrolled in" do
          StudentEnrollment.find_by(user: student, course:).destroy
          expect(conference_json_ids).to be_empty
        end
      end

      describe "group conferences" do
        let(:conference) { group.web_conferences.create!(conference_type: "Wimba", user: teacher) }

        before do
          conference.add_user(student, "attendee")
        end

        it "includes conferences for groups with the user as an active member" do
          expect(conference_json_ids).to contain_exactly(conference.id)
        end

        it "excludes conferences for groups for which this user is not an active member" do
          GroupMembership.find_by!(user: student, group:).update!(workflow_state: "deleted")

          expect(conference_json_ids).to be_empty
        end
      end

      context "with state = 'live'" do
        let(:response_json) { api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ state: "live" })) }
        let(:conference_json_ids) { response_json["conferences"].pluck("id") }

        it "includes conferences that have started and not finished yet" do
          past_conference = course.web_conferences.create!(
            conference_type: "Wimba",
            started_at: Time.zone.at(2.hours.ago),
            ended_at: Time.zone.at(1.hour.ago),
            user: teacher
          )
          past_conference.add_user(student, "attendee")

          live_conference_with_end_time = course.web_conferences.create!(
            conference_type: "Wimba",
            started_at: Time.zone.at(30.minutes.ago),
            ended_at: Time.zone.at(30.minutes.from_now),
            user: teacher
          )
          live_conference_with_end_time.add_user(student, "attendee")

          live_conference_with_no_end_time = course.web_conferences.create!(
            conference_type: "Wimba",
            duration: 60,
            started_at: Time.zone.at(30.minutes.ago),
            user: teacher
          )
          live_conference_with_no_end_time.add_user(student, "attendee")

          future_conference = course.web_conferences.create!(
            conference_type: "Wimba",
            started_at: Time.zone.at(1.hour.from_now),
            ended_at: Time.zone.at(2.hours.from_now),
            user: teacher
          )
          future_conference.add_user(student, "attendee")

          expect(conference_json_ids).to match_array([
                                                       live_conference_with_end_time.id,
                                                       live_conference_with_no_end_time.id
                                                     ])
        end

        it "excludes conferences that are active but started more than a day ago" do
          zombie_conference = course.web_conferences.create!(
            conference_type: "Wimba",
            started_at: Time.zone.at(2.days.ago),
            user: teacher
          )
          zombie_conference.add_user(student, "attendee")
          expect(conference_json_ids).to be_empty
        end
      end

      describe "result ordering" do
        let(:past_conference) do
          Timecop.freeze(1.hour.ago) do
            course.web_conferences.create!(
              conference_type: "Wimba",
              started_at: Time.zone.at(Time.zone.now),
              ended_at: Time.zone.at(1.hour.from_now),
              user: teacher
            )
          end
        end

        let(:future_conference) do
          Timecop.freeze(1.hour.from_now) do
            course.web_conferences.create!(
              conference_type: "Wimba",
              started_at: Time.zone.at(Time.zone.now),
              ended_at: Time.zone.at(1.hour.from_now),
              user: teacher
            )
          end
        end

        let(:present_conference) do
          course.web_conferences.create!(
            conference_type: "Wimba",
            started_at: Time.zone.at(Time.zone.now),
            ended_at: Time.zone.at(1.hour.from_now),
            user: teacher
          )
        end

        it "sorts results by creation date in descending order" do
          past_conference.add_user(student, "attendee")
          present_conference.add_user(student, "attendee")
          future_conference.add_user(student, "attendee")

          expect(conference_json_ids).to eq [future_conference.id, present_conference.id, past_conference.id]
        end

        context "with paginated results" do
          before do
            past_conference.add_user(student, "attendee")
            present_conference.add_user(student, "attendee")
            future_conference.add_user(student, "attendee")
            conferences = Timecop.freeze(1.month.from_now) do
              [
                WebConference.create!(
                  id: greater_id,
                  conference_type: "Wimba",
                  context: course,
                  started_at: Time.zone.at(Time.zone.now),
                  ended_at: Time.zone.at(1.hour.from_now),
                  user: teacher
                ),
                WebConference.create!(
                  id: smaller_id,
                  conference_type: "Wimba",
                  context: course,
                  started_at: Time.zone.at(Time.zone.now),
                  ended_at: Time.zone.at(1.hour.from_now),
                  user: teacher
                )
              ]
            end
            conferences.each { |conference| conference.add_user(student, "attendee") }
          end

          let(:greater_id) { 99_999_999 }
          let(:smaller_id) { 99_999_998 }
          let(:request_params) do
            { controller: "conferences", action: "for_user", format: "json", per_page: }
          end
          let(:per_page) { 2 }

          it "paginates results with correct previous page" do
            first_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params)
            expect(first_page_response["conferences"].length).to eq 2
            expect(first_page_response["conferences"].first["id"]).to eq(greater_id)
            expect(first_page_response["conferences"].second["id"]).to eq(smaller_id)

            # follow_pagination_link is broken
            links = Api.parse_pagination_links(response.headers["Link"])
            page = links.find { |l| l[:rel] == "next" }["page"]

            second_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ page: }))
            expect(second_page_response["conferences"].length).to eq 2
            expect(second_page_response["conferences"].first["id"]).to eq(future_conference.id)
            expect(second_page_response["conferences"].second["id"]).to eq(present_conference.id)
          end
        end

        it "sorts results with equal creation dates by ID in descending order" do
          conferences = Timecop.freeze(1.hour.ago) do
            [
              WebConference.create!(
                conference_type: "Wimba",
                context: course,
                started_at: Time.zone.at(Time.zone.now),
                ended_at: Time.zone.at(1.hour.from_now),
                user: teacher
              ),
              WebConference.create!(
                conference_type: "Wimba",
                context: course,
                started_at: Time.zone.at(Time.zone.now),
                ended_at: Time.zone.at(1.hour.from_now),
                user: teacher
              )
            ]
          end
          conferences.each { |conference| conference.add_user(student, "attendee") }

          expect(conference_json_ids).to eq [conferences.second.id, conferences.first.id]
        end
      end
    end

    context "with multiple shards" do
      specs_require_sharding

      let_once(:home_shard) { Shard.default }
      let_once(:student) { User.create! }
      let_once(:teacher) { User.create! }

      let_once(:home_course) do
        home_shard.activate do
          course_factory(active_course: true, account: Account.create!, course_name: "home course")
        end
      end
      let_once(:home_group) do
        home_shard.activate do
          group_category = home_course.group_categories.create!(name: "a category")
          group_category.create_groups(1)

          group_category.groups.first
        end
      end

      let_once(:another_shard) { @shard1 }
      let_once(:another_account) { another_shard.activate { Account.create! } }
      let_once(:another_course) do
        another_shard.activate do
          course_factory(active_course: true, account: another_account, course_name: "another course")
        end
      end
      let_once(:another_group) do
        another_account.shard.activate do
          group_category = another_account.group_categories.create!(name: "a category")
          group_category.create_groups(1)

          group_category.groups.first
        end
      end

      let(:response_json) { api_call_as_user(student, :get, "/api/v1/conferences.json", request_params) }
      let(:conference_json_ids) { response_json["conferences"].pluck("id") }

      before(:once) do
        home_course.enroll_student(student, enrollment_state: "active")
        another_course.enroll_student(student, enrollment_state: "active")

        Timecop.freeze(1.day.ago) do
          conference = home_course.web_conferences.create!(conference_type: "Wimba", user: teacher)
          conference.add_user(student, "attendee")
        end

        Timecop.freeze(1.day.from_now) do
          home_group.add_user(student)
          conference = home_group.web_conferences.create!(conference_type: "Wimba", user: teacher)
          conference.add_user(student, "attendee")
        end

        another_shard.activate do
          Timecop.freeze(2.days.ago) do
            conference = another_course.web_conferences.create!(conference_type: "Wimba", user: teacher)
            conference.add_user(student, "attendee")
          end

          Timecop.freeze(2.days.from_now) do
            another_group.add_user(student)
            conference = another_group.web_conferences.create!(conference_type: "Wimba", user: teacher)
            conference.add_user(student, "attendee")
          end
        end
      end

      it "returns results from across all applicable shards" do
        expect(conference_json_ids.length).to eq 4
      end

      it "sorts all results by descending creation date" do
        expect(conference_json_ids).to eq [
          another_group.web_conferences.first.id,
          home_group.web_conferences.first.id,
          home_course.web_conferences.first.id,
          another_course.web_conferences.first.id
        ]
      end

      context "with paginated results" do
        let(:request_params) do
          { controller: "conferences", action: "for_user", format: "json", per_page: }
        end
        let(:per_page) { 1 }

        it "paginates results with correct previous page" do
          first_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params)
          expect(first_page_response["conferences"].length).to eq 1
          expect(first_page_response["conferences"].first["id"]).to eq(another_group.web_conferences.first.id)

          # follow_pagination_link is broken
          links = Api.parse_pagination_links(response.headers["Link"])
          page = links.find { |l| l[:rel] == "next" }["page"]

          second_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ page: }))
          expect(second_page_response["conferences"].length).to eq 1
          expect(second_page_response["conferences"].first["id"]).to eq(home_group.web_conferences.first.id)
        end

        context "with multiple results having the same created_at timestamp" do
          let(:per_page) { 5 }
          let(:greater_id) { 99_999_999 }
          let(:smaller_id) { 99_999_998 }

          before(:once) do
            Timecop.freeze(1.week.ago) do
              home_shard.activate do
                conference = home_course.web_conferences.create!(id: greater_id, conference_type: "Wimba", user: teacher)
                conference.add_user(student, "attendee")
              end

              another_shard.activate do
                conference = another_course.web_conferences.create!(id: smaller_id, conference_type: "Wimba", user: teacher)
                conference.add_user(student, "attendee")
              end
            end
          end

          it "orders by id desc cross-shard" do
            first_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params)
            expect(first_page_response["conferences"].length).to eq 5
            first_page_last_record = first_page_response["conferences"].pluck("id").last
            # This is not consistent which shard runs the query so it can be either global or local id
            expect(first_page_last_record.to_s).to end_with(greater_id.to_s)

            # follow_pagination_link is broken
            links = Api.parse_pagination_links(response.headers["Link"])
            page = links.find { |l| l[:rel] == "next" }["page"]

            second_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ page: }))
            second_page_last_record = second_page_response["conferences"].pluck("id").last
            # This is not consistent which shard runs the query so it can be either global or local id
            expect(second_page_last_record.to_s).to end_with(smaller_id.to_s)
          end
        end

        context "When only course or group conferences exist" do
          let(:per_page) { 1 }
          let(:greater_id) { 99_999_999 }
          let(:smaller_id) { 99_999_998 }

          context "only course conferences exist" do
            before(:once) do
              Shard.find_each do |shard|
                shard.activate do
                  WebConference.find_each do |conf|
                    conf.web_conference_participants.delete_all
                    conf.delete
                  end
                end
              end

              Timecop.freeze(1.week.ago) do
                home_shard.activate do
                  conference = home_course.web_conferences.create!(id: greater_id, conference_type: "Wimba", user: teacher)
                  conference.add_user(student, "attendee")
                end

                another_shard.activate do
                  conference = another_course.web_conferences.create!(id: smaller_id, conference_type: "Wimba", user: teacher)
                  conference.add_user(student, "attendee")
                end
              end
            end

            it "orders by id desc cross-shard" do
              first_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params)
              expect(first_page_response["conferences"].length).to eq 1
              first_page_last_record = first_page_response["conferences"].pluck("id").last
              # This is not consistent which shard runs the query so it can be either global or local id
              expect(first_page_last_record.to_s).to end_with(greater_id.to_s)

              # follow_pagination_link is broken
              links = Api.parse_pagination_links(response.headers["Link"])
              page = links.find { |l| l[:rel] == "next" }["page"]

              second_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ page: }))
              second_page_last_record = second_page_response["conferences"].pluck("id").last
              # This is not consistent which shard runs the query so it can be either global or local id
              expect(second_page_last_record.to_s).to end_with(smaller_id.to_s)
            end
          end

          context "only group conferences exist" do
            before(:once) do
              Shard.find_each do |shard|
                shard.activate do
                  WebConference.find_each do |conf|
                    conf.web_conference_participants.delete_all
                    conf.delete
                  end
                end
              end

              Timecop.freeze(1.week.ago) do
                home_shard.activate do
                  home_group.add_user(student)
                  conference = home_group.web_conferences.create!(id: greater_id, conference_type: "Wimba", user: teacher)
                  conference.add_user(student, "attendee")
                end

                another_shard.activate do
                  another_group.add_user(student)
                  conference = another_group.web_conferences.create!(id: smaller_id, conference_type: "Wimba", user: teacher)
                  conference.add_user(student, "attendee")
                end
              end
            end

            it "orders by id desc cross-shard" do
              first_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params)
              expect(first_page_response["conferences"].length).to eq 1
              first_page_last_record = first_page_response["conferences"].pluck("id").last
              # This is not consistent which shard runs the query so it can be either global or local id
              expect(first_page_last_record.to_s).to end_with(greater_id.to_s)

              # follow_pagination_link is broken
              links = Api.parse_pagination_links(response.headers["Link"])
              page = links.find { |l| l[:rel] == "next" }["page"]

              second_page_response = api_call_as_user(student, :get, "/api/v1/conferences.json", request_params.merge({ page: }))
              second_page_last_record = second_page_response["conferences"].pluck("id").last
              # This is not consistent which shard runs the query so it can be either global or local id
              expect(second_page_last_record.to_s).to end_with(smaller_id.to_s)
            end
          end
        end
      end
    end
  end

  describe "POST 'recording_ready'" do
    before do
      allow(WebConference).to receive(:plugins).and_return([
                                                             web_conference_plugin_mock("big_blue_button", {
                                                                                          domain: "bbb.instructure.com",
                                                                                          secret_dec: "secret",
                                                                                        })
                                                           ])
    end

    let(:conference) do
      BigBlueButtonConference.create!(context: course_factory,
                                      user: user_factory,
                                      conference_key: "conf_key")
    end

    let(:course_id) { conference.context.id }

    let(:path) do
      "/api/v1/courses/#{course_id}/conferences/#{conference.id}/recording_ready"
    end

    let(:params) do
      @category_path_options.merge(action: "recording_ready",
                                   course_id:,
                                   conference_id: conference.id)
    end

    it "marks the recording as ready" do
      payload = { meeting_id: conference.conference_key }
      jwt = Canvas::Security.create_jwt(payload, nil, conference.config[:secret_dec])
      body_params = { signed_parameters: jwt }

      raw_api_call(:post, path, params, body_params)
      expect(response).to have_http_status :accepted
    end

    it "errors if the secret key is wrong" do
      payload = { meeting_id: conference.conference_key }
      jwt = Canvas::Security.create_jwt(payload, nil, "wrong_key")
      body_params = { signed_parameters: jwt }

      raw_api_call(:post, path, params, body_params)
      expect(response).to have_http_status :unauthorized
    end

    it "errors if the conference_key is wrong" do
      payload = { meeting_id: "wrong_conference_key" }
      jwt = Canvas::Security.create_jwt(payload, nil, conference.config[:secret_dec])
      body_params = { signed_parameters: jwt }

      raw_api_call(:post, path, params, body_params)
      expect(response).to have_http_status :unprocessable_content
    end
  end
end
