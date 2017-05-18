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

require 'test/unit'
require 'active_record'
require 'acts_as_list'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
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

class Mixin < ActiveRecord::Base
  def self.nulls(first_or_last, column, direction = nil)
    "#{column} IS#{" NOT" unless first_or_last == :last} NULL, #{column} #{direction.to_s.upcase}".strip
  end
end

class ListMixin < Mixin
  acts_as_list :column => "pos", :scope => :parent_id
end

class ListMixinSub1 < ListMixin
end

class ListMixinSub2 < ListMixin
end

class UnscopedListMixin < Mixin
  acts_as_list :column => "pos"
end

class ListTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |counter| ListMixin.create! :pos => counter, :parent_id => 5 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.where('parent_id = 5').order('pos').pluck(:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.where('parent_id = 5').order('pos').pluck(:id)
  end

  def test_injection
    item = ListMixin.new(:parent_id => 1)
    assert_equal({parent_id: 1}, item.scope_condition)
    assert_equal "pos", item.class.position_column
  end

  def test_insert
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos
    assert !new.first?
    assert new.last?

    new = ListMixin.create(:parent_id => 0)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?
  end

  def test_insert_at
    new = ListMixin.create(:parent_id => 20)
    assert_equal 1, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 2, new.pos

    new = ListMixin.create(:parent_id => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create(:parent_id => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixin.create(:parent_id => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy
    assert_equal [3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

  def test_nil_scope
    new1, new2, new3 = UnscopedListMixin.create, UnscopedListMixin.create, UnscopedListMixin.create
    new2.move_to_top
    assert_equal [new2, new1, new3], UnscopedListMixin.where('parent_id IS NULL').order('pos').to_a
  end


  def test_remove_from_list_should_then_fail_in_list?
    assert_equal true, ListMixin.find(1).in_list?
    ListMixin.find(1).remove_from_list
    assert_equal false, ListMixin.find(1).in_list?
  end

  def test_remove_from_list_should_set_position_to_nil
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(2).remove_from_list

    assert_equal [2, 1, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    assert_equal 1,   ListMixin.find(1).pos
    assert_equal nil, ListMixin.find(2).pos
    assert_equal 2,   ListMixin.find(3).pos
    assert_equal 3,   ListMixin.find(4).pos
  end

  def test_remove_before_destroy_does_not_shift_lower_items_twice
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    ListMixin.find(2).remove_from_list
    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.where('parent_id = 5').order('pos').pluck(:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos
  end

end

class ListSubTest < Test::Unit::TestCase

  def setup
    setup_db
    (1..4).each { |i| ((i % 2 == 1) ? ListMixinSub1 : ListMixinSub2).create! :pos => i, :parent_id => 5000 }
  end

  def teardown
    teardown_db
  end

  def test_reordering
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    ListMixin.find(1).move_to_bottom
    assert_equal [2, 3, 4, 1], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    ListMixin.find(1).move_to_top
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    ListMixin.find(2).move_to_bottom
    assert_equal [1, 3, 4, 2], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    ListMixin.find(4).move_to_top
    assert_equal [4, 1, 3, 2], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)
  end

  def test_move_to_bottom_with_next_to_last_item
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)
    ListMixin.find(3).move_to_bottom
    assert_equal [1, 2, 4, 3], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)
  end

  def test_injection
    item = ListMixin.new("parent_id"=>1)
    assert_equal({parent_id: 1}, item.scope_condition)
    assert_equal "pos", item.class.position_column
  end

  def test_insert_at
    new = ListMixin.create("parent_id" => 20)
    assert_equal 1, new.pos

    new = ListMixinSub1.create("parent_id" => 20)
    assert_equal 2, new.pos

    new = ListMixinSub2.create("parent_id" => 20)
    assert_equal 3, new.pos

    new4 = ListMixin.create("parent_id" => 20)
    assert_equal 4, new4.pos

    new4.insert_at(3)
    assert_equal 3, new4.pos

    new.reload
    assert_equal 4, new.pos

    new.insert_at(2)
    assert_equal 2, new.pos

    new4.reload
    assert_equal 4, new4.pos

    new5 = ListMixinSub1.create("parent_id" => 20)
    assert_equal 5, new5.pos

    new5.insert_at(1)
    assert_equal 1, new5.pos

    new4.reload
    assert_equal 5, new4.pos
  end

  def test_delete_middle
    assert_equal [1, 2, 3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    ListMixin.find(2).destroy

    assert_equal [1, 3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    assert_equal 1, ListMixin.find(1).pos
    assert_equal 2, ListMixin.find(3).pos
    assert_equal 3, ListMixin.find(4).pos

    ListMixin.find(1).destroy

    assert_equal [3, 4], ListMixin.where('parent_id = 5000').order('pos').pluck(:id)

    assert_equal 1, ListMixin.find(3).pos
    assert_equal 2, ListMixin.find(4).pos
  end

end
