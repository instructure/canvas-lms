# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../qti_helper')
if Qti.migration_executable
describe "QTI Migration Tool" do
   it "should get assessment identifier if set" do
     File.open(File.join(CANVAS_FIXTURE_DIR, 'empty_assessment.xml.qti'), 'r') do |file|
       hash = Qti.convert_xml(file.read, :file_name => "not_the_identifier.xml.qti").last.first
       expect(hash[:migration_id]).to eq 'i09d7615b43e5f35589cc1e2647dd345f'
     end
   end
   it "should use filename as identifier if none set" do
     File.open(File.join(CANVAS_FIXTURE_DIR, 'empty_assessment_no_ident.xml'), 'r') do |file|
       hash = Qti.convert_xml(file.read, :file_name => "the_identifier.xml").last.first
       expect(hash[:migration_id]).to eq 'the_identifier'
     end
   end
end
end
