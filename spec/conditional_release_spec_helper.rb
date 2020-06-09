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

require_relative 'factory_bot_spec_helper'

RSpec.shared_examples 'a soft-deletable model' do
  it { is_expected.to have_db_column(:deleted_at) }

  it 'adds a deleted_at where clause when requested' do
    expect(described_class.active.all.to_sql).to include('"deleted_at" IS NULL')
  end

  it 'skips adding the deleted_at where clause normally' do
    # sorry - no default scopes
    expect(described_class.all.to_sql).not_to include('deleted_at')
  end

  it 'soft deletes' do
    instance = create described_class.name.underscore.sub("conditional_release/", "").to_sym
    instance.destroy!
    expect(described_class.exists?(instance.id)).to be true
    expect(described_class.active.exists?(instance.id)).to be false
  end

  it 'allows duplicates on unique attributes when one instance is soft deleted' do
    instance = create described_class.name.underscore.sub("conditional_release/", "").to_sym
    copy = instance.clone
    instance.destroy!
    expect { copy.save! }.to_not raise_error
  end
end
