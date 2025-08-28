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

describe GraphQLController do # rubocop:disable RSpec/SpecFilePathFormat
  before :once do
    student_in_course(user: user_with_pseudonym)
  end

  context "graphiql" do
    it "requires a user" do
      get :graphiql
      expect(response.location).to match(%r{/login$})
    end

    it "works in production for normal users" do
      allow(Rails.env).to receive(:production?).and_return(true)
      user_session(@student)
      get :graphiql
      expect(response).to have_http_status :ok
    end

    it "works in production for site admins" do
      allow(Rails.env).to receive(:production?).and_return(true)
      site_admin_user(active_all: true)
      user_session(@user)
      get :graphiql
      expect(response).to have_http_status :ok
    end

    it "works" do
      user_session(@student)
      get :graphiql
      expect(response).to have_http_status :ok
    end
  end

  context "graphql, without a session" do
    it "requires a user" do
      post :execute, params: { query: "{}" }, format: :json
      expect(response).to be_unauthorized
    end
  end

  context "graphql" do
    before { user_session(@student) }

    it "works" do
      post :execute, params: { query: '{ course(id: "1") { id } }' }, format: :json
      expect(response.parsed_body["errors"]).to be_blank
      expect(response.parsed_body["data"]).not_to be_blank
    end

    context "CreateSubmission" do
      before do
        Setting.set("enable_page_views", "db")
        @course = course_factory(name: "course", active_course: true)
        student_in_course(active_all: true, course: @course)
        user_session(@student)

        @assignment = @course.assignments.create!(
          name: "assignment",
          due_at: 5.days.ago,
          points_possible: 10,
          submission_types: "online_text_entry"
        )

        @test_query = <<~GQL
          mutation CreateSubmission($assignmentLid: ID!, $type: OnlineSubmissionType!, $body: String!) {
            createSubmission(input: {
              assignmentId: $assignmentLid
              submissionType: $type
              body: $body
            }) {
              submission {
                _id
                attempt
              }
              errors {
                attribute
                message
              }
            }
          }
        GQL

        @test_variables = {
          assignmentLid: @assignment.id,
          body: "<p>test</p>",
          type: "online_text_entry"
        }

        # need this for the page view to be assigned a proper request_id
        RequestContext::Generator.new(->(_env) { [200, {}, []] }).call({})
      end

      it "logs a page view for CreateSubmission" do
        expect { post :execute, params: { query: @test_query, operationName: "CreateSubmission", variables: @test_variables }, format: :json }.to change { PageView.count }.by(1)

        expect(PageView.last.participated).to be(true)
      end

      it "does not log a page view for CreateSubmission when graphql error (user has no permission)" do
        usr = user_model
        user_session(usr)

        expect { post :execute, params: { query: @test_query, operationName: "CreateSubmission", variables: @test_variables }, format: :json }.not_to change { PageView.count }
      end

      it "does not log a page view for CreateSubmission if generic graphql error" do
        allow(GraphQLTuning).to receive(:max_complexity).and_return(1)

        expect { post :execute, params: { query: @test_query, operationName: "CreateSubmission", variables: @test_variables }, format: :json }.not_to change { PageView.count }
      end
    end

    context "discussions" do
      def mutation_str(
        discussion_topic_id: nil,
        message: nil
      )
        <<~GQL
          mutation {
            createDiscussionEntry(input: {
              discussionTopicId: #{discussion_topic_id}
              message: "#{message}"
              }) {
              discussionEntry {
                _id
                message
                parentId
                attachment {
                  _id
                }
              }
              errors {
                message
                attribute
              }
            }
          }
        GQL
      end

      def create_discussion_entry(message)
        post :execute,
             params: {
               query: mutation_str(discussion_topic_id: @topic.id, message:),
               operationName: "CreateDiscussionEntry",
               variables: {
                 courseID: @course.id,
                 discussionTopicId: @topic.id
               }
             },
             format: :json
      end

      it "increments participate_score on participate for DiscussionTopic" do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
        dt = discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })

        user_session(@student)

        create_discussion_entry("Post 1")
        expect(AssetUserAccess.last.participate_score).to eq 1.0

        create_discussion_entry("Post 2")
        expect(AssetUserAccess.last.participate_score).to eq 2.0

        dt.locked = true
        dt.save!
        create_discussion_entry("failure")
        expect(AssetUserAccess.last.participate_score).to eq 2.0
      end

      it "correctly sets the course context for a Live event" do
        allow(LiveEvents).to receive(:post_event)
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
        discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })

        user_session(@teacher)

        expect(LiveEvents).to receive(:post_event).with(hash_including({
                                                                         event_name: "discussion_entry_created"
                                                                       })) do |payload|
          # Add an expectation to check the context within the payload
          expect(payload[:text]).to eq("Post 1")
          expect(payload[:user_id]).to eq(@teacher.id.to_s)

          # The post_event method in the live_events.rb uses the materialized_context to set the liveEvent context before sending it
          # This only gets run if the LiveEvents is configured, so tests like this are only able to capture the information that goes to that method
          # This tests the context that the LiveEvent is set to right before it is sent out
          # The context must be retrieved here because it will get set to nil after the event is sent
          live_event_context = LiveEvents.get_context
          expect(live_event_context[:context_type]).to eq "Course"
          expect(live_event_context[:context_id]).to eq @course.id.to_s
          expect(live_event_context[:context_account_id]).to eq @course.account.id.to_s
        end

        create_discussion_entry("Post 1")
      end
    end

    context "datadog metrics" do
      before { allow(InstStatsd::Statsd).to receive(:increment).and_call_original }

      def expect_increment(metric, tags)
        expect(InstStatsd::Statsd).to have_received(:increment).with(metric, tags:)
      end

      context "for first-party queries" do
        def mark_first_party(request)
          request.headers["GraphQL-Metrics"] = "true"
        end

        it "counts each operation and query top-level field" do
          mark_first_party(request)
          test_query = <<~GQL
            query GetStuff {
              course(id: "1") { name }
              assignment(id: "1") { name }
              legacyNode(type: User, id: "1") {
                ... on User { email }
              }
            }
          GQL
          post :execute, params: { query: test_query }, format: :json
          expect_increment("graphql.operation.count", operation_name: "GetStuff")
          expect_increment("graphql.query.count", operation_name: "GetStuff", field: "course")
          expect_increment("graphql.query.count", operation_name: "GetStuff", field: "assignment")
          expect_increment("graphql.query.count", operation_name: "GetStuff", field: "legacyNode")
        end

        it "counts unnamed operations" do
          mark_first_party(request)
          test_query = <<~GQL
            query {
              course(id: "1") { name }
              assignment(id: "1") { name }
            }
          GQL
          post :execute, params: { query: test_query }, format: :json
          expect_increment("graphql.operation.count", operation_name: "unnamed")
          expect_increment("graphql.query.count", operation_name: "unnamed", field: "course")
          expect_increment("graphql.query.count", operation_name: "unnamed", field: "assignment")
        end

        it "counts each mutation top-level field" do
          mark_first_party(request)
          test_query = <<~GQL
            mutation {
              createAssignment(input: {courseId: "1", name: "Do my bidding"}) {
                assignment { name }
              }
              updateAssignment(input: {id: "1", name: "Do it good"}) {
                assignment { name }
              }
            }
          GQL
          post :execute, params: { query: test_query }, format: :json
          expect_increment("graphql.operation.count", operation_name: "unnamed")
          expect_increment("graphql.mutation.count", operation_name: "unnamed", field: "createAssignment")
          expect_increment("graphql.mutation.count", operation_name: "unnamed", field: "updateAssignment")
        end
      end

      context "for third-party queries" do
        it "names all operations '3rdparty' and omits hashes" do
          test_query = <<~GQL
            query GetStuff {
              course(id: "1") { name }
            }
          GQL
          post :execute, params: { query: test_query }, format: :json
          expect_increment("graphql.operation.count", operation_name: "3rdparty")
          expect_increment("graphql.query.count", operation_name: "3rdparty", field: "course")
        end
      end
    end

    context "get_context" do
      context "on creating submissions" do
        before do
          @course = Course.create!
          @assignment = @course.assignments.create!
        end

        it "sets context based on the course" do
          params = { operationName: "CreateSubmission", variables: { assignmentLid: @assignment.id } }
          expect { post :execute, params:, format: :json }.to change { subject.context }.from(nil).to(@course)
        end
      end

      context "on creating discussion entries" do
        before do
          @course = Course.create!
          @group = Group.create!(context: @course)

          @course_discussion_topic = DiscussionTopic.create!(context: @course)
          @group_discussion_topic = DiscussionTopic.create!(context: @group)
        end

        context "when the discussion is under a course" do
          it "sets context based on the course" do
            params = { operationName: "CreateDiscussionEntry", variables: { discussionTopicId: @course_discussion_topic.id } }
            expect { post :execute, params:, format: :json }.to change { subject.context }.from(nil).to(@course)
          end
        end

        context "when the discussion is under a group" do
          it "sets context based on the group" do
            params = { operationName: "CreateDiscussionEntry", variables: { discussionTopicId: @group_discussion_topic.id } }
            expect { post :execute, params:, format: :json }.to change { subject.context }.from(nil).to(@group)
          end
        end
      end

      context "on other operations" do
        it "does not change the context" do
          params = { operationName: "CreateDiscussionTopic" }
          expect { post :execute, params:, format: :json }.not_to change { subject.context }
        end
      end

      context "on invalid context objects" do
        before do
          allow(subject).to receive(:subject) { double("dummy subject", pick: ["User", 1]) }
        end

        it "raises an exception" do
          post :execute, format: :json
          expect(response).to have_http_status(:internal_server_error)
          expect(ErrorReport.last.message).to eq("Can not handle User in GraphQL context")
        end
      end
    end

    it "logs statsd metrics with correct complexity and operation name" do
      allow(GraphQLTuning).to receive(:max_complexity).and_return(1)
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      allow(InstStatsd::Statsd).to receive(:gauge)
      allow(controller).to receive(:operation_name).and_return("MyQuery")

      post :execute, params: { query: '{ course(id: "1") { id, name } }' }, format: :json

      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
        "graphql.errors.exceeds_max_complexity.count",
        tags: { operation_name: "MyQuery" }
      )
      expect(InstStatsd::Statsd).to have_received(:gauge).with(
        "graphql.errors.exceeds_max_complexity.compexity",
        3,
        tags: { operation_name: "MyQuery" }
      )
    end
  end

  context "with feature flag disable_graphql_authentication enabled" do
    context "graphql, without a session" do
      it "works" do
        Account.site_admin.enable_feature!(:disable_graphql_authentication)
        post :execute, params: { query: '{ course(id: "1") { id } }' }, format: :json
        expect(response.parsed_body["errors"]).to be_blank
        expect(response.parsed_body["data"]).not_to be_blank
      end
    end
  end

  describe "#execute error handling" do
    before do
      # Mock the schema execution to return custom error results
      allow_any_instance_of(GraphQLController).to receive(:execute_on) { mocked_result }
      user_session(@student)
    end

    context "when root errors are present" do
      let(:mocked_result) { { "errors" => [{ "message" => "Root error" }] } }

      it "returns root errors in the response" do
        post :execute, params: { query: "{ dummy }" }, format: :json
        expect(response.parsed_body["errors"]).to eq([{ "message" => "Root error" }])
      end
    end

    context "when nested data errors are present and no root errors" do
      let(:mocked_result) do
        {
          "data" => {
            "foo" => { "errors" => [{ "message" => "Nested error" }] },
            "bar" => { "errors" => [] },
            "baz" => { "value" => 1 },
            "qux" => "",
            "quux" => nil,
            "corge" => { "errors" => nil }
          }
        }
      end

      it "returns nested data errors in the response" do
        post :execute, params: { query: "{ dummy }" }, format: :json
        # The controller currently just renders the result, so errors will be in the data structure
        expect(response.parsed_body["data"]["foo"]["errors"]).to eq([{ "message" => "Nested error" }])
      end
    end
  end

  describe "request metrics tracking for execute action" do
    before do
      course_with_teacher(active_all: true)
      user_session(@teacher)
      allow(InstStatsd::Statsd).to receive(:timing)
      # Mock execute_on to return a simple successful result by default
      allow(@controller).to receive(:execute_on).and_return({ "data" => { "course" => { "name" => "Test Course" } } })
    end

    # Helper methods for consistent test setup
    def set_gradebook_headers(correlation_id: "test-correlation-id")
      request.env["HTTP_REFERER"] = "https://example.com/gradebook"
      request.env["HTTP_CORRELATION_ID"] = correlation_id
    end

    def set_non_gradebook_headers(correlation_id: "test-correlation-id")
      request.env["HTTP_REFERER"] = "https://example.com/other-page"
      request.env["HTTP_CORRELATION_ID"] = correlation_id
    end

    def make_graphql_request(operation_name, query = nil)
      query ||= "query #{operation_name} { course { assignments { id } } }"
      post :execute,
           params: {
             query:,
             operationName: operation_name
           },
           format: :json
    end

    def expect_metrics_sent_with(expected_tags = {})
      expect(InstStatsd::Statsd).to have_received(:timing).with(
        "canvas.controller.request_time",
        be_a(Float),
        tags: {
          controller: "graphql",
          action: "execute",
          method: "post",
          domain: be_a(String),
          referer: "/gradebook",
          correlation_id: "test-correlation-id",
        }.merge(expected_tags)
      )
    end

    def expect_no_metrics_sent
      expect(InstStatsd::Statsd).not_to have_received(:timing).with("canvas.controller.request_time", any_args)
    end

    def mock_graphql_root_errors
      allow(@controller).to receive(:execute_on).and_return({
                                                              "data" => nil,
                                                              "errors" => [{ "message" => "Field 'assignments' doesn't exist on type 'Course'" }]
                                                            })
    end

    def mock_graphql_nested_errors
      allow(@controller).to receive(:execute_on).and_return({
                                                              "data" => {
                                                                "course" => {
                                                                  "errors" => [{ "message" => "Permission denied" }]
                                                                }
                                                              }
                                                            })
    end

    context "when tracking conditions are met" do
      it "sends success metrics for tracked GraphQL operations" do
        set_gradebook_headers

        make_graphql_request("getAssignments")

        expect_metrics_sent_with(
          status: "success",
          operation_name: "getAssignments"
        )
      end

      %w[getAssignments getAssignmentGroups getUsers getEnrollments getSubmissions].each do |operation|
        it "sends metrics for tracked operation: #{operation}" do
          set_gradebook_headers

          make_graphql_request(operation)

          expect_metrics_sent_with(
            operation_name: operation,
            status: "success"
          )
        end
      end
    end

    context "when tracking conditions are not met" do
      it "does not send metrics for untracked GraphQL operations" do
        set_gradebook_headers

        make_graphql_request("untrackedOperation", "query untrackedOperation { course { name } }")

        expect_no_metrics_sent
      end

      it "does not send metrics without gradebook referer" do
        set_non_gradebook_headers

        make_graphql_request("getAssignments")

        expect_no_metrics_sent
      end

      it "does not send metrics without correlation_id" do
        request.env["HTTP_REFERER"] = "https://example.com/gradebook"

        make_graphql_request("getAssignments")

        expect_no_metrics_sent
      end
    end

    context "when request fails with exception" do
      it "sends error metrics for Ruby exceptions" do
        set_gradebook_headers
        allow(@controller).to receive(:execute_on).and_raise(StandardError, "test error")

        # The exception may be rescued by Rails, so we don't expect it to propagate
        # but we should still get error metrics
        begin
          make_graphql_request("getAssignments")
        rescue
          # Exception may or may not propagate depending on Rails rescue handling
        end

        expect_metrics_sent_with(
          status: "error",
          error_type: "StandardError",
          operation_name: "getAssignments"
        )
      end

      it "sends error metrics for GraphQL root-level errors" do
        set_gradebook_headers
        mock_graphql_root_errors

        make_graphql_request("getAssignments")

        expect_metrics_sent_with(
          status: "error",
          error_type: "GraphQLController::GraphQLError",
          operation_name: "getAssignments"
        )
      end

      it "sends error metrics for GraphQL nested errors" do
        set_gradebook_headers
        mock_graphql_nested_errors

        make_graphql_request("getAssignments")

        expect_metrics_sent_with(
          status: "error",
          error_type: "GraphQLController::GraphQLError",
          operation_name: "getAssignments"
        )
      end
    end
  end
end
