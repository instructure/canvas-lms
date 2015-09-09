#
# Copyright (C) 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizEligibility do

  let(:quiz)   { Quizzes::Quiz.new }
  let(:course) { Course.new }
  let(:user)   { User.new }
  let(:term)   { EnrollmentTerm.new }
  let(:eligibility) { Quizzes::QuizEligibility.new(course: course, user: user, quiz: quiz) }


  before do
    user.stubs(:workflow_state).returns('active')
    course.stubs(:enrollment_term).returns(term)
    quiz.stubs(:grants_right?).returns(true)
    quiz.stubs(:grants_right?)
    .with(anything, anything, :manage).returns(false)
  end

  describe "#eligible?" do

    it "always returns true if the user is a teacher" do
      quiz.stubs(:grants_right?).returns(false)
      quiz.stubs(:grants_right?)
      .with(anything, anything, :manage).returns(true)
      expect(eligibility.eligible?).to be_truthy
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it "returns false if no course is provided" do
      eligibility.stubs(:course).returns(nil)
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it "returns false if the student is inactive" do
      user.stubs(:workflow_state).returns("deleted")
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it "returns false if a user cannot read as an admin" do
      user.stubs(:new_record?).returns(false)
      course.stubs(:grants_right?).returns(false)
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it "returns false if a quiz is access code restricted (but is still potentially_eligible)" do
      quiz.access_code = 'x'
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it "returns false if a quiz is ip restricted (but is still potentially_eligible)" do
      quiz.ip_filter = '1.1.1.1'
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it "otherwise returns true" do
      expect(eligibility.eligible?).to be_truthy
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    describe "date-based overrides" do

      let(:active_course)     { Course.new(conclude_at: Time.zone.now + 3.days) }
      let(:concluded_course)  { Course.new(conclude_at: Time.zone.now - 3.days) }

      let(:restricted_active_course)    { Course.new(conclude_at: Time.zone.now + 3.days, restrict_enrollments_to_course_dates: true)}
      let(:restricted_concluded_course) { Course.new(conclude_at: Time.zone.now - 3.days, restrict_enrollments_to_course_dates: true)}
      let(:restricted_nodate_course) { Course.new(restrict_enrollments_to_course_dates: true)}

      let(:active_section)    { CourseSection.new(end_at: Time.zone.now + 3.days) }
      let(:concluded_section) { CourseSection.new(end_at: Time.zone.now - 3.days) }

      let(:restricted_active_section)    { CourseSection.new(end_at: Time.zone.now + 3.days, restrict_enrollments_to_section_dates: true) }
      let(:restricted_concluded_section) { CourseSection.new(end_at: Time.zone.now - 3.days, restrict_enrollments_to_section_dates: true) }

      let(:active_term)       { EnrollmentTerm.new(end_at: Time.zone.now + 3.days) }
      let(:concluded_term)    { EnrollmentTerm.new(end_at: Time.zone.now - 3.days) }

      context "term concluded" do
        it "returns false if no overrides" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns false if restricted course doesn't have an end_at" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(restricted_nodate_course)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns false if active course because term > course" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(active_course)
          restricted_active_course.stubs(:enrollment_term).returns(concluded_term)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns true if active course overrides" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(restricted_active_course)
          restricted_active_course.stubs(:enrollment_term).returns(concluded_term)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end

        it "returns false and ignores section" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(active_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns false and ignores section" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(active_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns true if active section overrides" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          concluded_course.stubs(:enrollment_term).returns(concluded_term)
          eligibility.stubs(:course_section).returns(restricted_active_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end
      end

      context "course concluded and restricted to course dates" do
        it "returns false if no overrides" do
          eligibility.stubs(:term).returns(active_term)
          eligibility.stubs(:course).returns(restricted_concluded_course)
          restricted_concluded_course.stubs(:enrollment_term).returns(active_term)
          eligibility.stubs(:course_section).returns(active_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns true if active section overrides" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(restricted_concluded_course)
          eligibility.stubs(:course_section).returns(restricted_active_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end
      end

      context "course concluded" do
        it "returns true if no overrides because term > course" do
          eligibility.stubs(:term).returns(active_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end

        it "returns false if term is closed with no respect for section" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(active_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey

          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end

        it "returns true if active section overrides" do
          eligibility.stubs(:term).returns(concluded_term)
          eligibility.stubs(:course).returns(concluded_course)
          eligibility.stubs(:course_section).returns(restricted_active_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end
      end

      context "section concluded" do
        it "returns true with no overrides" do
          eligibility.stubs(:term).returns(active_term)
          eligibility.stubs(:course).returns(active_course)
          eligibility.stubs(:course_section).returns(concluded_section)
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end

        it "returns false if section overrides" do
          eligibility.stubs(:term).returns(active_term)
          eligibility.stubs(:course).returns(active_course)
          eligibility.stubs(:course_section).returns(restricted_concluded_section)
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end
      end

      it "returns false if section overrides and course overrides" do
        eligibility.stubs(:term).returns(active_term)
        eligibility.stubs(:course).returns(restricted_active_course)
        eligibility.stubs(:course_section).returns(restricted_concluded_section)
        expect(eligibility.eligible?).to be_falsey
        expect(eligibility.potentially_eligible?).to be_falsey
      end
    end
  end


  describe "#declined_reason_renders" do

    it "returns nil when no additional information should be rendered" do
      expect(eligibility.declined_reason_renders).to be_nil
    end

    it "returns :access_code when an access code is needed" do
      quiz.access_code = 'x'
      expect(eligibility.declined_reason_renders).to eq(:access_code)
    end

    it "returns :invalid_ip an invalid IP is used to attempt to take a quiz" do
      quiz.ip_filter = '1.1.1.1'
      expect(eligibility.declined_reason_renders).to eq(:invalid_ip)
    end

  end

  describe "#locked?" do

    it "returns false the quiz is not locked" do
      expect(eligibility.locked?).to be_falsey
    end

    it "returns false if quiz explicitly grant access to the user" do
      quiz.stubs(:locked_for?)   { true }
      quiz.stubs(:grants_right?) { true }
      expect(eligibility.locked?).to be_falsey
    end

    it "returns true if the quiz is locked and access is not granted" do
      quiz.stubs(:locked_for?)   { true }
      quiz.stubs(:grants_right?) { false }
      expect(eligibility.locked?).to be_falsey
    end

  end

end
