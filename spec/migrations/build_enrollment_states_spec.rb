#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'spec_helper'
require 'db/migrate/20160517153405_build_enrollment_states.rb'

describe 'BuildEnrollmentStates' do
  describe "up" do
    it "should populate all enrollments with enrollment states" do
      # turns out i broke the old migration - oops
      BuildEnrollmentStates.new.down

      course_with_student(:active_all => true)

      expect(@course.enrollments.count).to eq 2

      EnrollmentState.where(:enrollment_id => @course.enrollments.map(&:id)).delete_all
      @course.enrollments.reload
      @course.enrollments.each do |e|
        expect(e.association(:enrollment_state).target).to be_blank
      end

      BuildEnrollmentStates.new.up

      @course.enrollments.reload
      @course.enrollments.each do |e|
        expect(e.enrollment_state).to be_present
      end
    end
  end
end
