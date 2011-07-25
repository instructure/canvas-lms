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

describe EnrollmentDateRestrictions do
  describe "enrollment_dates_for" do
    it "should grab the enrollments dates first, if defined" do
      course_with_student(:active_all => true)
      start_at = 2.days.ago
      end_at = 2.days.from_now
      @enrollment.start_at = start_at
      @enrollment.end_at = end_at
      @enrollment.save!
      @enrollment.start_at.should_not be_nil
      @enrollment.end_at.should_not be_nil
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([start_at, end_at].map(&:to_i))
      
      @enrollment.end_at = nil
      @enrollment.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).should eql([nil, nil])
    end
    
    it "should grab the section dates if defined and enabled, and no enrollment dates set" do
      course_with_student(:active_all => true)
      @section = @course.course_sections.first
      @section.should_not be_nil
      start_at = 2.days.ago
      end_at = 2.days.from_now
      @enrollment.course_section = @section
      @enrollment.save!
      @section.start_at = start_at
      @section.end_at = end_at
      @section.restrict_enrollments_to_section_dates = true
      @section.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([start_at, end_at].map(&:to_i))

      @section.restrict_enrollments_to_section_dates = false
      @section.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).should eql([nil, nil])
    end
    
    it "should grab the course dates if defined and enabled, and no section or enrollment dates set" do
      course_with_student(:active_all => true)
      start_at = 2.days.ago
      end_at = 2.days.from_now
      @course.start_at = start_at
      @course.conclude_at = end_at
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([start_at, end_at].map(&:to_i))
      
      @course.restrict_enrollments_to_course_dates = false
      @course.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).should eql([nil, nil])
    end
    
    it "should grab the override dates if defined, and no course or section or enrollment dates set" do
      course_with_student(:active_all => true)
      start_at = 2.days.ago
      end_at = 2.days.from_now
      @term = @course.enrollment_term
      @term.should_not be_nil
      @term.save!
      @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term, :start_at => start_at, :end_at => end_at)
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([start_at, end_at].map(&:to_i))

      @term.ignore_term_date_restrictions = true
      @term.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([nil, nil].map(&:to_i))
    end
    
    it "should grab the term dates if defined, and no override or course or section or enrollment dates set" do
      course_with_student(:active_all => true)
      start_at = 2.days.ago
      end_at = 2.days.from_now
      @term = @course.enrollment_term
      @term.should_not be_nil
      @term.start_at = start_at
      @term.end_at = end_at
      @term.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([start_at, end_at].map(&:to_i))

      @term.ignore_term_date_restrictions = true
      @term.save!
      @course = Course.find(@course.id)
      @course.enrollment_dates_for(@enrollment).map(&:to_i).should eql([nil, nil].map(&:to_i))
    end
    
    it "should return nil if no dates are set or enabled" do
      course_with_student(:active_all => true)
      @course.enrollment_dates_for(@enrollment).should eql([nil, nil])
    end
  end
  
  describe "update_restricted_enrollments" do
    describe "should activate inactive enrollments once start_at has passed" do
      it "should work on the enrollment model" do
        course_with_student(:active_all => true)
        start_at = 2.days.ago
        end_at = 2.days.from_now
        @enrollment.start_at = start_at
        @enrollment.end_at = end_at
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@enrollment)
        @enrollment.reload.state.should eql(:active)
      end
      
      it "should work on the course_section model" do
        course_with_student(:active_all => true)
        @section = @course.course_sections.first
        @section.should_not be_nil
        start_at = 2.days.ago
        end_at = 2.days.from_now
        @enrollment.course_section = @section
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @section.start_at = start_at
        @section.end_at = end_at
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@section)
        @enrollment.reload.state.should eql(:active)

        @section.restrict_enrollments_to_section_dates = false
        @section.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@section)
        @enrollment.reload.state.should eql(:inactive)
      end
      
      it "should work on the course model" do
        course_with_student(:active_all => true)
        start_at = 2.days.ago
        end_at = 2.days.from_now
        @course.start_at = start_at
        @course.conclude_at = end_at
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@course)
        @enrollment.reload.state.should eql(:active)
        
        @course.restrict_enrollments_to_course_dates = false
        @course.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@course)
        @enrollment.reload.state.should eql(:inactive)
      end
      
      it "should work on the enrollment_dates_override model" do
        course_with_student(:active_all => true)
        start_at = 2.days.ago
        end_at = 2.days.from_now
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term, :start_at => start_at, :end_at => end_at)
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@override)
        @enrollment.reload.state.should eql(:active)
        
        @term.ignore_term_date_restrictions = true
        @term.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        @override.reload
        EnrollmentDateRestrictions.update_restricted_enrollments(@override)
        @enrollment.reload.state.should eql(:inactive)
      end
      
      it "should work on the enrollment_term model" do
        course_with_student(:active_all => true)
        start_at = 2.days.ago
        end_at = 2.days.from_now
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.start_at = start_at
        @term.end_at = end_at
        @term.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@term)
        @enrollment.reload.state.should eql(:active)
        
        @term.ignore_term_date_restrictions = true
        @term.save!
        @enrollment.workflow_state = 'inactive'
        @enrollment.save!
        @enrollment.state.should eql(:inactive)
        EnrollmentDateRestrictions.update_restricted_enrollments(@term)
        @enrollment.reload.state.should eql(:inactive)
      end
    end
    
    describe "should complete active enrollments once end_at has passed" do
      it "should work on the enrollment model" do
        course_with_student(:active_all => true)
        start_at = 4.days.ago
        end_at = 2.days.ago
        @enrollment.start_at = start_at
        @enrollment.end_at = end_at
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@enrollment)
        @enrollment.reload.state.should eql(:completed)
      end
      
      it "should work on the course_section model" do
        course_with_student(:active_all => true)
        @section = @course.course_sections.first
        @section.should_not be_nil
        start_at = 4.days.ago
        end_at = 2.days.ago
        @enrollment.course_section = @section
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @section.start_at = start_at
        @section.end_at = end_at
        @section.restrict_enrollments_to_section_dates = true
        @section.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@section)
        @enrollment.reload.state.should eql(:completed)

        @section.restrict_enrollments_to_section_dates = false
        @section.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@section)
        @enrollment.reload.state.should eql(:active)
      end
      
      it "should work on the course model" do
        course_with_student(:active_all => true)
        start_at = 4.days.ago
        end_at = 2.days.ago
        @course.start_at = start_at
        @course.conclude_at = end_at
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@course)
        @enrollment.reload.state.should eql(:completed)
        
        @course.restrict_enrollments_to_course_dates = false
        @course.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@course)
        @enrollment.reload.state.should eql(:active)
      end
      
      it "should work on the enrollment_dates_override model" do
        course_with_student(:active_all => true)
        start_at = 4.days.ago
        end_at = 2.days.ago
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.save!
        @override = @term.enrollment_dates_overrides.create!(:enrollment_type => 'StudentEnrollment', :enrollment_term => @term, :start_at => start_at, :end_at => end_at)
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@override)
        @enrollment.reload.state.should eql(:completed)
        
        @term.ignore_term_date_restrictions = true
        @term.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@override)
        @enrollment.reload.state.should eql(:active)
      end
      
      it "should work on the enrollment_term model" do
        course_with_student(:active_all => true)
        start_at = 4.days.ago
        end_at = 2.days.ago
        @term = @course.enrollment_term
        @term.should_not be_nil
        @term.start_at = start_at
        @term.end_at = end_at
        @term.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@term)
        @enrollment.reload.state.should eql(:completed)
        
        @term.ignore_term_date_restrictions = true
        @term.save!
        @enrollment.workflow_state = 'active'
        @enrollment.save!
        @enrollment.state.should eql(:active)
        EnrollmentDateRestrictions.update_restricted_enrollments(@term)
        @enrollment.reload.state.should eql(:active)
      end
    end
    
    describe "scheduling future updates" do
      it "should schedule a delayed job at the right time to update enrollments" do
        course_with_student(:active_all => true)
        start_at = 2.days.from_now
        end_at = 4.days.from_now
        @course.start_at = start_at
        @course.conclude_at = end_at
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
        jobs = Delayed::Job.all(:limit => 2, :order => 'id desc').reverse
        jobs[0].run_at.should be_close start_at, 1
        jobs[1].run_at.should be_close end_at, 1
      end
    end
  end
end
