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

require_relative "messages_helper"

describe "new_files_added" do
  before :once do
    attachment_model
  end

  file_names = ["file1.txt", "file2.txt", "file3.txt", "file4.txt", "file5.txt"]

  let(:asset) { @attachment }
  let(:message_data) { { data: { count: 5, display_names: file_names } } }
  let(:notification_name) { :new_files_added }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "only displays max_displayed" do
      stub_const("Attachment::NOTIFICATION_MAX_DISPLAY", 4)
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.body).not_to include("file5.txt")
    end
  end
end
