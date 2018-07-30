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

describe "submission_graded" do
  before :once do
    submission_model
  end

  let(:asset) { @submission }
  let(:notification_name) { :submission_graded }

  include_examples "a message"

  it "should include the submission's submitter name if receiver is not the submitter and has the setting turned on" do
    observer = user_model
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).not_to match("For #{@submission.user.name}")

    observer.preferences[:send_observed_names_in_notifications] = true
    observer.save!
    message = generate_message(:submission_graded, :summary, asset, user: observer)
    expect(message.body).to match("For #{@submission.user.name}")
  end
end
