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

describe "appointment_reserved_for_user" do
  include MessagesCommon

  before :once do
    @user = user_model
    @course = course_model
    cat = group_category
    @group = cat.groups.create(context: @course)
    @group.users << @user
    appointment_participant_model(participant: @group, course: @course)
  end

  let(:notification_name) { :appointment_reserved_for_user }
  let(:asset) { @event }
  let(:message_options) { { data: { updating_user_name: @teacher.name } } }

  describe ".email" do
    let(:path_type) { :email }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset, message_options)
      expect(msg.subject).to include("some title")
      expect(msg.body).to include("some title")
      expect(msg.body).to include(@teacher.name)
      expect(msg.body).to include(@user.name)
      expect(msg.body).to include(@course.name)
      expect(msg.body).to include("/appointment_groups/#{@appointment_group.id}")
    end

    context "for groups" do
      it "renders group name" do
        msg = generate_message(notification_name, path_type, asset, message_options)

        expect(msg.body).to include(@group.name)
      end
    end
  end

  describe ".sms" do
    let(:path_type) { :sms }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset, message_options)
      expect(msg.body).to include("some title")
    end
  end

  describe ".summary" do
    let(:path_type) { :summary }

    it "renders" do
      msg = generate_message(notification_name, path_type, asset, message_options)
      expect(msg.subject).to include("some title")
      expect(msg.body).to include("some title")
      expect(msg.body).to include(@teacher.name)
    end
  end
end
