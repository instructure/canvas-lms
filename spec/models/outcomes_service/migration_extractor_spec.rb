#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../spec_helper'

describe OutcomesService::MigrationExtractor do
  before(:once) { course_with_teacher }

  let(:cm) { ContentMigration.create!(context: @course, user: @teacher) }
  let(:subject) { described_class.new(cm) }

  describe '.learning_outcomes' do
    it 'returns no outcomes with an empty migration' do
      expect(subject.learning_outcomes(@course)).to eq []
    end

    context 'with course outcome' do
      let(:course_outcome) do
        @course.created_learning_outcomes.create!(
          title: 'course outcome',
          migration_id: 'alpha'
        )
      end

      it 'returns single course outcome' do
        cm.add_imported_item(course_outcome)
        outcomes = subject.learning_outcomes(@course)
        expect(outcomes.length).to eq 1
        outcome = outcomes[0]
        expect(outcome).to include(
          '$canvas_learning_outcome_id': course_outcome.id,
          rubric_criterion: be_an_instance_of(Hash)
        )
        expect(outcome).to_not have_key(:migration_id_2)
        expect(outcome).to_not have_key(:vendor_guid_2)
        expect(outcome).to_not have_key(:root_account_id)
        expect(outcome).to_not have_key(:context_type)
        expect(outcome).to_not have_key(:context_id)
      end

      context 'with global outcome' do
        let(:global_outcome) do
          LearningOutcome.create!(title: 'global outcome', migration_id: 'beta').tap do |outcome|
            LearningOutcomeGroup.global_root_outcome_group.add_outcome(outcome)
          end
        end

        it 'excludes the non-course outcome' do
          cm.add_imported_item(course_outcome)
          cm.add_imported_item(global_outcome)
          outcomes = subject.learning_outcomes(@course)
          expect(outcomes.length).to eq 1
          expect(outcomes[0][:'$canvas_learning_outcome_id']). to eq course_outcome.id
        end
      end
    end
  end

  describe '.learning_outcome_groups' do
    it 'returns only root group with an empty migration' do
      groups = subject.learning_outcome_groups(@course)
      expect(groups.count).to eq 1
      group = groups[0]
      expect(group).to include(
        '$canvas_learning_outcome_group_id': @course.root_outcome_group.id,
        parent_outcome_group_id: nil
      )
      expect(group).to_not have_key(:id)
      expect(group).to_not have_key(:learning_outcome_group_id)
      expect(group).to_not have_key(:root_learning_outcome_group_id)
      expect(group).to_not have_key(:root_account_id)
      expect(group).to_not have_key(:migration_id_2)
      expect(group).to_not have_key(:vendor_guid_2)
    end
  end

  describe '.learning_outcome_links' do
    it 'returns no links with an empty migration' do
      expect(subject.learning_outcome_links).to eq []
    end

    context 'with course outcome' do
      let!(:course_outcome) do
        @course.created_learning_outcomes.create!(
          title: 'course outcome',
          migration_id: 'alpha'
        ).tap do |outcome|
          @course.root_outcome_group.add_outcome(outcome, migration_id: 'charlie')
        end
      end

      it 'returns single outcome link' do
        cm.add_imported_item(@course.root_outcome_group.child_outcome_links.first)
        links = subject.learning_outcome_links
        expect(links.length).to eq 1
        expect(links[0]).to eq(
          '$canvas_learning_outcome_link_id': @course.root_outcome_group.child_outcome_links.first.id,
          '$canvas_learning_outcome_group_id': @course.root_outcome_group.id,
          '$canvas_learning_outcome_id': course_outcome.id,
        )
      end

      context 'with other content tags' do
        let!(:content_tag) do
          ContentTag.create!(tag_type: 'fake', context: @course, migration_id: 'delta')
        end

        it 'excludes the non-link content tag' do
          cm.add_imported_item(@course.root_outcome_group.child_outcome_links.first)
          cm.add_imported_item(content_tag)
          expect(subject.learning_outcome_links.length).to eq 1
        end
      end
    end
  end
end
