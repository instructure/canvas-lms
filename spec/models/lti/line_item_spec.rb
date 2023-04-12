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
      line_item_one = line_item_model(assignment: assignment)
      line_item_two = line_item_model(assignment: assignment)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_one.assignment_line_item?).to be true
    end

    it "returns false if the line item is not the first in the assignment" do
      line_item_one = line_item_model(assignment: assignment)
      line_item_two = line_item_model(assignment: assignment)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)

      expect(line_item_two.assignment_line_item?).to be false
    end
  end

  describe "#launch_url_extension" do
    let(:url) { "https://example.com/launch" }
    let(:assignment) do
      a = assignment_model
      a.external_tool_tag = ContentTag.create!(context: a, url: url)
      a.save!
      a
    end
    let(:line_item) { line_item_model(assignment: assignment) }

    it "returns hash with extension key" do
      expect(line_item.launch_url_extension).to have_key(Lti::LineItem::AGS_EXT_LAUNCH_URL)
    end

    it "returns launch url in hash" do
      expect(line_item.launch_url_extension[Lti::LineItem::AGS_EXT_LAUNCH_URL]).to eq url
    end
  end

  context "with lti_link not matching assignment" do
    let(:resource_link) { resource_link_model }
    let(:line_item) { line_item_model resource_link: resource_link }
    let(:line_item_two) { line_item_model resource_link: resource_link }

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

  context "when destroying a line item" do
    let(:line_item) { line_item_model }
    let(:assignment) { assignment_model }
    let(:resource_link) { resource_link_model }

    it "destroys the assignment if it is the first line item and is not coupled" do
      line_item_one = line_item_model(assignment: assignment, coupled: false)
      line_item_two = line_item_model(assignment: assignment)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)
      expect do
        line_item_one.destroy!
      end.to change(assignment, :workflow_state).from("published").to("deleted")
    end

    it "doesn't destroy the assignment if the line item is not the first line item" do
      line_item_one = line_item_model(assignment: assignment)
      line_item_two = line_item_model(assignment: assignment, coupled: false)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)
      expect do
        line_item_two.destroy!
      end.not_to change(assignment, :workflow_state)
    end

    it "doesn't destroy the assignment if the line item is coupled" do
      line_item_one = line_item_model(assignment: assignment, coupled: true)
      line_item_two = line_item_model(assignment: assignment)
      line_item_two.update!(created_at: line_item_one.created_at + 5.seconds)
      expect do
        line_item_one.destroy!
      end.not_to change(assignment, :workflow_state)
    end
  end
end
