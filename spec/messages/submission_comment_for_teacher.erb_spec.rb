#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe 'submission_comment_for_teacher' do
  before :once do
    submission_model
    @comment = @submission.add_comment(:comment => "new comment")
  end

  let(:asset) { @comment }
  let(:notification_name) { :submission_comment_for_teacher }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "should render" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.url).to match(/\/courses\/\d+\/assignments\/\d+\/submissions\/\d+/)
      expect(msg.body.include?("new comment on the submission")).to eq true
    end

    it "should render correct footer if replys are enabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("responding to this message")).to eq true
    end

    it "should render correct footer if replys are disabled" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = false
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body.include?("responding to this message")).to eq false
    end
  end
end
