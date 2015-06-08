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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

include Api::V1::Conferences
include Api::V1::Json
include Api

describe "Conferences API", type: :request do
  before :once do
    # these specs need an enabled web conference plugin
    @plugin = PluginSetting.create!(name: 'wimba')
    @plugin.update_attribute(:settings, { :domain => 'wimba.test' })
    @category_path_options = { :controller => "conferences", :format => "json" }
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
    @user = @teacher
  end

  describe "GET list of conferences" do

    it "should require authorization" do
      @user = nil
      raw_api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options.
        merge(action: 'index', course_id: @course.to_param))
      expect(response.code).to eq '401'
    end

    it "should list all the conferences" do
      @conferences = (1..2).map { |i| @course.web_conferences.create!(:conference_type => 'Wimba',
                                                                      :duration => 60,
                                                                      :user => @teacher,
                                                                      :title => "Wimba #{i}")}

      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options.
        merge(action: 'index', course_id: @course.to_param))
      expect(json).to eq api_conferences_json(@conferences.reverse.map{|c| WebConference.find(c.id)}, @course, @user)
    end

    it "should not list conferences for disabled plugins" do
      plugin = PluginSetting.create!(name: 'adobe_connect')
      plugin.update_attribute(:settings, { :domain => 'adobe_connect.test' })
      @conferences = ['AdobeConnect', 'Wimba'].map {|ct| @course.web_conferences.create!(:conference_type => ct,
                                                                                         :duration => 60,
                                                                                         :user => @teacher,
                                                                                         :title => ct)}
      plugin.disabled = true
      plugin.save!
      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options.
        merge(action: 'index', course_id: @course.to_param))
      expect(json).to eq api_conferences_json([WebConference.find(@conferences[1].id)], @course, @user)
    end

    it "should only list conferences the user is a participant of" do
      @user = @student
      @conferences = (1..2).map { |i| @course.web_conferences.create!(:conference_type => 'Wimba',
                                                                      :duration => 60,
                                                                      :user => @teacher,
                                                                      :title => "Wimba #{i}")}
      @conferences[0].users << @user
      @conferences[0].save!
      json = api_call(:get, "/api/v1/courses/#{@course.to_param}/conferences", @category_path_options.
        merge(action: 'index', course_id: @course.to_param))
      expect(json).to eq api_conferences_json([WebConference.find(@conferences[0].id)], @course, @user)
    end

    it 'should get a conferences for a group' do
      @user = @student
      @group = @course.groups.create!(:name => "My Group")
      @group.add_user(@student, 'accepted', true)
      @conferences = (1..2).map { |i| @group.web_conferences.create!(:conference_type => 'Wimba',
                                                                      :duration => 60,
                                                                      :user => @teacher,
                                                                      :title => "Wimba #{i}")}
      json = api_call(:get, "/api/v1/groups/#{@group.to_param}/conferences", @category_path_options.
        merge(action: 'index', group_id: @group.to_param))
      expect(json).to eq api_conferences_json(@conferences.reverse.map{|c| WebConference.find(c.id)}, @group, @student)
    end
  end

  describe "POST 'recording_ready'" do
    before do
      WebConference.stubs(:plugins).returns([
        web_conference_plugin_mock("big_blue_button", {
          :domain => "bbb.instructure.com",
          :secret_dec => "secret",
        })
      ])
    end

    let(:conference) do
      BigBlueButtonConference.create!(context: course,
                                      user: user,
                                      conference_key: "conf_key")
    end

    let(:course_id) { conference.context.id }

    let(:path) do
      "api/v1/courses/#{course_id}/conferences/#{conference.id}/recording_ready"
    end

    let(:params) do
      @category_path_options.merge(action: 'recording_ready',
                                   course_id: course_id,
                                   conference_id: conference.id)
    end

    it 'should mark the recording as ready' do
      payload = {meeting_id: conference.conference_key}
      body_params = {signed_parameters: JWT.encode(payload, conference.config[:secret_dec])}

      raw_api_call(:post, path, params, body_params)
      expect(response.status).to eq 202
    end

    it 'should error if the secret key is wrong' do
      payload = {meeting_id: conference.conference_key}
      body_params = {signed_parameters: JWT.encode(payload, "wrong_key")}

      raw_api_call(:post, path, params, body_params)
      expect(response.status).to eq 401
    end

    it 'should error if the conference_key is wrong' do
      payload = {meeting_id: "wrong_conference_key"}
      body_params = {signed_parameters: JWT.encode(payload, conference.config[:secret_dec])}

      raw_api_call(:post, path, params, body_params)
      expect(response.status).to eq 422
    end
  end
end
