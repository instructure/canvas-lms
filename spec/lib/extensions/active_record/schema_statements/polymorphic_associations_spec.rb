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
#

describe Extensions::ActiveRecord::SchemaStatements::PolymorphicAssociations do
  subject(:connection) { ActiveRecord::Base.connection }

  it "adds and removes separate columns and check constraint for a new 'polymorphic' reference" do
    connection.add_reference :users, :asset, polymorphic: %i[assignment submission attachment], null: false

    expect(connection.column_exists?(:users, :assignment_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :submission_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :attachment_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :asset_id)).to be false
    expect(connection.column_exists?(:users, :asset_type)).to be false
    expect(connection.index_exists?(:users, :assignment_id, where: "(assignment_id IS NOT NULL)")).to be true
    expect(connection.check_constraint_exists?(:users,
                                               name: "chk_require_asset",
                                               expression: "(assignment_id IS NOT NULL)::int + (submission_id IS NOT NULL)::int + (attachment_id IS NOT NULL)::int = 1"))
      .to be true

    connection.remove_reference :users, :asset, polymorphic: %i[assignment submission attachment], null: false

    expect(connection.column_exists?(:users, :assignment_id)).to be false
    expect(connection.column_exists?(:users, :submission_id)).to be false
    expect(connection.column_exists?(:users, :attachment_id)).to be false
    expect(connection.column_exists?(:users, :asset_id)).to be false
    expect(connection.column_exists?(:users, :asset_type)).to be false
    expect(connection.index_exists?(:users, :assignment_id)).to be false
    expect(connection.check_constraint_exists?(:users, name: "chk_require_asset")).to be false
  end

  it "adds columns in a change_table block" do
    connection.change_table :users, bulk: true do |t|
      t.references :asset, polymorphic: %i[assignment submission attachment], null: false
    end

    expect(connection.column_exists?(:users, :assignment_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :submission_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :attachment_id, :integer, limit: 8, null: true)).to be true
    expect(connection.column_exists?(:users, :asset_id)).to be false
    expect(connection.column_exists?(:users, :asset_type)).to be false
    expect(connection.index_exists?(:users, :assignment_id, where: "(assignment_id IS NOT NULL)")).to be true
    expect(connection.check_constraint_exists?(:users,
                                               name: "chk_require_asset",
                                               expression: "(assignment_id IS NOT NULL)::int + (submission_id IS NOT NULL)::int + (attachment_id IS NOT NULL)::int = 1"))
      .to be true

    connection.change_table :users, bulk: true do |t|
      t.remove_references :asset, polymorphic: %i[assignment submission attachment], null: false
    end

    expect(connection.column_exists?(:users, :assignment_id)).to be false
    expect(connection.column_exists?(:users, :submission_id)).to be false
    expect(connection.column_exists?(:users, :attachment_id)).to be false
    expect(connection.column_exists?(:users, :asset_id)).to be false
    expect(connection.column_exists?(:users, :asset_type)).to be false
    expect(connection.index_exists?(:users, :assignment_id)).to be false
    expect(connection.check_constraint_exists?(:users, name: "chk_require_asset")).to be false
  end

  it "adds an appropriate check constraint for a nullable 'polymorphic' reference" do
    connection.add_reference :users, :asset, polymorphic: %i[assignment submission attachment], null: true

    expect(connection.check_constraint_exists?(:users,
                                               name: "chk_asset_disjunction",
                                               expression: "(assignment_id IS NOT NULL)::int + (submission_id IS NOT NULL)::int + (attachment_id IS NOT NULL)::int <= 1"))
      .to be true
  end
end
