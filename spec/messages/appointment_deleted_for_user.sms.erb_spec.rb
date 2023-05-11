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

describe "appointment_deleted_for_user.sms" do
  include MessagesCommon

  it "renders" do
    user = user_model(name: "bob")
    appointment_participant_model(participant: user)

    generate_message(:appointment_deleted_for_user,
                     :sms,
                     @event,
                     data: { updating_user_name: @teacher.name,
                             cancel_reason: "just because" })

    expect(@message.body).to include("some title")
  end

  it "renders for groups" do
    user = user_model(name: "bob")
    @course = course_model
    cat = group_category
    @group = cat.groups.create(context: @course)
    @group.users << user
    appointment_participant_model(participant: @group, course: @course)

    generate_message(:appointment_deleted_for_user,
                     :sms,
                     @event,
                     data: { updating_user_name: @teacher.name,
                             cancel_reason: "just because" })

    expect(@message.body).to include("some title")
  end
end
