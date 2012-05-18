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
require 'db/migrate/20111209000047_fix_spelling_of_privileges_column_on_enrollments.rb'

describe 'FixSpellingOfPrivilegesColumnOnEnrollments' do
  describe "existing records" do
    before do
      course_with_teacher
      @enrollment = @course.enroll_user @user, 'StudentEnrollment'
      FixSpellingOfPrivilegesColumnOnEnrollments.down
      Enrollment.reset_column_information
    end

    context "get values" do
      it "should preserve a true value across the migration" do
        Enrollment.update_all({ :limit_priveleges_to_course_section => true }, { :id => @enrollment.id } )
        run_migration(@enrollment)
        @enrollment.limit_priveleges_to_course_section.should eql true
        @enrollment.limit_privileges_to_course_section.should eql true
      end

      it "should preserve a false value across the migration" do
        Enrollment.update_all({ :limit_priveleges_to_course_section => false }, { :id => @enrollment.id } )
        run_migration(@enrollment)
        @enrollment.limit_priveleges_to_course_section.should eql false
        @enrollment.limit_privileges_to_course_section.should eql false
      end
    end

    context "set values" do
      it "should allow setting of properly spelled column" do
        Enrollment.update_all({ :limit_priveleges_to_course_section => true }, { :id => @enrollment.id } )
        run_migration(@enrollment)
        @enrollment.limit_privileges_to_course_section = false
        @enrollment.save
        @enrollment.limit_priveleges_to_course_section.should eql false
        @enrollment.limit_privileges_to_course_section.should eql false
      end

      it "should allow setting of improperly spelled column" do
        Enrollment.update_all({ :limit_priveleges_to_course_section => true }, { :id => @enrollment.id } )
        run_migration(@enrollment)
        @enrollment.limit_priveleges_to_course_section = false
        @enrollment.limit_priveleges_to_course_section.should eql false
        @enrollment.limit_privileges_to_course_section.should eql false
      end
    end
  end

  # helpers
  def run_migration(enrollment)
    FixSpellingOfPrivilegesColumnOnEnrollments.up
    Enrollment.reset_column_information
    enrollment.reload if enrollment.present?
  end
end

