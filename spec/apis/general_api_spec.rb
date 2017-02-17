#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')

describe "API", type: :request do
  describe "Api::V1::Json" do
    it "should merge user options with the default api behavior" do
      obj = Object.new
      obj.extend Api::V1::Json
      course_with_teacher
      session = mock()
      @course.expects(:as_json).with({ :include_root => false, :permissions => { :user => @user, :session => session, :include_permissions => false }, :only => [ :name, :sis_source_id ] })
      obj.api_json(@course, @user, session, :only => [:name, :sis_source_id])
    end

    it "should accept a block to add serialized field data" do
      # DON'T use Object here; injecting Object will have ramifications in-memory for the entire test suite.
      class MockedAPIObject < Object; end
      obj = MockedAPIObject.new
      obj.class.module_eval { attr_accessor :serialized, :name }

      obj.name = "Some Object"
      obj.serialized = {:nested_key => "foo"}

      obj.extend Api::V1::Json
      course_with_teacher
      session = mock()

      json_hash = obj.api_json(@course, @user, session, :only => [:name]) do |json, object|
        json.mapped_value = obj.serialized[:nested_key]
      end

      expect(json_hash).to have_key(:mapped_value)
      expect(json_hash[:mapped_value]).to eq "foo"
    end
  end

  describe "as_json extensions" do
    it "should skip attribute filtering if obj doesn't respond" do
      course_with_teacher
      expect(@course.respond_to?(:filter_attributes_for_user)).to be_truthy
      expect(@course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort).to eq %w(name permissions sis_source_id)
    end

    it "should do attribute filtering if obj responds" do
      course_with_teacher
      @course.send(:extend, RSpec::Matchers)
      def @course.filter_attributes_for_user(hash, user, session)
        expect(user).to eq self.teachers.first
        expect(session).to be_nil
        hash.delete('sis_source_id')
      end
      expect(@course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort).to eq %w(name permissions)
    end

    it "should not return the permissions list if include_permissions is false" do
      course_with_teacher
      expect(@course.as_json(:include_root => false, :permissions => { :user => @user, :include_permissions => false }, :only => %w(name sis_source_id)).keys.sort).to eq %w(name sis_source_id)
    end

    it "should serialize permissions if obj responds" do
      course_with_teacher
      expect(@course).to receive(:serialize_permissions).once.with(anything, @teacher, nil)
      json = @course.as_json(:include_root => false, :permissions => { :user => @user, :session => nil, :include_permissions => true, :policies => [ "update" ] }, :only => %w(name))
      expect(json.keys.sort).to eq %w(name permissions)
    end
  end

  describe "json post format" do
    before :once do
      course_with_teacher(:user => user_with_pseudonym, :active_all => true)
      @token = @user.access_tokens.create!(:purpose => "specs")
    end

    it "should use html form encoding by default" do
      html_request = "assignment[name]=test+assignment&assignment[points_possible]=15"
      # no content-type header is sent
      post "/api/v1/courses/#{@course.id}/assignments", html_request, { "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      expect(response).to be_success
      expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'

      @assignment = @course.assignments.order(:id).last
      expect(@assignment.title).to eq "test assignment"
      expect(@assignment.points_possible).to eq 15
    end

    it "should support json POST request bodies" do
      json_request = { "assignment" => { "name" => "test assignment", "points_possible" => 15 } }
      post "/api/v1/courses/#{@course.id}/assignments", json_request.to_json, { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      expect(response).to be_success
      expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'

      @assignment = @course.assignments.order(:id).last
      expect(@assignment.title).to eq "test assignment"
      expect(@assignment.points_possible).to eq 15
    end

    it "should use array params without the [] on the key" do
      assignment_model(:course => @course, :submission_types => 'online_upload')
      @user = user_with_pseudonym
      course_with_student(:course => @course, :user => @user, :active_all => true)
      @token = @user.access_tokens.create!(:purpose => "specs")
      a1 = attachment_model(:context => @user)
      a2 = attachment_model(:context => @user)
      json_request = { "comment" => {
                          "text_comment" => "yay" },
                       "submission" => {
                          "submission_type" => "online_upload",
                          "file_ids" => [a1.id, a2.id] } }
      post "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions", json_request.to_json, { "CONTENT_TYPE" => "application/json", "HTTP_AUTHORIZATION" => "Bearer #{@token.full_token}" }
      expect(response).to be_success
      expect(response.header[content_type_key]).to eq 'application/json; charset=utf-8'

      @submission = @assignment.submissions.where(user_id: @user).first
      expect(@submission.attachments.map { |a| a.id }.sort).to eq [a1.id, a2.id]
      expect(@submission.submission_comments.first.comment).to eq "yay"
    end
  end

  describe "application/json+canvas-string-ids" do
    it "should stringify fields with Accept header" do
      account = Account.default.sub_accounts.create!
      account_admin_user(active_all: true, account: account)
      json = api_call(:get, "/api/v1/accounts/#{account.id}",
        { controller: 'accounts', action: 'show', id: account.to_param, format: 'json' },
        {}, { 'Accept' => 'application/json+canvas-string-ids' })
      expect(json['id']).to eq account.id.to_s
      expect(json['root_account_id']).to eq Account.default.id.to_s
    end

    it "should not stringify fields without Accept header" do
      account = Account.default.sub_accounts.create!
      account_admin_user(active_all: true, account: account)
      json = api_call(:get, "/api/v1/accounts/#{account.id}",
        { controller: 'accounts', action: 'show', id: account.to_param, format: 'json' })
      expect(json['id']).to eq account.id
      expect(json['root_account_id']).to eq Account.default.id
    end
  end
end
