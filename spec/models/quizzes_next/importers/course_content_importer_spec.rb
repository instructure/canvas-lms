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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '../../../../import_helper')

describe QuizzesNext::Importers::CourseContentImporter do
  subject(:importer) do
    described_class.new(data, migration)
  end

  context '.import_content' do
    let(:course) { course_factory() }
    let(:migration) { ContentMigration.create!(:context => course) }
    let(:assignment1) { instance_double('Assignment') }
    let(:assignment2) { instance_double('Assignment') }
    let(:assignment3) { instance_double('Assignment') }
    let(:quiz1) { instance_double('Quizzes::Quiz') }
    let(:quiz2) { instance_double('Quizzes::Quiz') }
    let(:quiz3) { instance_double('Quizzes::Quiz') }
    let(:data) { double }
    let(:time_now) { Time.zone.parse('03 May 2018 00:00:00 +0000') }

    before do
      allow(migration).
        to receive(:imported_migration_items_by_class).
        with(Assignment).
        and_return([assignment1, assignment2])
      allow(migration).
        to receive(:imported_migration_items_by_class).
        with(Quizzes::Quiz).
        and_return([quiz1, quiz2, quiz3])
      allow(Time.zone).to receive(:now).and_return(time_now)
      allow(assignment1).to receive(:quiz?).and_return(true)
      allow(assignment2).to receive(:quiz?).and_return(true)
      allow(assignment3).to receive(:quiz?).and_return(false)
      allow(assignment1).to receive(:quiz).and_return(quiz1)
      allow(assignment2).to receive(:quiz).and_return(quiz2)
      allow(assignment1).to receive(:global_id).and_return(112_233)
      allow(assignment2).to receive(:global_id).and_return(888_777)
      allow(quiz1).to receive(:global_id).and_return(123_456)
      allow(quiz2).to receive(:global_id).and_return(22_345)
    end

    it 'makes lti assignments' do
      expect(Importers::CourseContentImporter).
        to receive(:import_content)
      expect(assignment1).to receive(:workflow_state=).with('importing')
      expect(assignment1).to receive(:importing_started_at=).with(time_now)
      expect(assignment1).to receive(:quiz_lti!).and_return(true)
      expect(assignment1).to receive(:save!)
      expect(assignment2).to receive(:workflow_state=).with('importing')
      expect(assignment2).to receive(:importing_started_at=).with(time_now)
      expect(assignment2).to receive(:quiz_lti!).and_return(true)
      expect(assignment2).to receive(:save!)
      expect(quiz1).to receive(:destroy)
      expect(quiz2).to receive(:destroy)
      expect(quiz2).not_to receive(:destroy)
      importer.import_content(double)

      expect(migration.migration_settings[:imported_assets][:lti_assignment_quiz_set]).
        to eq([[112_233, 123_456], [888_777, 22_345]])
    end
  end

  context 'migration context is not a Course' do
    let(:context) { double }
    let(:migration) { instance_double('ContextMigration') }
    let(:data) { double }

    before do
      allow(migration).to receive(:context).and_return(context)
      allow(context).to receive(:instance_of?).
        with(Course).and_return(false)
    end

    it 'does nothing' do
      expect(Importers::CourseContentImporter).
        to receive(:import_content).never
      importer.import_content(double)
    end
  end
end
