# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

RSpec.describe Outcomes::Import do
  class TestImporter
    include Outcomes::Import

    def initialize(context)
      @context = context
    end

    attr_reader :context
  end

  let_once(:context) { account_model }
  let_once(:course) { course_model(account: context) }
  let_once(:other_context) { account_model }
  let_once(:parent1) { outcome_group_model(context: context, vendor_guid: 'parent1') }
  let_once(:parent2) { outcome_group_model(context: context, vendor_guid: 'parent2') }
  let_once(:outcome_vendor_guid) { 'imanoutcome' }
  let_once(:group_vendor_guid) { 'imagroup' }
  let(:group_attributes) do
    {
      title: "i'm a group",
      description: "really i'm a group",
      vendor_guid: group_vendor_guid,
      workflow_state: 'active',
    }
  end
  let(:outcome_attributes) do
    {
      title: "i'm an outcome",
      description: "really i'm an outcome",
      display_name: 'display an outcome',
      vendor_guid: outcome_vendor_guid,
      workflow_state: 'active',
      calculation_method: 'n_mastery',
      calculation_int: 3
    }
  end
  let(:importer) { TestImporter.new(context) }

  describe '#import_object' do
    it 'calls #import_group for a group' do
      importer.import_object(**group_attributes, vendor_guid: 'new_group', object_type: 'group')
      expect(LearningOutcomeGroup.find_by(vendor_guid: 'new_group')).to be_present
    end

    it 'calls #import_outcome for an outcome' do
      importer.import_object(**outcome_attributes, vendor_guid: 'new_outcome', object_type: 'outcome')
      expect(LearningOutcome.find_by(vendor_guid: 'new_outcome')).to be_present
    end

    it 'raises an error for anything else' do
      expect do
        importer.import_object(**group_attributes, object_type: 'monkey')
      end.to raise_error(TestImporter::InvalidDataError, /Invalid object_type/)
    end
  end

  describe '#import_group' do
    let_once(:existing_group) { outcome_group_model(context: context, vendor_guid: group_vendor_guid) }

    context 'with canvas_id' do
      it 'fails if group not present with that id' do
        missing_id = existing_group.destroy_permanently!.id
        expect do
          importer.import_group(canvas_id: missing_id, **group_attributes)
        end.to raise_error(TestImporter::InvalidDataError, /not found/)
      end

      it 'fails if matching group not in correct context' do
        existing_group.update! context: other_context
        expect do
          importer.import_group(canvas_id: existing_group.id, **group_attributes)
        end.to raise_error(TestImporter::InvalidDataError, /incorrect context/)
      end

      it 'updates vendor_guid if group in correct context' do
        existing_group.update! vendor_guid: 'gonna get changed'
        importer.import_group(canvas_id: existing_group.id, **group_attributes)
        expect(existing_group.reload.vendor_guid).to eq group_vendor_guid
      end
    end

    context 'with vendor_guid' do
      it 'updates if group in current context' do
        importer.import_group(group_attributes)
        expect(existing_group.reload.title).to eq "i'm a group"
      end

      it 'creates in current context if group not found' do
        importer.import_group(**group_attributes, vendor_guid: 'something else')
        new_group = LearningOutcomeGroup.find_by!(vendor_guid: 'something else')
        expect(new_group.id).not_to eq existing_group.id
        expect(new_group.title).to eq "i'm a group"
      end

      it 'creates new group if matching group not in correct context' do
        existing_group.update! context: other_context
        importer.import_group(group_attributes)
        new_group = LearningOutcomeGroup.find_by!(context: context, vendor_guid: group_vendor_guid)
        expect(new_group.id).not_to eq existing_group.id
      end
    end

    it 'updates attributes' do
      importer.import_group(group_attributes)
      expect(existing_group.reload).to have_attributes group_attributes
    end

    it 'fails if outcome group has already appeared in import' do
      importer.import_group(group_attributes)
      expect do
        importer.import_group(group_attributes)
      end.to raise_error TestImporter::InvalidDataError, /already appeared/
    end

    context 'with parents' do
      before do
        [parent1, parent2].each do |p|
          importer.import_group(**group_attributes, vendor_guid: p.vendor_guid)
        end
      end

      it 'assigns correct parent' do
        importer.import_group(**group_attributes, vendor_guid: 'newguy', parent_guids: 'parent1')
        new_guy = LearningOutcomeGroup.find_by!(vendor_guid: 'newguy')
        expect(new_guy.learning_outcome_group).to eq parent1
      end

      it 'assigns to root outcome group if no parent specified' do
        importer.import_group(**group_attributes, vendor_guid: 'newguy', parent_guids: '')
        new_guy = LearningOutcomeGroup.find_by!(vendor_guid: 'newguy')
        expect(new_guy.learning_outcome_group).to eq context.root_outcome_group
      end

      it 'fails if parents not found in file' do
        expect do
          importer.import_group(**group_attributes, parent_guids: 'blahblahblah')
        end.to raise_error(TestImporter::InvalidDataError, /Parent references not found/)
      end

      it 'fails if parents not found' do
        parent1.destroy_permanently!
        expect do
          importer.import_group(**group_attributes, parent_guids: 'parent1')
        end.to raise_error(TestImporter::InvalidDataError, /Parent references not found/)
      end

      it 'reassigns parents of existing group' do
        existing_group.update! learning_outcome_group: parent1
        importer.import_group(**group_attributes, parent_guids: 'parent2')
        expect(existing_group.reload.learning_outcome_group).to eq parent2
      end
    end

    it 'destroys outcome group if workflow state deleted' do
      # destroy will delete child outcome groups
      parent1.update! learning_outcome_group: existing_group
      importer.import_group(**group_attributes, workflow_state: 'deleted')
      expect(parent1.reload.workflow_state).to eq 'deleted'
    end
  end

  describe '#import_outcome' do
    let_once(:existing_outcome) do
      outcome_model(context: context, vendor_guid: outcome_vendor_guid)
    end

    context 'with canvas_id' do
      it 'fails if outcome not present with that id' do
        missing_id = existing_outcome.destroy_permanently!.id
        expect do
          importer.import_outcome(**outcome_attributes, canvas_id: missing_id)
        end.to raise_error(TestImporter::InvalidDataError, /with canvas id/)
      end

      it 'fails if matching outcome not in visible context' do
        existing_outcome.update! context: other_context
        expect do
          importer.import_outcome(**outcome_attributes, canvas_id: existing_outcome.id)
        end.to raise_error(TestImporter::InvalidDataError, /not in visible context/)
      end

      it 'updates vendor_guid if group in current context' do
        importer.import_outcome(**outcome_attributes)
        expect(existing_outcome.reload.vendor_guid).to eq outcome_vendor_guid
      end
    end

    context 'with vendor_guid' do
      it 'fails if matching outcome not in visible context' do
        existing_outcome.update! context: other_context
        expect do
          importer.import_outcome(**outcome_attributes)
        end.to raise_error(TestImporter::InvalidDataError, /not in visible context/)
      end

      it 'updates if outcome in current context' do
        importer.import_outcome(**outcome_attributes)
        expect(existing_outcome.reload.title).to eq "i'm an outcome"
      end

      it 'imports if outcome in visible context and unchanged' do
        ratings = [{ points: 5, description: 'ok' }, { points: 1, description: 'ohno' }]
        importer.import_outcome(**outcome_attributes, ratings: ratings)
        expect(existing_outcome.reload.title).to eq "i'm an outcome"

        course_importer = TestImporter.new(course)
        course_importer.import_outcome(**outcome_attributes, ratings: ratings)
        expect(LearningOutcomeGroup.for_context(course).first.child_outcome_links.count).to eq(1)
      end

      it 'creates in current context if outcome not found' do
        importer.import_outcome(**outcome_attributes, vendor_guid: 'new_outcome_frd')
        new_outcome = LearningOutcome.find_by(vendor_guid: 'new_outcome_frd')
        expect(new_outcome).not_to eq existing_outcome
        expect(new_outcome.context).to eq context
      end
    end

    it 'updates attributes' do
      importer.import_outcome(**outcome_attributes)
      existing_outcome.reload
      expect(existing_outcome.reload).to have_attributes outcome_attributes
    end

    it 'fails if outcome has already appeared in import' do
      importer.import_outcome(outcome_attributes)
      expect do
        importer.import_outcome(outcome_attributes)
      end.to raise_error TestImporter::InvalidDataError, /already appeared/
    end

    context 'with parents' do
      before do
        [parent1, parent2].each do |p|
          importer.import_group(**group_attributes, vendor_guid: p.vendor_guid)
        end
      end

      it 'assigns correct parents' do
        importer.import_outcome(**outcome_attributes, parent_guids: 'parent1 parent2')
        expect(context.root_outcome_group.child_outcome_links.active).to be_empty
        expect(parent1.child_outcome_links.active.map(&:content)).to include existing_outcome
        expect(parent2.child_outcome_links.active.map(&:content)).to include existing_outcome
      end

      it 'assigns to root outcome group if no parent specified' do
        importer.import_outcome(**outcome_attributes)
        expect(context.root_outcome_group.child_outcome_links.active.map(&:content)).to include existing_outcome
      end

      it 'fails if parents not found' do
        expect do
          importer.import_outcome(**outcome_attributes, parent_guids: 'parent1 parentmissing')
        end.to raise_error(TestImporter::InvalidDataError, /Parent references not found/)
      end

      it 'does not find parents from another context' do
        parent1.update! context: other_context
        expect do
          importer.import_outcome(**outcome_attributes, parent_guids: 'parent1')
        end.to raise_error(TestImporter::InvalidDataError, /Parent references not found/)
      end

      it 'reassigns parents of existing outcome' do
        parent1.add_outcome(existing_outcome)
        importer.import_outcome(**outcome_attributes, parent_guids: 'parent2')
          expect(parent1.child_outcome_links.active.map(&:content)).to be_empty
        expect(parent2.child_outcome_links.active.map(&:content)).to include existing_outcome
      end

      context 'with outcomes from other contexts' do
        let(:parent_context) { account_model }

        before do
          context.update! parent_account: parent_context
          existing_outcome.update! context: parent_context
        end

        it 'does not assign parents when attributes are changed' do
          expect do
            importer.import_outcome(**outcome_attributes, parent_guids: 'parent1')
          end.to raise_error(TestImporter::InvalidDataError, /Cannot modify outcome from another context/)
        end

        it 'assigns parents for outcome in another context if attributes unchanged' do
          existing_outcome.update! outcome_attributes
          importer.import_outcome(**outcome_attributes, parent_guids: 'parent1')
          expect(parent1.child_outcome_links.map(&:content)).to include existing_outcome
        end

        context 'with global context' do
          let(:parent_context) { nil }

          it 'does not assign parents when attributes are changed' do
            expect do
              importer.import_outcome(**outcome_attributes, parent_guids: 'parent1')
            end.to raise_error(TestImporter::InvalidDataError, /Cannot modify .* the global context/)
          end

          it 'assigns parents if attributes are unchanged' do
            existing_outcome.update! outcome_attributes
            importer.import_outcome(**outcome_attributes, parent_guids: 'parent1')
            expect(parent1.child_outcome_links.map(&:content)).to include existing_outcome
          end
        end
      end
    end

    it 'calls destroy on content tag if workflow state is deleted' do
      # deleting last content tag will delete outcome
      importer.import_outcome(**outcome_attributes, workflow_state: 'deleted')
      expect(existing_outcome.reload.workflow_state).to eq 'deleted'
    end
  end
end
