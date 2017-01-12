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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'submission_comment.sms' do

  before :each do
    submission_model
    @object = @submission.add_comment(:comment => "new comment")
    expect(@object.submission).not_to be_nil
    expect(@object.submission.assignment).not_to be_nil
    expect(@object.submission.assignment.context).not_to be_nil
    expect(@object.submission.user).not_to be_nil
  end

  it "should render" do
    message = generate_message(:submission_comment, :sms, @object)
    expect(message.body).to_not include('Anonymous User')
  end

  it 'should show anonymous when anonymous peer review enabled' do
    @submission.assignment.update_attribute(:anonymous_peer_reviews, true)
    @object.reload
    message = generate_message(:submission_comment, :sms, @object)
    expect(message.body).to include('Anonymous User')
  end

end
