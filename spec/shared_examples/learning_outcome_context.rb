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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

shared_examples_for 'a learning outcome context' do
  let_once(:outcome_context) { described_class.create name: 'Foo' }

  describe 'root_outcome_group' do
    it 'creates a root outcome group' do
      root = outcome_context.root_outcome_group
      expect(root).not_to be_nil
      expect(root.title).to eq 'Foo'
      expect(root.context).to eq outcome_context
    end

    it 'returns an existing root outcome group' do
      root1 = outcome_context.root_outcome_group
      root2 = outcome_context.root_outcome_group
      expect(root1).to eq root2
    end

    it 'does not create a root outcome group if force is false' do
      root = outcome_context.root_outcome_group(false)
      expect(root).to be_nil
    end
  end

  describe 'update_root_outcome_group_name' do
    let_once(:root) { outcome_context.root_outcome_group }

    it 'updates the root name' do
      outcome_context.update! name: 'Bar'
      expect(root.reload.title).to eq 'Bar'
    end

    it 'updates outside of primary transaction' do
      allow(outcome_context).to receive(:root_outcome_group).and_return(root)
      expect(root).to receive(:update!).and_raise('Ha ha!')

      expect { outcome_context.update! name: 'Bar' }.to raise_error('Ha ha!')
      expect(outcome_context.reload.name).to eq 'Bar' # transaction completed
      expect(root.reload.title).to eq 'Foo'           # after_transaction failed
    end

    it 'does not update if name is not changed' do
      allow(outcome_context).to receive(:root_outcome_group).and_return(root)
      expect(root).not_to receive(:update!)
      outcome_context.update! workflow_state: 'deleted'
    end
  end
end
