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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchHelper do
  
  include SearchHelper

  context "load_all_contexts" do
    it "should return requested permissions" do
      course(:active_all => true)
      @current_user = @teacher
      
      load_all_contexts
      @contexts[:courses][@course.id][:permissions].should be_empty

      load_all_contexts(:permissions => [:manage_assignments])
      @contexts[:courses][@course.id][:permissions][:manage_assignments].should be_true
    end
  end
end
