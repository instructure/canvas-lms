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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'rubric_assessment_submission_reminder' do
  before :once do
    user_model
    rubric_assessment_model(user: @user)
    @submission = @course.assignments.first.submissions.create!(user: @user)
    @object = @rubric_association.assessment_requests.create!(user: @user,
                                                              asset: @submission,
                                                              assessor: @user,
                                                              assessor_asset: @submission)
  end

  let(:asset) { @object }
  let(:notification_name) { :rubric_assessment_submission_reminder }

  include_examples "a message"
end