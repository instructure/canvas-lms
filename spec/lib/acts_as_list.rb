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
      Attachment.expects(:update_all).with("position=CASE WHEN id=#{a2.id} THEN 1 WHEN id=#{a3.id} THEN 2 WHEN id=#{a1.id} THEN 3 WHEN id=#{a4.id} THEN 4 ELSE 0 END", anything)
      Attachment.expects(:update_all).with("position=CASE WHEN id=#{a3.id} THEN 1 WHEN id=#{a1.id} THEN 2 WHEN id=#{a2.id} THEN 3 WHEN id=#{a4.id} THEN 4 ELSE 0 END", anything)
      a1.update_order([a2.id, a3.id, a1.id])
      a1.update_order(["SELECT now()", a3.id, "evil stuff"])
    end
  end

  describe "#insert_at_position" do
    before :each do
      course
      @module_1 = @course.context_modules.create!(:name => "another module")
      @module_2 = @course.context_modules.create!(:name => "another module")
      @module_3 = @course.context_modules.create!(:name => "another module")

      @modules = [@module_1, @module_2, @module_3]
    end

    it "should insert in the position correctly" do
      @modules.map(&:position).should == [1, 2, 3]

      @module_1.insert_at_position(3).should == true
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [3, 1, 2]

      @module_2.insert_at_position(2).should == true
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [3, 2, 1]

      @module_3.insert_at_position(3).should == true
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [2, 1, 3]

      @module_1.insert_at_position(1).should == true
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [1, 2, 3]
    end

    it "should handle positions outside range" do
      @module_2.insert_at_position(-10).should == false # do nothing
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [1, 2, 3]

      @module_3.insert_at_position(0).should == false # do nothing
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [1, 2, 3]

      @module_1.insert_at_position(4).should == false # do nothing
      @modules.each{|m| m.reload}
      @modules.map(&:position).should == [1, 2, 3]
    end
  end
end

