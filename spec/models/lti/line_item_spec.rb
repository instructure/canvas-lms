# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative "../../spec_helper"

RSpec.describe Lti::LineItem do
  context "when validating" do
    let(:line_item) { line_item_model }

    it 'requires "score_maximum"' do
      expect do
        line_item.update!(score_maximum: nil)
      end.to raise_error(
        ActiveRecord::RecordInvalid,
        "Validation failed: Score maximum can't be blank, Score maximum is not a number"
      )
    end

    it 'requires "label"' do
      expect do
        line_item.update!(label: nil)
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Label can't be blank")
    end

    it 'requires "assignment"' do
      expect do
        line_item.update!(assignment: nil)
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assignment can't be blank")
    end
  end

  context "on create" do
    it "adds a root account id" do
      line_item = line_item_model
      expect(line_item.root_account).not_to be_nil
    end
  end

  describe "#assignment_line_item?" do
    let(:line_item) { line_item_model }
    let(:assignment) { assignment_model }

    it "returns true if the line item was created before all others in the assignment" do
      line_item_one = line_item_model(assignment:)
      line_item_two = line_item_model(assignment:)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_one.assignment_line_item?).to be true
    end

    it "returns false if the line item is not the first in the assignment" do
      line_item_one = line_item_model(assignment:)
      line_item_two = line_item_model(assignment:)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_two.assignment_line_item?).to be false
    end
  end

  describe "#launch_url_extension" do
    let(:url) { "https://example.com/launch" }
    let(:assignment) do
      a = assignment_model
      a.external_tool_tag = ContentTag.create!(context: a, url:)
      a.save!
      a
    end
    let(:line_item) { line_item_model(assignment:) }

    it "returns hash with extension key" do
      expect(line_item.launch_url_extension).to have_key(Lti::LineItem::AGS_EXT_LAUNCH_URL)
    end

    it "returns launch url in hash" do
      expect(line_item.launch_url_extension[Lti::LineItem::AGS_EXT_LAUNCH_URL]).to eq url
    end
  end

  context "with lti_link not matching assignment" do
    let(:resource_link) { resource_link_model }
    let(:line_item) { line_item_model resource_link: }
    let(:line_item_two) { line_item_model resource_link: }

    it "returns true if the line item was created before all others in the resource" do
      line_item
      expect do
        line_item_two
      end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Assignment does not match ltiLink")
    end
  end

  it_behaves_like "soft deletion" do
    subject { Lti::LineItem }

    let(:creation_arguments) { base_line_item_params(assignment_model, DeveloperKey.create!) }
  end

  it "destroys and undestroys associated results" do
    line_item = line_item_model
    result = lti_result_model(line_item:)
    expect(result).to be_active
    line_item.destroy
    expect(result.reload).to be_deleted
    line_item.reload.undestroy
    expect(result.reload).to be_active
  end

  context "when updating the associated assignment" do
    let(:line_item) do
      Time.now
      tool = AccessToken.create!
      line_item_params = { start_date_time: Time.now - 1.day, end_date_time: Time.now, score_maximum: 10.0, label: "a line item" }
      line_item = Lti::LineItem.create_line_item!(nil, course_model, tool, line_item_params)
      # This is necessary because the line item only gets associated to the assignment after
      # the assignment is created. This line_item variable is up-to-date with "knowing" its
      # relation to the assignment, but the assignment variable is not yet up-to-date with
      # its relation to the line item, even though we are referencing it with
      # line_item.assignment -- in the assignment model, when it calls self.line_items,
      # it will still get nil. So it needs to be reloaded. Since Lti::LineItem.create_line_item!
      # is only ever called in an API request, this "need to reload" scenario should not
      # happen in real life.
      line_item.assignment.reload
      line_item
    end

    it "updates the line item's end_date_time to match assignment's due date" do
      next_week = 1.week.from_now
      line_item.assignment.due_at = next_week
      line_item.assignment.save!
      expect(line_item.reload.end_date_time).to eq(next_week)
    end

    it "updates the line item's start_date_time to match assignment's due date" do
      last_week = 1.week.ago
      line_item.assignment.unlock_at = last_week
      line_item.assignment.save!
      expect(line_item.reload.start_date_time).to eq(last_week)
    end
  end
end
