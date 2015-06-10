#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiAssignmentCreator do
  it "converts an assignment into an lti_assignment" do
    assignment = Assignment.new()
    assignment.stubs(:id).returns(123)
    assignment.title = 'name'
    assignment.points_possible = 10
    assignment.allowed_extensions = 'csv,txt'

    lti_assignment = Lti::LtiAssignmentCreator.new(assignment, 'source_id').convert
    expect(lti_assignment).to be_a LtiOutbound::LTIAssignment
    expect(lti_assignment.id).to eq 123
    expect(lti_assignment.source_id).to eq 'source_id'
    expect(lti_assignment.title).to eq 'name'
    expect(lti_assignment.points_possible).to eq 10
    expect(lti_assignment.allowed_extensions).to eq ['csv', 'txt']
  end

  it "sets the correct return type for lti assignment launches" do
    assignment = Assignment.new()
    assignment.submission_types = 'external_tool'
    lti_assignment = Lti::LtiAssignmentCreator.new(assignment).convert

    expect(lti_assignment.return_types).to eq ['url', 'text']
  end

  it "correctly maps return types" do
    assignment = Assignment.new()
    assignment.submission_types = 'online_upload,online_url'
    lti_assignment = Lti::LtiAssignmentCreator.new(assignment).convert

    expect(lti_assignment.return_types).to eq ['file', 'url']
  end
end