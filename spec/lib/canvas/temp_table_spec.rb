#
# Copyright (C) 2013 Instructure, Inc.
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

describe "Canvas::TempTable" do
  before do
    c1 = course(:name => 'course1', :active_course => true)
    c2 = course(:name => 'course2', :active_course => true)
    u1 = user(:name => 'user1', :active_user => true)
    u2 = user(:name => 'user2', :active_user => true)
    u3 = user(:name => 'user3', :active_user => true)
    @e1 = c1.enroll_student(u1, :enrollment_state => 'active')
    @e2 = c1.enroll_student(u2, :enrollment_state => 'active')
    @e3 = c1.enroll_student(u3, :enrollment_state => 'active')
    @e4 = c2.enroll_student(u1, :enrollment_state => 'active')
    @e5 = c2.enroll_student(u2, :enrollment_state => 'active')
    @e6 = c2.enroll_student(u3, :enrollment_state => 'active')
    @scope = Course.active.scoped(:select => "enrollments.id AS e_id",
                                  :joins => :enrollments, :order => "e_id asc")
    @sql = @scope.construct_finder_sql({})
  end

  it "should not create a temp table before executing" do
    temp_table = Canvas::TempTable.new(@scope.connection, @sql)
    table = temp_table.name
    expect { @scope.connection.select_all("select * from #{table}") }.to raise_error
  end

  it "should create a temp table then destroy it" do
    temp_table = Canvas::TempTable.new(@scope.connection, @sql)
    table = temp_table.name

    temp_table.execute! do
      @scope.connection.select_all("select * from #{table}").length.should == 6
    end
    expect { @scope.connection.select_all("select * from #{table}") }.to raise_error
  end

  it "should give me the length of the table" do
    temp_table = Canvas::TempTable.new(@scope.connection, @sql)
    temp_table.execute! do
      temp_table.size.should == 6
    end
  end
end
