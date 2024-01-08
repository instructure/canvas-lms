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

describe "annotation_notification" do
  include MessagesCommon

  let(:notification_name) { :annotation_notification }
  let(:asset) { @submission }
  let(:path_type) { :email }
  let(:data) { { data: { author_name: "User 1" } } }

  context ".email" do
    context "base case" do
      before :once do
        assignment_model
        @submission = submission_model(assignment: @assignment, user: @student)
      end

      it "renders" do
        msg = generate_message(notification_name, path_type, asset, data)

        expect(msg.subject).to match("A new annotation has been made to your submission document")
        expect(msg.body).to match(/A new annotation has been made by User 1 on the assignment/)
        expect(msg.body).to match(%r{#{HostUrl.protocol}://})
      end
    end

    context "anonymous annotations" do
      before :once do
        assignment_model(anonymous_instructor_annotations: true)
        @submission = submission_model(assignment: @assignment, user: @student)
      end

      it "renders" do
        msg = generate_message(notification_name, path_type, asset, data)

        expect(msg.subject).to match("A new annotation has been made to your submission document")
        expect(msg.body).to match(/A new annotation has been made on the assignment/)
        expect(msg.body).to match(%r{#{HostUrl.protocol}://})
      end
    end
  end
end
