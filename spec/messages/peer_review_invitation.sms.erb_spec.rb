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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'peer_review_invitation.sms' do

  before :each do
    assessment_request_model
    @object = @assessment_request
    @object.reload
    expect(@object.context).not_to be_nil
  end

  it "should render" do
    message = generate_message(:peer_review_invitation, :sms, @object)
    expect(message.body).to_not include('Anonymous User')
  end

  it 'should show anonymous when anonymous peer review enabled' do
    assignment = @assessment_request.asset.assignment
    assignment.update_attribute(:anonymous_peer_reviews, true)
    @object.reload
    message = generate_message(:peer_review_invitation, :sms, @object)
    expect(message.body).to include('Anonymous User')
  end

end
