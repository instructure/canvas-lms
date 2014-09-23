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
    course(:active_course => true)
    a1 = Assignment.create!(context: @course, title: 'hi1')
    a2 = Assignment.create!(context: @course, title: 'hi2')
    a3 = Assignment.create!(context: @course, title: 'hi3')

    Assignment.where(id: a2.id).update_all(allowed_extensions: ['doc', 'xsl'].to_yaml)
    Assignment.where(id: a3.id).update_all(allowed_extensions: ['.DOC', ' .XSL'].to_yaml)

    DataFixup::ResanitizeAssignmentsAllowedExtensions.run

    a1.reload.allowed_extensions.should == []
    a2.reload.allowed_extensions.should == ['doc', 'xsl']
    a3.reload.allowed_extensions.should == ['doc', 'xsl']
  end
end
