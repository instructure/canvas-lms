# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

RSpec.describe Lti::Asset do
  describe "validations" do
    subject { lti_asset_model }

    it { is_expected.to be_valid }

    context "exactly one locator field present" do
      it "is valid with only attachment_id" do
        expect(lti_asset_model(attachment: attachment_model).save).to be_truthy
      end

      it "is valid with only submission_attempt (RCE)" do
        submission = submission_model(submission_type: "online_text_entry", body: "hi")
        asset = lti_asset_model(submission:, submission_attempt: submission.attempt)
        expect(asset.save).to be_truthy
      end

      it "is valid with only discussion_entry_version_id" do
        topic = course_model.discussion_topics.create!
        entry = topic.discussion_entries.create!(message: "msg", user: user_model)
        dev = entry.discussion_entry_versions.first
        submission = submission_model
        asset = Lti::Asset.new(submission:, discussion_entry_version: dev)
        expect(asset.save).to be_truthy
      end

      it "is valid with none present (referenced entity (discussion_entry_version_id) has been deleted)" do
        submission = submission_model
        asset = Lti::Asset.new(submission:, attachment: nil, submission_attempt: nil, discussion_entry_version_id: nil)
        expect(asset).not_to be_valid
        expect(asset.errors.full_messages.join).to match(/Exactly one of/)
        expect(asset.save(validate: false)).to be_truthy
      end

      it "is invalid with multiple present" do
        submission = submission_model(submission_type: "online_text_entry", body: "hi")
        topic = submission.assignment.context.discussion_topics.create!
        entry = topic.discussion_entries.create!(message: "msg", user: user_model)
        dev = entry.discussion_entry_versions.first
        # use raw model to control fields
        asset = Lti::Asset.new(submission:, attachment: attachment_model, submission_attempt: submission.attempt, discussion_entry_version_id: dev.id)
        expect(asset).not_to be_valid
        expect(asset.errors.full_messages.join).to match(/Exactly one of/)
        expect { asset.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid, /CheckViolation|chk_one_asset_locator_present/)
      end
    end
  end

  it "generates a uuid" do
    asset1 = lti_asset_model
    asset2 = lti_asset_model
    expect(asset1.uuid).not_to be_nil
    expect(asset2.uuid).not_to be_nil
    expect(asset1.uuid).not_to eq(asset2.uuid)
  end

  it "submission_id is nullified when submission is deleted" do
    asset1 = lti_asset_model

    asset1.submission.destroy

    expect(asset1.reload.submission_id).to be_nil
    expect(asset1.asset_type).to eq "deleted"
  end

  it "allows multiple rows with the same attachment_id and empty submission id" do
    attachment = attachment_model
    asset1 = lti_asset_model(attachment:)
    asset2 = lti_asset_model(attachment:)
    expect(asset2.attachment_id).to eq(asset1.attachment_id)

    asset1.submission.destroy
    asset2.submission.destroy

    expect(asset1.reload.submission_id).to be_nil
    expect(asset2.reload.submission_id).to be_nil
  end

  it "allows multiple rows with the same submission_attempt and empty submission id" do
    submission = submission_model(submission_type: "online_text_entry", body: "hello body")
    attempt_number = submission.attempt
    asset1 = lti_asset_model(submission:, submission_attempt: attempt_number)
    submission.destroy
    asset1.reload
    expect(asset1.submission_id).to be_nil

    asset2 = Lti::Asset.new(submission_attempt: attempt_number)
    asset2.uuid = SecureRandom.uuid
    asset2.root_account_id = asset1.root_account_id
    expect { asset2.save!(validate: false) }.not_to raise_error
  end

  it "soft deleted when attachment is deleted" do
    asset1 = lti_asset_model

    asset1.attachment.destroy

    expect(asset1.reload.workflow_state).to eq("deleted")
  end

  describe "discussion_entry_version_id" do
    it "prevents duplicates at the DB level" do
      submission = submission_model
      topic = submission.assignment.context.discussion_topics.create!
      entry = topic.discussion_entries.create!(message: "msg", user: user_model)
      dev = entry.discussion_entry_versions.first
      first = Lti::Asset.create!(submission:, attachment: nil, submission_attempt: nil, discussion_entry_version_id: dev.id)
      expect(first).to be_persisted

      dup = Lti::Asset.new(submission:, discussion_entry_version_id: dev.id)
      expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "when deleting a discussion_entry_version referenced by an asset the asset is soft-deleted" do
      submission = submission_model
      topic = submission.assignment.context.discussion_topics.create!
      entry = topic.discussion_entries.create!(message: "msg", user: user_model)
      dev = entry.discussion_entry_versions.first
      asset = Lti::Asset.create!(submission:, discussion_entry_version: dev)

      dev.destroy!
      expect(asset.reload.workflow_state).to eq("active")
      expect(asset.discussion_entry_version_id).to be_nil
    end

    it "nullifies discussion_entry_version_id at the DB level via FK ON DELETE SET NULL" do
      submission = submission_model
      topic = submission.assignment.context.discussion_topics.create!
      entry = topic.discussion_entries.create!(message: "msg", user: user_model)
      dev = entry.discussion_entry_versions.first
      asset = Lti::Asset.create!(submission:, discussion_entry_version: dev)

      # Direct SQL delete to bypass AR callbacks and ensure database FK handles nullification
      DiscussionEntryVersion.connection.execute("DELETE FROM #{DiscussionEntryVersion.quoted_table_name} WHERE id = #{dev.id}")

      asset.reload
      expect(asset.discussion_entry_version_id).to be_nil
      # Asset should remain active and still have its submission id set
      expect(asset.workflow_state).to eq("active")
      expect(asset.submission_id).not_to be_nil
    end
  end

  describe "#compatible_with_processor?" do
    describe "for submission-attachment assets" do
      it "is true iff the submission matches the given processor's assignment" do
        asset = lti_asset_model
        processor = lti_asset_processor_model(assignment: asset.submission.assignment)
        expect(asset.compatible_with_processor?(processor)).to be(true)

        expect(asset.compatible_with_processor?(lti_asset_processor_model)).to be(false)
      end
    end
  end

  describe "#calculate_sha256_checksum!" do
    let(:content) { "hello world" }
    let(:attachment) { attachment_model(uploaded_data: stub_file_data("test.txt", content, "text/plain")) }
    let(:asset) { lti_asset_model(attachment:) }

    it "calculates and stores SHA256 checksum" do
      asset.calculate_sha256_checksum!
      expect(asset.reload.sha256_checksum).to eq "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
    end

    it "does nothing if checksum already exists" do
      asset.update(sha256_checksum: "existing_checksum")
      asset.calculate_sha256_checksum!
      expect(asset.reload.sha256_checksum).to eq "existing_checksum"
    end

    context "text entry submission" do
      let(:asset) { lti_asset_model(submission: submission_model(submission_type: "online_text_entry", body: content)) }

      it "calculates checksum for text entry submissions" do
        asset.calculate_sha256_checksum!
        expect(asset.reload.sha256_checksum).to eq "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
      end
    end
  end

  describe "#content_size" do
    let(:content) { "hello world" }

    context "with attachment" do
      let(:attachment) { attachment_model(uploaded_data: stub_file_data("test.txt", content, "text/plain")) }
      let(:asset) { lti_asset_model(attachment:) }

      it "returns the size of the attachment content" do
        expect(asset.content_size).to eq(11)
      end
    end

    context "with text entry submission" do
      let(:asset) { lti_asset_model(submission: submission_model(submission_type: "online_text_entry", body: content)) }

      it "returns the size of the text entry content" do
        expect(asset.content_size).to eq(11)
      end
    end
  end

  describe "asset_reports association" do
    let(:asset) { lti_asset_model }
    let(:asset_processor) { lti_asset_processor_model(assignment: asset.submission.assignment) }

    it "soft deletes dependent asset reports when deleted" do
      3.times do |i|
        lti_asset_report_model(
          asset:,
          asset_processor:,
          report_type: "test_report_type_#{i}",
          timestamp: Time.zone.now,
          priority: Lti::AssetReport::PRIORITY_GOOD,
          processing_progress: Lti::AssetReport::PROGRESS_PROCESSED
        )
      end

      expect(asset.asset_reports.count).to eq 3

      asset.destroy!

      expect(asset.asset_reports.reload.pluck(:workflow_state)).to all(eq("deleted"))
    end
  end
end
