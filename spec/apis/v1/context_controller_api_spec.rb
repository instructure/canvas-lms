# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
describe ContextController, type: :request do
  before :once do
    course_with_teacher(:active_all => true)
    student_in_course(:active_all => true)
  end

  describe "POST '/api/v1/media_objects'" do
    before :each do
      user_session(@student)
    end

    it "should match the create_media_object api route" do
      assert_recognizes({:controller => 'context', :action => 'create_media_object', 'format'=>'json'}, {:path => 'api/v1/media_objects', :method => :post})
    end

    it "should create the object if it doesn't already exist" do
      @original_count = @user.media_objects.count
      allow_any_instance_of(MediaObject).to receive(:media_sources).and_return("stub")

      json = api_call(:post, "/api/v1/media_objects",
        { :controller => 'context', :action => 'create_media_object', :format => 'json', :context_code => "user_#{@user.id}",
        :id => "new_object",
        :type => "audio",
        :title => "title"})
      @user.reload
      expect(@user.media_objects.count).to eq @original_count + 1
      @media_object = @user.media_objects.last

      expect(@media_object.media_id).to eq "new_object"
      expect(@media_object.media_type).to eq "audio"
      expect(@media_object.title).to eq "title"
      expect(json["media_object"]["id"]).to eq @media_object.id
      expect(json["media_object"]["title"]).to eq @media_object.title
      expect(json["media_object"]["media_type"]).to eq @media_object.media_type
    end
  end
end
