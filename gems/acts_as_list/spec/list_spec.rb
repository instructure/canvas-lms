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

require "active_record"
require "acts_as_list"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

class Mixin < ActiveRecord::Base
end

class ListMixin < Mixin
  acts_as_list column: "pos", scope: :parent_id
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class UnscopedListMixin < Mixin
  acts_as_list column: "pos"
end

describe "ListTest" do
  after do
    teardown_db
  end

  describe do
    before do
      setup_db
      (1..4).each { |counter| ListMixin.create! pos: counter, parent_id: 5 }
    end

    it "reordering" do
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(1).move_to_bottom
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [2, 3, 4, 1]

      ListMixin.find(1).move_to_top
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).move_to_bottom
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 3, 4, 2]

      ListMixin.find(4).move_to_top
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [4, 1, 3, 2]
    end

    it "move_to_bottom with next to last" do
      ListMixin.find(3).move_to_bottom
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 4, 3]
    end

    it "injection" do
      item = ListMixin.new(parent_id: 1)
      expect(item.scope_condition).to eq parent_id: 1
      expect(item.class.position_column).to eq "pos"
    end

    it "insert" do
      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 1
      expect(new).to be_first
      expect(new).to be_last

      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 2
      expect(new).to_not be_first
      expect(new).to be_last

      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 3
      expect(new).to_not be_first
      expect(new).to be_last

      new = ListMixin.create(parent_id: 0)
      expect(new.pos).to eq 1
      expect(new).to be_first
      expect(new).to be_last
    end

    it "insert_at" do
      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 1

      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 2

      new = ListMixin.create(parent_id: 20)
      expect(new.pos).to eq 3

      new4 = ListMixin.create(parent_id: 20)
      expect(new4.pos).to eq 4

      new4.insert_at(3)
      expect(new4.pos).to eq 3

      new.reload
      expect(new.pos).to eq 4

      new.insert_at(2)
      expect(new.pos).to eq 2

      new4.reload
      expect(new4.pos).to eq 4

      new5 = ListMixin.create(parent_id: 20)
      expect(new5.pos).to eq 5

      new5.insert_at(1)
      expect(new5.pos).to eq 1

      new4.reload
      expect(new4.pos).to eq 5
    end

    it "delete middle" do
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).destroy
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 3, 4]

      expect(ListMixin.find(1).pos).to eq 1
      expect(ListMixin.find(3).pos).to eq 2
      expect(ListMixin.find(4).pos).to eq 3

      ListMixin.find(1).destroy
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [3, 4]

      expect(ListMixin.find(3).pos).to eq 1
      expect(ListMixin.find(4).pos).to eq 2
    end

    it "nil scope" do
      new1, new2, new3 = UnscopedListMixin.create, UnscopedListMixin.create, UnscopedListMixin.create
      new2.move_to_top
      expect(UnscopedListMixin.where(parent_id: nil).order("pos").to_a).to eq [new2, new1, new3]
    end

    it "remove_from_list should then fail in_list?" do
      expect(ListMixin.find(1)).to be_in_list
      ListMixin.find(1).remove_from_list
      expect(ListMixin.find(1)).to_not be_in_list
    end

    it "remove_from_list should set position to nil" do
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).remove_from_list
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [2, 1, 3, 4]

      expect(ListMixin.find(1).pos).to eq 1
      expect(ListMixin.find(2).pos).to be_nil
      expect(ListMixin.find(3).pos).to eq 2
      expect(ListMixin.find(4).pos).to eq 3
    end

    it "remove before destroy does not shift lower items twice" do
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).remove_from_list
      ListMixin.find(2).destroy
      expect(ListMixin.where("parent_id = 5").order("pos").pluck(:id)).to eq [1, 3, 4]

      expect(ListMixin.find(1).pos).to eq 1
      expect(ListMixin.find(3).pos).to eq 2
      expect(ListMixin.find(4).pos).to eq 3
    end
  end

  describe "SubTest" do
    before do
      setup_db
      (1..4).each { |i| (i.odd? ? ListMixinSub1 : ListMixinSub2).create! pos: i, parent_id: 5000 }
    end

    it "reordering" do
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(1).move_to_bottom
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [2, 3, 4, 1]

      ListMixin.find(1).move_to_top
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).move_to_bottom
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 3, 4, 2]

      ListMixin.find(4).move_to_top
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [4, 1, 3, 2]
    end

    it "move_to_bottom with next to last item" do
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 2, 3, 4]
      ListMixin.find(3).move_to_bottom
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 2, 4, 3]
    end

    it "injection" do
      item = ListMixin.new("parent_id" => 1)
      expect(item.scope_condition).to eq parent_id: 1
      expect(item.class.position_column).to eq "pos"
    end

    it "insert_at" do
      new = ListMixin.create("parent_id" => 20)
      expect(new.pos).to eq 1

      new = ListMixinSub1.create("parent_id" => 20)
      expect(new.pos).to eq 2

      new = ListMixinSub2.create("parent_id" => 20)
      expect(new.pos).to eq 3

      new4 = ListMixin.create("parent_id" => 20)
      expect(new4.pos).to eq 4

      new4.insert_at(3)
      expect(new4.pos).to eq 3

      new.reload
      expect(new.pos).to eq 4

      new.insert_at(2)
      expect(new.pos).to eq 2

      new4.reload
      expect(new4.pos).to eq 4

      new5 = ListMixinSub1.create("parent_id" => 20)
      expect(new5.pos).to eq 5

      new5.insert_at(1)
      expect(new5.pos).to eq 1

      new4.reload
      expect(new4.pos).to eq 5
    end

    it "delete middle" do
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 2, 3, 4]

      ListMixin.find(2).destroy
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [1, 3, 4]

      expect(ListMixin.find(1).pos).to eq 1
      expect(ListMixin.find(3).pos).to eq 2
      expect(ListMixin.find(4).pos).to eq 3

      ListMixin.find(1).destroy
      expect(ListMixin.where("parent_id = 5000").order("pos").pluck(:id)).to eq [3, 4]

      expect(ListMixin.find(3).pos).to eq 1
      expect(ListMixin.find(4).pos).to eq 2
    end
  end

  def setup_db
    ActiveRecord::Schema.define(version: 1) do
      create_table :mixins do |t|
        t.column :pos, :integer
        t.column :parent_id, :integer
        t.column :created_at, :datetime
        t.column :updated_at, :datetime
      end
    end
  end

  def teardown_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end
