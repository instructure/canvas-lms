# frozen_string_literal: true

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

module MessagesCommon
  def generate_message(notification_name, path_type, *)
    message = super
    expect(message.body).not_to be_nil
    case path_type
    when :email
      expect(message.subject).not_to be_nil
      expect(message.url).not_to be_nil
    end
    message
  end
end

shared_examples_for "a message" do
  include MessagesCommon

  def message_data_with_default
    if respond_to?(:message_data)
      message_data
    else
      {}
    end
  end

  describe ".email" do
    let(:path_type) { :email }

    it "renders" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  describe ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  describe ".summary" do
    let(:path_type) { :summary }

    it "renders" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end

  describe ".push" do
    let(:path_type) { :push }

    it "renders" do
      generate_message(notification_name, path_type, asset, message_data_with_default)
    end
  end
end
