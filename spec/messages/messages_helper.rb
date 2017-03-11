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

module MessagesCommon
  def generate_message(notification_name, path_type, *)
    message = super
    expect(message.body).not_to be_nil
    if path_type == :email
      expect(message.subject).not_to be_nil
      expect(message.url).not_to be_nil
    elsif path_type == :twitter
      expect(message.main_link).to be_present
    end
    message
  end
end

shared_examples_for "a message" do
  include MessagesCommon

  def message_data_with_default
    if self.respond_to?(:message_data)
      message_data
    else
      {}
    end
  end

  context ".email" do
    let(:path_type) { :email }
    it "should render" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  context ".sms" do
    let(:path_type) { :sms }
    it "should render" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  context ".summary" do
    let(:path_type) { :summary }
    it "should render" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  context ".twitter" do
    let(:path_type) { :twitter }
    it "should render" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  context ".push" do
    let(:path_type) { :push }
    it "should render" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end
end
