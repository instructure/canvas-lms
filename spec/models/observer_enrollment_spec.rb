# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe ObserverEnrollment do
  before do
    @course1 = course_factory(active_all: true)
    @student = user_factory
    @observer = user_factory
    @student_enrollment = @course1.enroll_student(@student)
    @observer_enrollment = @course1.enroll_user(@observer, "ObserverEnrollment")
    @observer_enrollment.update_attribute(:associated_user_id, @student.id)

    @course2 = course_factory(active_all: true)
    @student_enrollment2 = @course2.enroll_student(@student)
    @observer_enrollment2 = @course2.enroll_user(@observer, "ObserverEnrollment")
    @observer_enrollment2.update_attribute(:associated_user_id, @student.id)
  end

  describe "observed_enrollments_for_courses" do
    it "retrieve observed enrollments for courses passed in" do
      expect(ObserverEnrollment.observed_enrollments_for_courses([@course1, @course2], @observer).sort)
        .to eq([@student_enrollment, @student_enrollment2].sort)
    end
  end

  describe "observed_students" do
    it "does not fail if the observed has been deleted" do
      expect(ObserverEnrollment.observed_students(@course1, @observer)).to eq({ @student => [@student_enrollment] })
      @student_enrollment.destroy
      expect(ObserverEnrollment.observed_students(@course1, @observer)).to eq({})
    end

    it "manually concluded students are returned when grade summary is set to true" do
      @student_enrollment.update_attribute(:workflow_state, "completed")
      expect(ObserverEnrollment.observed_students(@course1, @observer, grade_summary: true).length).to eq(1)
    end

    describe "date restricted future sections" do
      let(:unrestricted_observed_students) { ObserverEnrollment.observed_students(@course1, @observer2, include_restricted_access: false) }
      let(:all_observed_students) { ObserverEnrollment.observed_students(@course1, @observer2) }

      before do
        @course1.restrict_student_future_view = true
        @course1.save!
        @student2 = user_factory
        @observer2 = user_with_pseudonym(active_all: true)
        @section = @course1.course_sections.create!
        @section.start_at = 1.day.from_now
        @section.restrict_enrollments_to_section_dates = true
        @section.save!

        add_linked_observer(@student2, @observer2)
        @student_enrollment = @section.enroll_user(@student2, "StudentEnrollment")
      end

      it "does not include students in future sections with restricted access when called with current_only" do
        expect(unrestricted_observed_students).not_to have_key(@student2)
      end

      it "includes all students when called without current_only" do
        expect(all_observed_students).to include(@student2 => [@student_enrollment])
      end

      it "includes all students in future sections without restricted access when called with current_only" do
        @section.restrict_enrollments_to_section_dates = false
        @section.save!

        expect(unrestricted_observed_students).to include(@student2 => [@student_enrollment])
      end
    end
  end

  describe "observed_student_ids_by_observer_id" do
    it "returns a properly formatted hash" do
      @observer_two = user_factory
      @observer_enrollment_two = @course1.enroll_user(@observer_two, "ObserverEnrollment")
      expect(ObserverEnrollment
               .observed_student_ids_by_observer_id(@course1,
                                                    [@observer.id, @observer_two.id]))
        .to eq({ @observer.id => [@student.id], @observer_two.id => [] })
    end
  end

  context "notifications" do
    it "doesn't send enrollment notifications if already registered" do
      Notification.create!(name: "Enrollment Notification")
      user_with_pseudonym(active_all: true)
      e = @course1.enroll_user(@user, "ObserverEnrollment")
      expect(e.messages_sent).to be_empty
    end

    it "does send enrollment notifications if not already registered" do
      Notification.create!(name: "Enrollment Registration")
      user_with_pseudonym
      e = @course1.enroll_user(@user, "ObserverEnrollment")
      expect(e.messages_sent).to_not be_empty
    end
  end
end
