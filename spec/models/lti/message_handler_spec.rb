#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Lti
  describe MessageHandler do

    describe 'validations' do
      before(:each) do
        subject.message_type = 'message_type'
        subject.launch_path = 'launch_path'
        subject.resource = ResourceHandler.new
      end

      it 'requires the message type' do
        subject.message_type = nil
        subject.save
        subject.errors.first.should == [:message_type, "can't be blank"]
      end

      it 'requires the launch path' do
        subject.launch_path = nil
        subject.save
        subject.errors.first.should == [:launch_path, "can't be blank"]
      end

      it 'requires a resource_handler' do
        subject.resource = nil
        subject.save
        subject.errors.first.should == [:resource, "can't be blank"]
      end

    end


  end
end