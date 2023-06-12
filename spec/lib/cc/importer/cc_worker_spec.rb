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
end
