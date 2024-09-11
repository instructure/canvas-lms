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

describe GraphQLController do
  before :once do
    student_in_course(user: user_with_pseudonym)
  end

  let(:federation_query_params) do
    {
      query: "query ($representations: [_Any!]!) { _entities(representations: $representations) { ...on Course { name } } }",
      variables: {
        representations: [{ __typename: "Course", id: "Q291cnNlLTE=" }]
      }
    }
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

    it "does not handle Apollo Federation queries" do
      post :execute, params: federation_query_params, format: :json
      expect(response.parsed_body["errors"]).not_to be_blank
      expect(response.parsed_body["data"]).to be_blank
    end

    it "logs a page view for CreateSubmission" do
      Setting.set("enable_page_views", "db")
      @course = course_factory(name: "course", active_course: true)

      @assignment = @course.assignments.create!(
        name: "assignment",
        due_at: 5.days.ago,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      test_query = <<~GQL
        mutation {
          CreateSubmission(input: {assignmentId: $assignmentLid, submissionType: $type, body: $body})
      GQL

      test_variables = {
        assignmentLid: @assignment.id,
        body: "<p>test</p>",
        type: "online_text_entry"
      }
      # need this for the page view to be assigned a proper request_id
      RequestContext::Generator.new(->(_env) { [200, {}, []] }).call({})

      expect { post :execute, params: { query: test_query, operationName: "CreateSubmission", variables: test_variables }, format: :json }.to change { PageView.count }.by(1)

      expect(PageView.last.participated).to be(true)
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
        discussion_topic_model({ context: @course, discussion_type: DiscussionTopic::DiscussionTypes::THREADED })

        user_session(@student)

        create_discussion_entry("Post 1")
        expect(AssetUserAccess.last.participate_score).to eq 1.0

        create_discussion_entry("Post 2")
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
  end

  describe "subgraph_execute" do
    context "with authentication" do
      around do |example|
        InstAccess.with_config(signing_key: signing_priv_key, &example)
      end

      let(:token_signing_keypair) { OpenSSL::PKey::RSA.new(2048) }
      let(:signing_priv_key) { token_signing_keypair.to_s }
      let(:token) { InstAccess::Token.for_user(user_uuid: @student.uuid, account_uuid: @student.account.uuid) }

      it "handles standard queries" do
        request.headers["Authorization"] = "Bearer #{token.to_unencrypted_token_string}"
        post :subgraph_execute, params: { query: '{ course(id: "1") { id } }' }, format: :json
        expect(response.parsed_body["errors"]).to be_blank
        expect(response.parsed_body["data"]).not_to be_blank
      end

      it "handles Apollo Federation queries" do
        request.headers["Authorization"] = "Bearer #{token.to_unencrypted_token_string}"
        post :subgraph_execute, params: federation_query_params, format: :json
        expect(response.parsed_body["errors"]).to be_blank
      end
    end

    describe "without authentication" do
      it "services subgraph introspection queries" do
        post :subgraph_execute, params: { query: "query FederationSubgraphIntrospection { _service { sdl } }" }, format: :json
        expect(response.parsed_body["errors"]).to be_blank
        expect(response.parsed_body["data"]).not_to be_blank
      end

      it "rejects other queries" do
        post :subgraph_execute, params: federation_query_params, format: :json
        expect(response).to be_unauthorized
      end
    end
  end

  context "with feature flag disable_graphql_authentication enabled" do
    context "graphql, without a session" do
      it "works" do
        expect(Account.site_admin).to(
          receive(:feature_enabled?).with(:disable_graphql_authentication).and_return(true)
        )
        post :execute, params: { query: '{ course(id: "1") { id } }' }, format: :json
        expect(response.parsed_body["errors"]).to be_blank
        expect(response.parsed_body["data"]).not_to be_blank
      end
    end
  end
end
