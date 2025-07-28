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

describe "appointment_reserved_by_user" do
  include MessagesCommon

  before :once do
    @user = user_model
    appointment_participant_model(participant: @user)
  end

  let(:asset) { @event }
  let(:notification_name) { :appointment_reserved_by_user }
  let(:message_data) do
    {
      data: { updating_user_name: @user.name },
      user: @user
    }
  end

  describe ".email" do
    let(:path_type) { :email }

    before :once do
      @user = user_model
      @course = course_model
      @cat = group_category
      user_model
      @group = @cat.groups.create(context: @course)
      @group.users << @user
      appointment_participant_model(participant: @group,
                                    course: @course,
                                    updating_user: @user)
    end

    it "renders" do
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.subject).to include("some title")
      expect(msg.body).to include("some title")
      expect(msg.body).to include(@user.name)
      expect(msg.body).to include(@course.name)
      expect(msg.body).to include("/appointment_groups/#{@appointment_group.id}")
    end

    it "renders for groups" do
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.body).to include(@group.name)
    end
  end

  describe ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset, message_data)
      expect(msg.body).to include("some title")
      expect(msg.body).to include(@user.name)
    end
  end
end
