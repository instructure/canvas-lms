# frozen_string_literal: true

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
    let!(:quiz01) do
      Quizzes::Quiz.create(
        context: course
      )
    end
    let!(:assignment01) do
      quiz01.build_assignment
      quiz01.assignment
    end
    let!(:quiz02) do
      Quizzes::Quiz.create(
        context: course
      )
    end
    let!(:assignment02) do
      quiz02.build_assignment
      quiz02.assignment
    end
    let!(:quiz03) do
      Quizzes::Quiz.create(
        context: course
      )
    end
    let!(:practice_quiz) do
      Quizzes::Quiz.create(
        context: course,
        quiz_type: 'practice_quiz',
        title: practice_quiz_title
      )
    end

    let(:practice_quiz_title) { SecureRandom.hex(40) }

    let(:data) { double }

    before do
      allow(migration).
        to receive(:imported_migration_items_by_class).
        with(Quizzes::Quiz).
        and_return([quiz01, quiz02, quiz03, practice_quiz])
    end

    it 'makes lti assignments' do
      expect(Importers::CourseContentImporter).
        to receive(:import_content)
      original_setup_assets_imported = importer.method(:setup_assets_imported)
      expect(importer).to receive(:setup_assets_imported) do |lti_assignment_quiz_set|
        expect(migration.workflow_state).not_to eq('imported')
        original_setup_assets_imported.call(lti_assignment_quiz_set)
      end
      expect { importer.import_content(double) }.to change(Assignment, :count).by(2)
      expect(migration.workflow_state).to eq('imported')
      practice_assginment = Assignment.find_by(title: practice_quiz_title)
      expect(practice_assginment).not_to be_nil
      expect(migration.migration_settings[:imported_assets][:lti_assignment_quiz_set]).
        to eq([
          [assignment01.global_id, quiz01.global_id],
          [assignment02.global_id, quiz02.global_id],
          [quiz03.assignment.global_id, quiz03.global_id],
          [practice_assginment.global_id, practice_quiz.global_id]
        ])
      expect(practice_assginment.omit_from_final_grade).to be(true)
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
