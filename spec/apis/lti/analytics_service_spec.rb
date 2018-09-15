#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

# https://github.com/adlnet/xAPI-Spec/blob/master/xAPI.md

describe LtiApiController, type: :request do
  before :once do
    course_with_student(:active_all => true)
    @student = @user
    @course.enroll_teacher(user_with_pseudonym(:active_all => true))
    @tool = @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'my analytics test tool', :domain => 'example.com')
    assignment_model(:course => @course, :name => 'tool assignment', :submission_types => 'external_tool', :points_possible => 20, :grading_type => 'points')
    tag = @assignment.build_external_tool_tag(:url => "http://example.com/one")
    tag.content_type = 'ContextExternalTool'
    tag.save!
    @token = Lti::AnalyticsService.create_token(@tool, @student, @course)
  end

  def make_call(opts = {})
    opts['path'] ||= "/api/lti/v1/xapi/#{@token}"
    opts['key'] ||= @tool.consumer_key
    opts['secret'] ||= @tool.shared_secret
    opts['content-type'] ||= 'application/json'
    consumer = OAuth::Consumer.new(opts['key'], opts['secret'], :site => "https://www.example.com", :signature_method => "HMAC-SHA1")
    req = consumer.create_signed_request(:post, opts['path'], nil, :scheme => 'header', :timestamp => opts['timestamp'], :nonce => opts['nonce'])
    req.body = JSON.generate(opts['body']) if opts['body']
    post "https://www.example.com#{req.path}",
      params: req.body,
      headers: { "CONTENT_TYPE" => opts['content-type'], "HTTP_AUTHORIZATION" => req['Authorization'] }
  end

  context 'xAPI' do
    it "should require a content-type of application/json" do
      make_call('content-type' => 'application/xml')
      assert_status(415)
    end

    it "should require the correct shared secret" do
      make_call('secret' => 'bad secret is bad')
      assert_status(401)
    end

    def xapi_body
      # https://github.com/adlnet/xAPI-Spec/blob/master/xAPI.md#AppendixA
      {
              id: "12345678-1234-5678-1234-567812345678",
              actor: {
                      account: {
                              homePage: "http://www.instructure.com/",
                              name: '123somemagicguid'
                      }
              },
              verb: {
                      id: "http://adlnet.gov/expapi/verbs/interacted",
                      display: {
                              "en-US" => "interacted"
                      }
              },
              object: {
                      id: "http://example.com/"
              },
              result: {
                      duration: "PT10M0S"
              }
      }
    end

    it "should increment activity time" do
      e = Enrollment.where(user_id: @student, course_id: @course).first
      previous_time = e.total_activity_time

      make_call('body' => xapi_body)
      expect(response).to be_successful

      expect(e.reload.total_activity_time).to eq previous_time + 600
    end

    it "should create an asset user access" do
      accesses = AssetUserAccess.where(user_id: @student)
      previous_count = accesses.count

      make_call('body' => xapi_body)

      expect(accesses.reload.count).to eq previous_count + 1
    end

    describe "page view creation" do
      before { Setting.set 'enable_page_views', 'db' }

      it "should include url and interaction_seconds" do
        page_views = PageView.where(user_id: @student, context_id: @course, context_type: 'Course')
        previous_count = page_views.count
        body = xapi_body

        make_call('body' => body)

        expect(page_views.reload.count).to eq previous_count + 1

        page_view = page_views.last
        expect(page_view.url).to eq body[:object][:id]
        expect(page_view.interaction_seconds).to eq 600
      end
    end

    it "should handle requests without durations" do
      body = xapi_body
      body.delete(:result)
      make_call('body' => body)
      expect(response).to be_successful
    end
  end

  context 'caliper' do

    it "should require the correct shared secret" do
      make_call('secret' => 'bad secret is bad', 'path' => "/api/lti/v1/caliper/#{@token}")
      assert_status(401)
    end

    def caliper_body
      {
              "@context" => "http://purl.imsglobal.org/ctx/caliper/v1/ViewEvent",
              "@type" => "http://purl.imsglobal.org/caliper/v1/ViewEvent",
              "action" => "viewed",
              "startedAtTime" => Time.now.utc.to_i,
              "duration" => "PT10M0S",
              "actor" => {
                      "@id" => '123somemagicguid',
                      "@type" => "http://purl.imsglobal.org/caliper/v1/lis/Person"
              },
              "object" => {
                      "@id" => "http://www.instructure.com/",
                      "@type" => "http://www.idpf.org/epub/vocab/structure/#volume",
                      "name" => "Test LTI Tool"
              },
              "edApp" => {
                      "@id" => "http://www.instructure.com/",
                      "@type" => "http://purl.imsglobal.org/caliper/v1/SoftwareApplication",
                      "name" => "LTI Tool of All Things",
                      "properties" => {},
                      "lastModifiedTime" => Time.now.utc.to_i
              }
      }
    end

    it "should increment activity time" do
      e = Enrollment.where(user_id: @student, course_id: @course).first
      previous_time = e.total_activity_time

      make_call('body' => caliper_body, 'path' => "/api/lti/v1/caliper/#{@token}")
      expect(response).to be_successful

      expect(e.reload.total_activity_time).to eq previous_time + 600
    end

    it "should not increment activity time for different event types" do
      e = Enrollment.where(user_id: @student, course_id: @course).first
      previous_time = e.total_activity_time
      body = caliper_body
      body['@type'] = 'did_not_view'

      make_call('body' => body, 'path' => "/api/lti/v1/caliper/#{@token}")
      expect(response).to be_successful

      expect(e.reload.total_activity_time).to eq previous_time
    end

    it "should create an asset user access" do
      accesses = AssetUserAccess.where(user_id: @student)
      previous_count = accesses.count

      make_call('body' => caliper_body, 'path' => "/api/lti/v1/caliper/#{@token}")

      expect(accesses.reload.count).to eq previous_count + 1
    end

    describe "page view creation" do
      before { Setting.set 'enable_page_views', 'db' }

      it "should include url and interaction_seconds" do
        page_views = PageView.where(user_id: @student, context_id: @course, context_type: 'Course')
        previous_count = page_views.count
        body = caliper_body

        make_call('body' => body, 'path' => "/api/lti/v1/caliper/#{@token}")

        expect(page_views.reload.count).to eq previous_count + 1

        page_view = page_views.last
        expect(page_view.url).to eq body['object']['@id']
        expect(page_view.interaction_seconds).to eq 600
      end
    end

    it "should handle requests without durations" do
      body = caliper_body
      body.delete('duration')
      make_call('body' => body, 'path' => "/api/lti/v1/caliper/#{@token}")
      expect(response).to be_successful
    end
  end

end
