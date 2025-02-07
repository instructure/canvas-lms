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

describe CC::Importer::CCWorker do
  it "sets the worker_class on the migration" do
    cm = ContentMigration.create!(migration_settings: { converter_class: CC::Importer::Canvas::Converter,
                                                        no_archive_file: true },
                                  context: course_factory)
    cm.reset_job_progress
    expect_any_instance_of(CC::Importer::Canvas::Converter).to receive(:export).and_return({})
    worker = CC::Importer::CCWorker.new(cm.id)
    expect(worker.perform).to be true
    expect(cm.reload.migration_settings[:worker_class]).to eq "CC::Importer::Canvas::Converter"
  end

  it "honors skip_job_progress" do
    cm = ContentMigration.create!(migration_settings: { converter_class: CC::Importer::Canvas::Converter,
                                                        no_archive_file: true,
                                                        skip_job_progress: true },
                                  context: course_factory)
    expect_any_instance_of(CC::Importer::Canvas::Converter).to receive(:export).and_return({})
    worker = CC::Importer::CCWorker.new(cm.id)
    expect(worker.perform).to be true
    expect(cm.skip_job_progress).to be_truthy
  end

  describe "setting is_discussion_checkpoints_enabled ff" do
    subject { described_class.new(content_migration.id).perform }

    let(:course) { course_factory }
    let(:migration_settings) { { converter_class: CC::Importer::Canvas::Converter, no_archive_file: true, skip_job_progress: true } }
    let(:content_migration) { ContentMigration.create!(migration_settings:, context: course) }

    before do
      allow_any_instance_of(CC::Importer::Canvas::Converter).to receive(:export).and_return({})
    end

    context "when is_discussion_checkpoints_enabled is disabled" do
      let(:expected_settings) { { is_discussion_checkpoints_enabled: false } }

      before do
        course.account.disable_feature!(:discussion_checkpoints)
      end

      it "calls converter_class with proper settings" do
        expect(CC::Importer::Canvas::Converter).to receive(:new).with(hash_including(expected_settings))
        subject
      end
    end

    context "when is_discussion_checkpoints_enabled is enabled" do
      let(:expected_settings) { { is_discussion_checkpoints_enabled: true } }

      before do
        course.account.enable_feature!(:discussion_checkpoints)
      end

      it "calls converter_class with proper settings" do
        expect(CC::Importer::Canvas::Converter).to receive(:new).with(hash_including(expected_settings))
        subject
      end
    end
  end
end
