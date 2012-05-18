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
require 'db/migrate/20111209171640_recalculate_muted_assignments.rb'

describe 'RecalculateMutedAssignments' do
  describe "up" do
    it "should work" do
      c1 = course
      a1 = c1.assignments.create!(:title => "Test Assignment")
      c1.any_instantiation
      c1.expects(:recompute_student_scores).never
      
      c2 = course
      a2 = c2.assignments.create!(:title => "Test Assignment2")
      a2.mute!
      c2.any_instantiation
      c2.expects :recompute_student_scores

      RecalculateMutedAssignments.up

    end
  end
end
