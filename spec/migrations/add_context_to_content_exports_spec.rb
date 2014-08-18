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
require 'db/migrate/20140530195058_add_context_to_content_exports.rb'
require 'db/migrate/20140530195059_remove_course_id_from_content_exports.rb'

describe 'AddContextToContentExports' do
  describe "up" do
    it "should populate all content exports with course context type and context id" do
      pending("PostgreSQL specific") unless ContentExport.connection.adapter_name == 'PostgreSQL'
      course1 = course
      course2 = course

      RemoveCourseIdFromContentExports.down
      AddContextToContentExports.down

      ContentExport.connection.execute "INSERT INTO content_exports(course_id, workflow_state, created_at, updated_at) VALUES(#{course1.id}, '', '2014-07-07', '2014-07-07')"

      AddContextToContentExports.up
      ContentExport.connection.execute "INSERT INTO content_exports(course_id, workflow_state, created_at, updated_at) VALUES(#{course2.id}, '', '2014-07-07', '2014-07-07')"
      RemoveCourseIdFromContentExports.up

      ce1 = course1.content_exports.first
      ce2 = course2.content_exports.first
      ce1.context_type.should == 'Course'
      ce1.context_id = course1.id
      ce2.context_type.should == 'Course'
      ce2.context_id.should == course2.id
    end
  end
end
