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
require 'lib/data_fixup/resanitize_assignments_allowed_extensions.rb'

describe 'DataFixup::ResanitizeAssignmentsAllowedExtensions' do
  it "should correct only assignments that aren't sanitized" do
    course_factory(active_course: true)
    a1 = Assignment.create!(context: @course, title: 'hi1')
    a2 = Assignment.create!(context: @course, title: 'hi2')
    a3 = Assignment.create!(context: @course, title: 'hi3')

    ActiveRecord::Base.connection.execute("UPDATE #{Assignment.quoted_table_name} SET allowed_extensions = '#{['doc', 'xsl'].to_yaml}' WHERE id = #{a2.id}")
    ActiveRecord::Base.connection.execute("UPDATE #{Assignment.quoted_table_name} SET allowed_extensions = '#{['.DOC', ' .XSL'].to_yaml}' WHERE id = #{a3.id}")

    DataFixup::ResanitizeAssignmentsAllowedExtensions.run

    expect(a1.reload.allowed_extensions).to eq []
    expect(a2.reload.allowed_extensions).to eq ['doc', 'xsl']
    expect(a3.reload.allowed_extensions).to eq ['doc', 'xsl']
  end
end
