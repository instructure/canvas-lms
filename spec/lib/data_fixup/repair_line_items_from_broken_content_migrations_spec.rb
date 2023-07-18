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
#

require_relative "../../models/content_migration/course_copy_helper"

describe DataFixup::RepairLineItemsFromBrokenContentMigrations do
  subject { DataFixup::RepairLineItemsFromBrokenContentMigrations.run(1) }

  include_context "course copy"

  # for stranding the jobs by shard, since none of the queries are
  # scoped by root account
  let(:shard_id) { 1 }
  let!(:src_key) { DeveloperKey.create!(account: @copy_from.account) }
  let!(:src_tool) do
    @copy_from.context_external_tools.create!(name: "foo", consumer_key: "123", shared_secret: "456", lti_version: "1.3", developer_key: src_key, url: "https://example.com", domain: "example.com")
  end
  let(:src_assignment) do
    assignment_model(title: "src", course: @copy_from, submission_types: "external_tool", external_tool_tag_attributes: { url: src_tool.url, content: src_tool })
  end
  let(:src) do
    src = src_assignment.line_items.first
    src.update!(
      resource_id: "123",
      tag: "bar",
      extensions: { hello: "world" },
      label: "this",
      score_maximum: 10
    )
    src.resource_link.update! url: "someurl"
    src
  end
  let(:warnings) { ["Import Error: Assignment - \"src\""] }
  let(:dest_assignment) do
    dest = @copy_to.assignments.first
    # needs to be in the date window to get picked up by fixup
    dest.update!(title: "dest", updated_at: Date.parse("2023-07-06"))
    dest
  end
  let(:dest) { dest_assignment.line_items.first }
  let(:updated_at) { Time.parse("2023-07-11 00:42:00Z") }

  before do
    src # create models before test starts
    Account.site_admin.enable_feature! :blueprint_line_item_support

    # this is a hack to "reproduce" the original bug in the code, which was a
    # NoMethodError on nil in AssignmentImporter#clear_params_before_overwriting_child_li.
    # That method is only accessible behind this flag and (now) when the migration is a
    # Blueprint Sync, but the original bug was for a normal course copy, so hacking the feature
    # flag check allows us to raise the same error in roughly the same branch of code.
    # It only should raise one time, since it gets checked again later in the process.
    allow(Account.site_admin).to receive(:feature_enabled?).and_call_original
    allow(Account.site_admin).to receive(:feature_enabled?).with(:blueprint_line_item_support) do
      raise NoMethodError if caller.any? { |t| t.include?("assignment_importer") }

      next
    end
  end

  it "sets attributes on dest line item from source line item" do
    run_course_copy(warnings)

    expect(dest.resource_id).to be_nil
    expect(dest.tag).to be_nil
    expect(dest.extensions).to be_empty
    expect(dest.label).to eq dest_assignment.title
    expect(dest.score_maximum).to eq dest_assignment.points_possible
    expect(dest.resource_link.url).to be_nil

    subject
    expect(dest.reload.resource_id).to eq src.resource_id
    expect(dest.tag).to eq src.tag
    expect(dest.extensions).to eq src.extensions
    expect(dest.label).to eq src.label
    expect(dest.score_maximum).to eq src.score_maximum
    expect(dest.updated_at).to eq updated_at
    expect(dest.resource_link.url).to eq "someurl"
  end

  context "with unaffected line items" do
    let(:unaffected_assignment) do
      assignment_model(title: "unaffected", course: @copy_from, submission_types: "external_tool", external_tool_tag_attributes: { url: src_tool.url, content: src_tool })
    end
    let(:unaffected) do
      li = unaffected_assignment.line_items.first
      li.update!(
        resource_id: nil,
        tag: nil,
        extensions: {}
      )
      li
    end
    let(:warnings) { ["Import Error: Assignment - \"src\"", "Import Error: Assignment - \"unaffected\""] }
    let(:dest_assignment) { @copy_to.assignments.last }

    it "ignores them" do
      unaffected # create models before test starts
      run_course_copy(warnings)

      expect(dest.resource_id).to be_nil
      expect(dest.tag).to be_nil
      expect(dest.extensions).to be_empty
      expect(dest.label).to eq dest_assignment.title
      expect(dest.score_maximum).to eq dest_assignment.points_possible
      u = dest.updated_at

      subject

      expect(dest.reload.resource_id).to be_nil
      expect(dest.tag).to be_nil
      expect(dest.extensions).to be_empty
      expect(dest.label).to eq dest_assignment.title
      expect(dest.score_maximum).to eq dest_assignment.points_possible
      expect(dest.updated_at).to eq u
    end
  end

  context "with multiple line items from same source" do
    let(:second) do
      src_assignment.line_items.create!(
        resource_id: "456",
        tag: "baz",
        extensions: { hello: "there" },
        score_maximum: 10,
        label: "second",
        resource_link: src.resource_link
      )
    end
    let(:second_dest) { dest_assignment.reload.line_items.last }

    it "creates dest line items" do
      second
      run_course_copy(warnings)
      expect(dest_assignment.line_items.count).to eq 1

      subject

      expect(dest_assignment.line_items.count).to eq 2

      expect(dest.reload.resource_id).to eq src.resource_id
      expect(dest.tag).to eq src.tag
      expect(dest.extensions).to eq src.extensions
      expect(dest.updated_at).to eq updated_at

      expect(second_dest.reload.resource_id).to eq second.resource_id
      expect(second_dest.tag).to eq second.tag
      expect(second_dest.extensions).to eq second.extensions
      expect(second_dest.updated_at).to eq updated_at
    end
  end
end
