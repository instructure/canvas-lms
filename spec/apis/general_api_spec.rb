#
# Copyright (C) 2011 Instructure, Inc.
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

describe "API", :type => :integration do
  describe "Api::V1::Json" do
    it "should merge user options with the default api behavior" do
      obj = Object.new
      obj.extend Api::V1::Json
      course_with_teacher
      session = mock()
      @course.expects(:as_json).with({ :include_root => false, :permissions => { :user => @user, :session => session, :include_permissions => false }, :only => [ :name, :sis_source_id ] })
      obj.api_json(@course, @user, session, :only => [:name, :sis_source_id])
    end
  end

  describe "as_json extensions" do
    it "should skip attribute filtering if obj doesn't respond" do
      course_with_teacher
      @course.respond_to?(:filter_attributes_for_user).should be_false
      @course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort.should == %w(name permissions sis_source_id)
    end

    it "should do attribute filtering if obj responds" do
      course_with_teacher
      def @course.filter_attributes_for_user(hash, user, session)
        user.should == self.teachers.first
        session.should == nil
        hash.delete('sis_source_id')
      end
      @course.as_json(:include_root => false, :permissions => { :user => @user }, :only => %w(name sis_source_id)).keys.sort.should == %w(name permissions)
    end

    it "should not return the permissions list if include_permissions is false" do
      course_with_teacher
      @course.as_json(:include_root => false, :permissions => { :user => @user, :include_permissions => false }, :only => %w(name sis_source_id)).keys.sort.should == %w(name sis_source_id)
    end
  end

  describe "json post format" do
    before do
      course_with_teacher(:user => user_with_pseudonym, :active_all => true)
      @token = @user.access_tokens.create!(:purpose => "specs")
    end

    it "should use html form encoding by default" do
      html_request = "assignment[name]=test+assignment&assignment[points_possible]=15"
      # no content-type header is sent
      post "/api/v1/courses/#{@course.id}/assignments", html_request, { "authorization" => "Bearer #{@token.token}" }
      response.should be_success
      response.header['content-type'].should == 'application/json; charset=utf-8'

      @assignment = @course.assignments.last(:order => :id)
      @assignment.title.should == "test assignment"
      @assignment.points_possible.should == 15
    end

    it "should support json POST request bodies" do
      json_request = { "assignment" => { "name" => "test assignment", "points_possible" => 15 } }
      post "/api/v1/courses/#{@course.id}/assignments", json_request.to_json, { "content-type" => "application/json", "authorization" => "Bearer #{@token.token}" }
      response.should be_success
      response.header['content-type'].should == 'application/json; charset=utf-8'

      @assignment = @course.assignments.last(:order => :id)
      @assignment.title.should == "test assignment"
      @assignment.points_possible.should == 15
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
      post "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions", json_request.to_json, { "content-type" => "application/json", "authorization" => "Bearer #{@token.token}" }
      response.should be_success
      response.header['content-type'].should == 'application/json; charset=utf-8'

      @submission = @assignment.submissions.find_by_user_id(@user.id)
      @submission.attachments.map { |a| a.id }.sort.should == [a1.id, a2.id]
      @submission.submission_comments.first.comment.should == "yay"
    end
  end
end
