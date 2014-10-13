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
      expect(@contexts[:courses][@course.id][:permissions]).to be_empty

      load_all_contexts(:permissions => [:manage_assignments])
      expect(@contexts[:courses][@course.id][:permissions][:manage_assignments]).to be_truthy
    end

    it "only loads the section and its course when given a section context" do
      course_with_teacher(:active_all => true)
      course_with_teacher(:active_all => true, :user => @teacher)
      @current_user = @teacher
      second_section = @course.course_sections.create!(:name => 'second section')
      load_all_contexts(context: second_section)

      expect(@contexts[:courses].count).to eq 1
      expect(@contexts[:sections].count).to eq 1
    end

    describe "sharding" do
      specs_require_sharding

      before do
        @current_user = @shard1.activate{ user(:active_all => true) }
        @shard2.activate{ course_with_teacher(:account => Account.create!, :user => @current_user, :active_all => true) }
      end

      it "should include courses from shards other than the user's native shard" do
        load_all_contexts
        expect(@contexts[:courses]).to have_key(@course.id)
      end

      it "should include sections from shards other than the user's native shard" do
        # needs at least two sections for any sections to show up
        second_section = @course.course_sections.create!(:name => 'second section')
        load_all_contexts
        expect(@contexts[:sections]).to have_key(second_section.id)
      end
    end
  end
end
