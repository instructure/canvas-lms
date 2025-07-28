# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe "assignment_changed" do
  include MessagesCommon

  before :once do
    assignment_model(title: "Quiz 1")
  end

  let(:notification_name) { :assignment_changed }
  let(:asset) { @assignment }

  describe ".email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to match(/Quiz 1/)
      expect(msg.body).to match(/Quiz 1/)
      expect(msg.body).to match(Regexp.new(@course.name))
      expect(msg.body).to match(%r{#{HostUrl.protocol}://})
      expect(msg.body).to match(%r{courses/#{@assignment.context_id}/assignments/#{@assignment.id}})
    end
  end

  describe ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.body).to match(/Quiz 1/)
      expect(msg.body).to match(Regexp.new(@course.name))
    end
  end

  describe ".summary" do
    let(:path_type) { :summary }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset)
      expect(msg.subject).to match(/Quiz 1/)
      expect(msg.subject).to match(Regexp.new(@course.name))
    end
  end
end
