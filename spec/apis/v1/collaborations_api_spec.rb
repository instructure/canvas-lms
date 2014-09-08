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
#

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe CollaborationsController, type: :request do
  before :once do
    PluginSetting.new(:name => 'etherpad', :settings => {}).save!
    course_with_teacher(:active_all => true)
    @members = (1..5).map do
      user = user_with_pseudonym(:active_all => true)
      @course.enroll_student(user).accept!
      user
    end
    collaboration_model(:user => @teacher, :context => @course)
    @user = @teacher
    @collaboration.update_members(@members)
  end

  context '/api/v1/collaborations/:id/members' do
    let(:url) { "/api/v1/collaborations/#{@collaboration.to_param}/members.json" }
    let(:url_options) { { :controller => 'collaborations',
                          :action     => 'members',
                          :id         => @collaboration.to_param,
                          :format     => 'json' } }

    describe 'a group member' do
      it 'should see group members' do
        json = api_call(:get, url, url_options)
        json.count.should == 6
      end

      it 'should receive a paginated response' do
        json = api_call(:get, "#{url}?per_page=1", url_options.merge(:per_page => '1'))
        json.count.should == 1
      end

      it 'should be formatted by collaborator_json' do
        json = api_call(:get, url, url_options)
        json.first.keys.sort.should == %w{collaborator_id id name type}
      end

      it 'should include groups' do
        group_model(:context => @course)
        Collaborator.create!(:user => nil, :group => @group, :collaboration => @collaboration)
        users, groups = api_call(:get, url, url_options).partition { |c| c['type'] == 'user' }
        users.length.should == 6
        groups.length.should == 1
        groups.first['collaborator_id'].should == @group.id
      end
    end

    describe 'a non-group member' do
      before(:each) do
        user
      end

      it 'should receive a 401' do
        raw_api_call(:get, url, url_options)
        response.code.should == '401'
      end
    end
  end
end
