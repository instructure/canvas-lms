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
    allow(user).to receive(:workflow_state).and_return('active')
    allow(course).to receive(:enrollment_term).and_return(term)
    allow(quiz).to receive(:grants_right?).and_return(true)
    allow(quiz).to receive(:grants_right?).
      with(anything, anything, :manage).and_return(false)
  end

  describe '#eligible?' do

    it 'always returns true if the user is a teacher' do
      allow(quiz).to receive(:grants_right?).and_return(false)
      allow(quiz).to receive(:grants_right?).
        with(anything, anything, :manage).and_return(true)
      expect(eligibility.eligible?).to be_truthy
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it 'returns false if no course is provided' do
      allow(eligibility).to receive(:course).and_return(nil)
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it 'returns false if the student is inactive' do
      allow(user).to receive(:workflow_state).and_return('deleted')
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it 'returns false if a user cannot read as an admin' do
      allow(user).to receive(:new_record?).and_return(false)
      allow(course).to receive(:grants_right?).and_return(false)
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_falsey
    end

    it 'returns false if a quiz is access code restricted (but is still potentially_eligible)' do
      quiz.access_code = 'x'
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it 'returns false if a quiz is ip restricted (but is still potentially_eligible)' do
      quiz.ip_filter = '1.1.1.1'
      expect(eligibility.eligible?).to be_falsey
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    it 'otherwise returns true' do
      expect(eligibility.eligible?).to be_truthy
      expect(eligibility.potentially_eligible?).to be_truthy
    end

    # Override priority is as follows:
    # term < course < section inasmuch as "Users can only participate within ___ dates" is enabled.
    # Otherwise, term > course > section.
    # Also, when a course or section don't have an end date, they lose their override priority.
    describe 'term, course, section hierarchy' do

      shared_examples 'an eligible quiz' do
        it 'returns true' do
          expect(eligibility.eligible?).to be_truthy
          expect(eligibility.potentially_eligible?).to be_truthy
        end
      end

      shared_examples 'an ineligible quiz' do
        it 'returns false' do
          expect(eligibility.eligible?).to be_falsey
          expect(eligibility.potentially_eligible?).to be_falsey
        end
      end

      def create_enrollment_term(start_at, end_at)
        EnrollmentTerm.new(start_at: start_at, end_at: end_at)
      end

      def create_course(start_at, end_at, restricted=nil)
        Course.new(start_at: start_at, conclude_at: end_at, restrict_enrollments_to_course_dates: restricted)
      end

      def create_restricted_course(start_at, end_at)
        create_course(start_at, end_at, true)
      end

      def create_course_section(start_at, end_at, restricted=nil)
        CourseSection.new(start_at: start_at, end_at: end_at, restrict_enrollments_to_section_dates: restricted)
      end

      def create_restricted_course_section(start_at, end_at)
        create_course_section(start_at, end_at, true)
      end

      let!(:now) { Time.zone.now }

      around do |example|
        Timecop.freeze(now, &example)
      end

      let(:three_days_ago)      { now - 3.days }
      let(:six_days_ago)        { now - 6.days }
      let(:three_days_from_now) { now + 3.days }
      let(:six_days_from_now)   { now + 6.days }

      # Terms

      let(:nodate_term)             { create_enrollment_term(nil, nil) }
      let(:active_term)             { create_enrollment_term(three_days_ago, three_days_from_now) }
      let(:future_term)             { create_enrollment_term(three_days_from_now, six_days_from_now) }
      let(:concluded_term)          { create_enrollment_term(six_days_ago, three_days_ago) }

      # Courses
      # restricted == ("Users can only participate within course dates" is enabled)

      let(:nodate_course)            { create_course(nil, nil) }
      let(:restricted_nodate_course) { create_restricted_course(nil, nil) }

      let(:active_course)            { create_course(three_days_ago, three_days_from_now) }
      let(:restricted_active_course) { create_restricted_course(three_days_ago, three_days_from_now) }

      let(:course_without_end)            { create_course(three_days_ago, nil) }
      let(:restricted_course_without_end) { create_restricted_course(three_days_ago, nil) }

      let(:future_course)            { create_course(three_days_from_now, six_days_from_now) }
      let(:restricted_future_course) { create_restricted_course(three_days_from_now, six_days_from_now) }

      let(:concluded_course)            { create_course(six_days_ago, three_days_ago) }
      let(:restricted_concluded_course) { create_restricted_course(six_days_ago, three_days_ago) }

      # Sections
      # restricted == ("Users can only participate within section dates" is enabled)

      let(:nodate_section)            { create_course_section(nil, nil) }
      let(:restricted_nodate_section) { create_restricted_course_section(nil, nil) }

      let(:active_section)            { create_course_section(three_days_ago, three_days_from_now) }
      let(:restricted_active_section) { create_restricted_course_section(three_days_ago, three_days_from_now) }

      let(:section_without_end)            { create_course_section(three_days_ago, nil) }
      let(:restricted_section_without_end) { create_restricted_course_section(three_days_ago, nil) }

      let(:future_section)            { create_course_section(three_days_from_now, six_days_from_now) }
      let(:restricted_future_section) { create_restricted_course_section(three_days_from_now, six_days_from_now) }

      let(:concluded_section)            { create_course_section(six_days_ago, three_days_ago) }
      let(:restricted_concluded_section) { create_restricted_course_section(six_days_ago, three_days_ago) }

      let!(:scenario_setup) do
        allow(eligibility).to receive(:term).and_return(term)
        allow(eligibility).to receive(:course).and_return(course)
        allow(course).to receive(:enrollment_term).and_return(term)
        allow(eligibility).to receive(:student_sections).and_return([section])
      end

      context 'when the term, course, and section have no dates' do
        let(:term) { nodate_term }

        context 'when restricted to course dates' do
          let(:course) { restricted_nodate_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_nodate_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { nodate_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when not restricted to course dates' do
          let(:course) { nodate_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_nodate_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { nodate_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end
      end

      context 'when the term is active' do
        let(:term) { active_term }

        context 'when restricted to course dates' do
          let(:course) { restricted_active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when not restricted to course dates' do
          let(:course) { active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when restricted to future course dates' do
          let(:course) { restricted_future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when not restricted to future course dates' do
          let(:course) { future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when the course is concluded' do
          let(:course) { concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when the restricted course is concluded' do
          let(:course) { restricted_concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the course has no end date' do
          let(:course) { course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when the restricted course has no end date' do
          let(:course) { restricted_course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end
      end

      context 'when the term is in the future' do
        let(:term) { future_term }

        context 'when restricted to course dates' do
          let(:course) { restricted_active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when not restricted to course dates' do
          let(:course) { active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when restricted to future course dates' do
          let(:course) { restricted_future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when not restricted to future course dates' do
          let(:course) { future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the course is concluded' do
          let(:course) { concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the restricted course is concluded' do
          let(:course) { restricted_concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the course has no end date' do
          let(:course) { course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the restricted course has no end date' do
          let(:course) { restricted_course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end
      end

      context 'when the term is concluded' do
        let(:term) { concluded_term }

        context 'when restricted to course dates' do
          let(:course) { restricted_active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an eligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an eligible quiz'
          end
        end

        context 'when not restricted to course dates' do
          let(:course) { active_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when restricted to future course dates' do
          let(:course) { restricted_future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when not restricted to future course dates' do
          let(:course) { future_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the course is concluded' do
          let(:course) { concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the restricted course is concluded' do
          let(:course) { restricted_concluded_course }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the course has no end date' do
          let(:course) { course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the restricted course has no end date' do
          let(:course) { restricted_course_without_end }

          context 'when restricted to section dates' do
            let(:section) { restricted_active_section }
            it_behaves_like 'an eligible quiz'
          end

          context 'when not restricted to section dates' do
            let(:section) { active_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted to future section dates' do
            let(:section) { restricted_future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when not restricted to future section dates' do
            let(:section) { future_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when section is concluded' do
            let(:section) { concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when restricted section is concluded' do
            let(:section) { restricted_concluded_section }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the section has no end date' do
            let(:section) { section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when the restricted section has no end date' do
            let(:section) { restricted_section_without_end }
            it_behaves_like 'an ineligible quiz'
          end

          context 'when no sections exist' do
            let!(:scenario_setup) do
              allow(eligibility).to receive(:term).and_return(term)
              allow(eligibility).to receive(:course).and_return(course)
              allow(course).to receive(:enrollment_term).and_return(term)
              allow(eligibility).to receive(:student_sections).and_return([])
            end
            it_behaves_like 'an ineligible quiz'
          end
        end

        context 'when the restricted course doesn\'t have an end_at' do
          let(:course) { restricted_nodate_course }
          let(:section) { concluded_section }
          it_behaves_like 'an ineligible quiz'
        end

        context 'when the course is concluded and the section overrides without an end date' do
          let(:course) { concluded_course }
          let(:section) { restricted_section_without_end }
          it_behaves_like 'an ineligible quiz'
        end
      end

      describe 'when an active course has many section enrollments' do
        let(:course) { active_course }
        let!(:scenario_setup) do
          allow(eligibility).to receive(:term).and_return(term)
          allow(eligibility).to receive(:course).and_return(course)
          allow(eligibility).to receive(:student_sections).and_return(student_sections)
        end

        context 'when an active section overrides' do
          let(:student_sections) do
            [
              restricted_active_section,
              restricted_concluded_section,
              restricted_future_section,
              restricted_section_without_end
            ]
          end
          it_behaves_like 'an eligible quiz'
        end

        context 'when an active section override doesn\'t exist' do
          let(:student_sections) do
            [
              restricted_future_section,
              active_section,
              restricted_concluded_section,
              restricted_section_without_end
            ]
          end
          it_behaves_like 'an ineligible quiz'
        end
      end

      describe 'with associated Assignment Overrides' do

        context 'when an active section override exists' do
          let(:assignment_override_sections) do
            [
              restricted_active_section,
              restricted_concluded_section,
              restricted_future_section
            ]
          end
          let!(:scenario_setup) do
            allow(eligibility).to receive(:assignment_override_sections).and_return(assignment_override_sections)
            allow(eligibility).to receive(:student_sections).and_return([])
          end
          it_behaves_like 'an eligible quiz'
        end

        context 'when an active section override doesn\'t exist' do
          let(:assignment_override_sections) do
            [
              restricted_concluded_section,
              restricted_future_section
            ]
          end
          let!(:scenario_setup) do
            allow(eligibility).to receive(:assignment_override_sections).and_return(assignment_override_sections)
            allow(eligibility).to receive(:term).and_return(concluded_term)
            allow(eligibility).to receive(:course).and_return(restricted_concluded_course)
            allow(eligibility).to receive(:student_sections).and_return([restricted_concluded_section])
          end
          it_behaves_like 'an ineligible quiz'
        end

        context 'when the term, course, and sections are concluded and an active section override exists' do
          let(:assignment_override_sections) do
            [
              restricted_active_section,
              restricted_concluded_section,
              restricted_future_section
            ]
          end
          let!(:scenario_setup) do
            allow(eligibility).to receive(:assignment_override_sections).and_return(assignment_override_sections)
            allow(eligibility).to receive(:term).and_return(concluded_term)
            allow(eligibility).to receive(:course).and_return(restricted_concluded_course)
            allow(eligibility).to receive(:student_sections).and_return([restricted_concluded_section])
          end
          it_behaves_like 'an eligible quiz'
        end

        context 'when the course section is active and no overrides are active' do
          let(:assignment_override_sections) do
            [
              restricted_concluded_section,
              restricted_future_section
            ]
          end
          let!(:scenario_setup) do
            allow(eligibility).to receive(:assignment_override_sections).and_return(assignment_override_sections)
            allow(eligibility).to receive(:student_sections).and_return([restricted_active_section])
          end
          it_behaves_like 'an eligible quiz'
        end
      end
    end
  end

  describe '#declined_reason_renders' do

    it 'returns nil when no additional information should be rendered' do
      expect(eligibility.declined_reason_renders).to be_nil
    end

    it 'returns :access_code when an access code is needed' do
      quiz.access_code = 'x'
      expect(eligibility.declined_reason_renders).to eq(:access_code)
    end

    it 'returns :invalid_ip an invalid IP is used to attempt to take a quiz' do
      quiz.ip_filter = '1.1.1.1'
      expect(eligibility.declined_reason_renders).to eq(:invalid_ip)
    end
  end

  describe '#locked?' do

    it 'returns false the quiz is not locked' do
      expect(eligibility.locked?).to be_falsey
    end

    it 'returns false if quiz explicitly grant access to the user' do
      allow(quiz).to receive(:locked_for?)   { true }
      allow(quiz).to receive(:grants_right?) { true }
      expect(eligibility.locked?).to be_falsey
    end

    it 'returns true if the quiz is locked and access is not granted' do
      allow(quiz).to receive(:locked_for?)   { true }
      allow(quiz).to receive(:grants_right?) { false }
      expect(eligibility.locked?).to be_truthy
    end
  end
end
