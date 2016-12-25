#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "acts_as_list" do
  describe "#update_order" do
    it "should cast id input" do
      a1 = attachment_model
      a2 = attachment_model
      a3 = attachment_model
      a4 = attachment_model
      list = a1.list_scope
      a1.update_order([a2.id, a3.id, a1.id])
      expect(list.pluck(:id)).to eq [a2.id, a3.id, a1.id, a4.id]
      a1.update_order(["SELECT now()", a3.id, "evil stuff"])
      expect(list.pluck(:id)).to eq [a3.id, a2.id, a1.id, a4.id]
    end
  end

  describe "#insert_at" do
    before :each do
      course_factory
      @module_1 = @course.context_modules.create!(:name => "another module")
      @module_2 = @course.context_modules.create!(:name => "another module")
      @module_3 = @course.context_modules.create!(:name => "another module")

      @modules = [@module_1, @module_2, @module_3]
    end

    it "should insert in the position correctly" do
      expect(@modules.map(&:position)).to eq [1, 2, 3]

      expect(@module_1.insert_at(3)).to eq true
      @modules.each{|m| m.reload}
      expect(@modules.map(&:position)).to eq [3, 1, 2]

      expect(@module_2.insert_at(2)).to eq true
      @modules.each{|m| m.reload}
      expect(@modules.map(&:position)).to eq [3, 2, 1]

      expect(@module_3.insert_at(3)).to eq true
      @modules.each{|m| m.reload}
      expect(@modules.map(&:position)).to eq [2, 1, 3]

      expect(@module_1.insert_at(1)).to eq true
      @modules.each{|m| m.reload}
      expect(@modules.map(&:position)).to eq [1, 2, 3]
    end
  end

  describe "#fix_position_conflicts" do
    it "should order null positions last" do
      course_factory
      module_1 = @course.context_modules.create :name => 'one'
      ContextModule.where(id: module_1).update_all(position: nil)
      module_2 = @course.context_modules.create :name => 'two'
      module_2.position = 1
      module_2.save!
      module_1.fix_position_conflicts
      expect(@course.context_modules.map{|m| [m.id, m.position]}).to eql [[module_2.id, 1], [module_1.id, 2]]
    end

    it "should break ties by object id" do
      course_factory
      module_1 = @course.context_modules.create :name => 'one'
      module_1.position = 1
      module_1.save!
      module_2 = @course.context_modules.create :name => 'two'
      module_2.position = 1
      module_2.save!
      module_1.fix_position_conflicts
      expect(@course.context_modules.map{|m| [m.id, m.position]}).to eql [[module_1.id, 1], [module_2.id, 2]]
    end

    it "should consolidate gaps" do
      course_factory
      module_1 = @course.context_modules.create :name => 'one'
      module_1.position = 1
      module_1.save!
      module_2 = @course.context_modules.create :name => 'two'
      module_2.position = 3
      module_2.save!
      module_1.fix_position_conflicts
      expect(@course.context_modules.map{|m| [m.id, m.position]}).to eql [[module_1.id, 1], [module_2.id, 2]]
    end
  end

  describe "base scope" do
    it "scopes by the base class rather then the STI class" do
      scope = AccountAuthorizationConfig::CAS.new.list_scope_base
      expect(scope.to_sql).to_not(match(/auth_type/))
    end
  end
end
