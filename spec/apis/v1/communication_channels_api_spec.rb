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

describe 'CommunicationChannels API', :type => :integration do
  describe 'index' do
    before do
      @someone = user_with_pseudonym
      @admin   = user_with_pseudonym

      Account.site_admin.add_user(@admin)

      @path = "/api/v1/users/#{@someone.id}/communication_channels"
      @path_options = { :controller => 'communication_channels',
        :action => 'index', :format => 'json', :user_id => @someone.id.to_param }
    end

    context 'an authorized user' do
      it 'should list all channels' do
        json = api_call(:get, @path, @path_options)

        cc = @someone.communication_channel
        json.should eql [{
          'id'       => cc.id,
          'address'  => cc.path,
          'type'     => cc.path_type,
          'position' => cc.position,
          'user_id'  => cc.user_id }]
      end
    end

    context 'an unauthorized user' do
      it 'should return 401' do
        user_with_pseudonym
        raw_api_call(:get, @path, @path_options)
        response.code.should eql '401'
      end

      it "should not list channels for a teacher's students" do
        course_with_teacher
        @course.enroll_student(@someone)
        @user = @teacher

        raw_api_call(:get, @path, @path_options)
        response.code.should eql '401'
      end
    end
  end
end
