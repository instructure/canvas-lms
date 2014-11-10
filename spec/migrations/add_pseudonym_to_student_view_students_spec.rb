#
# Copyright (C) 2012 Instructure, Inc.
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

describe "AddPseudonymToStudentViewStudents" do
  it "works" do
    course_with_teacher(:active_user => true)
    @c1 = @course
    @fake1 = @c1.student_view_student

    course_with_teacher(:active_user => true)
    @c2 = @course
    @fake2 = @c2.student_view_student

    course_with_teacher(:active_user => true)
    @c3 = @course
    @c3.course_sections.create!(:name => "Sec 1")
    @c3.course_sections.create!(:name => "Sec 2")
    @c3.course_sections.create!(:name => "Sec 3")
    @fake3 = @c3.student_view_student

    # remove these two students' pseudonyms
    @fake2.pseudonym.destroy!
    @fake3.pseudonym.destroy!

    expect(@fake1.reload.pseudonym).not_to be_nil
    expect(@fake2.reload.pseudonym).to be_nil
    expect(@fake3.reload.pseudonym).to be_nil

    DataFixup::AddPseudonymToStudentViewStudents.run

    expect(@fake1.reload.pseudonyms.count).to eql 1
    expect(@fake2.reload.pseudonyms.count).to eql 1
    expect(@fake3.reload.pseudonyms.count).to eql 1

    expect(@fake1.reload.pseudonym.unique_id).to eql Canvas::Security.hmac_sha1("Test Student_#{@fake1.id}")
    expect(@fake2.reload.pseudonym.unique_id).to eql Canvas::Security.hmac_sha1("Test Student_#{@fake2.id}")
    expect(@fake3.reload.pseudonym.unique_id).to eql Canvas::Security.hmac_sha1("Test Student_#{@fake3.id}")
  end
end
