# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::UpdateLineItemsToMatchAssignmentDueDates do
  before do
    course = course_model

    # create some line items
    tool = AccessToken.create!
    4.times do |index|
      line_item_params = { end_date_time: Time.now, score_maximum: 10.0, label: "line item #{index}" }
      line_item = Lti::LineItem.create_line_item!(nil, course_model, tool, line_item_params)
      line_item.update!(end_date_time: Time.now + 7.days)
    end

    # create a line item with nil for end_date_time
    line_item_params = { score_maximum: 10.0, label: "line item" }
    line_item = Lti::LineItem.create_line_item!(nil, course_model, tool, line_item_params)
    line_item.assignment.update!(due_at: Time.now + 7.days)

    # create some line items that already have matching end_date_time/due_at dates
    3.times do |index|
      line_item_params = { end_date_time: Time.now, score_maximum: 10.0, label: "line item #{index}" }
      Lti::LineItem.create_line_item!(nil, course_model, tool, line_item_params)
    end

    # create some regular assignments
    2.times { |index| Assignment.create!(course:, name: "assignment #{index} not external tool") }
  end

  it "corrects mis-matched assignment due dates" do
    expect(DataFixup::UpdateLineItemsToMatchAssignmentDueDates)
      .to receive(:update_line_item_date)
      .with(any_args)
      .exactly(5)
      .times
      .and_call_original

    Lti::LineItem.find_ids_in_ranges(batch_size: 1_000) do |start_id, end_id|
      DataFixup::UpdateLineItemsToMatchAssignmentDueDates.run(start_id, end_id)
    end

    expect(Lti::LineItem.count).to eq(8)
    # All line items should match the due_at date of their assignments
    Lti::LineItem.find_each { |li| expect(li.end_date_time).to eq(li.assignment.due_at) }
  end
end
