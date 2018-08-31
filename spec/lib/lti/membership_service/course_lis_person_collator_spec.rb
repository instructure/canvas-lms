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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require_dependency "lti/membership_service/course_lis_person_collator"

module Lti::MembershipService
  describe CourseLisPersonCollator do
    context 'course with teacher' do
      before(:each) do
        course_with_teacher
      end

      describe '#initialize' do
        it 'sets sane defaults when no options are set' do
          collator = CourseLisPersonCollator.new(@course, @teacher)

          expect(collator.role).to be_nil
          expect(collator.per_page).to eq(Api.per_page)
          expect(collator.page).to eq(1)
        end

        it 'handles negative values for :page option' do
          opts = {
            page: -1
          }
          collator = CourseLisPersonCollator.new(@course, @teacher, opts)

          expect(collator.page).to eq(1)
        end

        it 'handles negative values for :per_page option' do
          opts = {
            per_page: -1
          }
          collator = CourseLisPersonCollator.new(@course, @teacher, opts)

          expect(collator.per_page).to eq(Api.per_page)
        end

        it 'handles values for :per_page option that exceed per page max' do
          opts = {
            per_page: Api.max_per_page + 1
          }
          collator = CourseLisPersonCollator.new(@course, @teacher, opts)

          expect(collator.per_page).to eq(Api.max_per_page)
        end

        it 'generates a list of IMS::LTI::Models::Membership objects' do
          collator = CourseLisPersonCollator.new(@course, @teacher)
          memberships = collator.memberships
          @teacher.reload
          membership = memberships[0]

          expect(memberships.size).to eq(1)
          expect(membership.status).to eq(IMS::LIS::Statuses::SimpleNames::Active)
          expect(membership.role).to match_array([IMS::LIS::Roles::Context::URNs::Instructor])
          expect(membership.member.name).to eq(@teacher.name)
          expect(membership.member.given_name).to eq(@teacher.first_name)
          expect(membership.member.family_name).to eq(@teacher.last_name)
          expect(membership.member.img).to eq(@teacher.avatar_image_url)
          expect(membership.member.email).to eq(@teacher.email)
          expect(membership.member.result_sourced_id).to be_nil
          expect(membership.member.sourced_id).to be_nil
          expect(membership.member.user_id).to eq(@teacher.lti_context_id)
        end
      end

      describe '#context' do
        it 'returns a course for the context' do
          collator = CourseLisPersonCollator.new(@course, @teacher)

          expect(collator.context).to eq(@course)
        end
      end
    end
  end

  context 'course with user that has many enrollments' do
    before(:each) do
      course_with_teacher
      @course.enroll_user(@teacher, 'TaEnrollment', enrollment_state: 'active')
      @course.enroll_user(@teacher, 'DesignerEnrollment', enrollment_state: 'active')
      @course.enroll_user(@teacher, 'StudentEnrollment', enrollment_state: 'active')
      @course.enroll_user(@teacher, 'TeacherEnrollment', enrollment_state: 'active')
      @course.enroll_user(@teacher, 'ObserverEnrollment', enrollment_state: 'active')
    end

    describe '#membership' do
      it 'properly outputs multiple membership roles for membership' do
        collator = CourseLisPersonCollator.new(@course, @teacher)
        memberships = collator.memberships
        membership = memberships[0]

        expect(memberships.size).to eq(1)
        expect(membership.role).to match_array([
          IMS::LIS::Roles::Context::URNs::Instructor,
          IMS::LIS::Roles::Context::URNs::TeachingAssistant,
          IMS::LIS::Roles::Context::URNs::ContentDeveloper,
          IMS::LIS::Roles::Context::URNs::Learner,
          IMS::LIS::Roles::Context::URNs::Learner_NonCreditLearner
        ])
      end

      it 'excludes membership roles for non-active enrollments' do
        enrollment = @teacher.enrollments.where(type: 'TeacherEnrollment').first
        enrollment.deactivate
        collator = CourseLisPersonCollator.new(@course, @teacher)
        memberships = collator.memberships
        membership = memberships[0]

        expect(memberships.size).to eq(1)
        expect(membership.role).to match_array([
          IMS::LIS::Roles::Context::URNs::TeachingAssistant,
          IMS::LIS::Roles::Context::URNs::ContentDeveloper,
          IMS::LIS::Roles::Context::URNs::Learner,
          IMS::LIS::Roles::Context::URNs::Learner_NonCreditLearner
        ])
      end
    end
  end

  context 'course with multiple users' do
    before(:each) do
      course_with_teacher
      @course.enroll_user(@teacher, 'TeacherEnrollment', enrollment_state: 'active')
      @ta = user_model
      @course.enroll_user(@ta, 'TaEnrollment', enrollment_state: 'active')
      @designer = user_model
      @course.enroll_user(@designer, 'DesignerEnrollment', enrollment_state: 'active')
      @student = user_model
      @course.enroll_user(@student, 'StudentEnrollment', enrollment_state: 'active')
      @observer = user_model
      @course.enroll_user(@observer, 'ObserverEnrollment', enrollment_state: 'active')
    end

    describe '#membership' do
      it 'outputs the users in a course with their respective roles' do
        collator = CourseLisPersonCollator.new(@course, @teacher)
        memberships = collator.memberships

        expect(memberships.size).to eq(5)

        @teacher.reload
        @ta.reload
        @designer.reload
        @student.reload
        @observer.reload

        teacher = memberships.find { |m| m.member.user_id == @teacher.lti_context_id }
        ta = memberships.find { |m| m.member.user_id == @ta.lti_context_id }
        designer = memberships.find { |m| m.member.user_id == @designer.lti_context_id }
        student = memberships.find { |m| m.member.user_id == @student.lti_context_id }
        observer = memberships.find { |m| m.member.user_id == @observer.lti_context_id }

        expect(teacher.role).to match_array([IMS::LIS::Roles::Context::URNs::Instructor])
        expect(ta.role).to match_array([IMS::LIS::Roles::Context::URNs::TeachingAssistant])
        expect(designer.role).to match_array([IMS::LIS::Roles::Context::URNs::ContentDeveloper])
        expect(student.role).to match_array([IMS::LIS::Roles::Context::URNs::Learner])
        expect(observer.role).to match_array([IMS::LIS::Roles::Context::URNs::Learner_NonCreditLearner])
      end
    end
  end

  context 'pagination' do
    before(:each) do
      course_with_teacher
      @course.enroll_user(@teacher, 'TeacherEnrollment', enrollment_state: 'active')
      @ta = user_model
      @course.enroll_user(@ta, 'TaEnrollment', enrollment_state: 'active')
      @designer = user_model
      @course.enroll_user(@designer, 'DesignerEnrollment', enrollment_state: 'active')
      @student = user_model
      @course.enroll_user(@student, 'StudentEnrollment', enrollment_state: 'active')
      @observer = user_model
      @course.enroll_user(@observer, 'ObserverEnrollment', enrollment_state: 'active')
      allow(Api).to receive(:per_page).and_return(1)
    end

    context 'OAuth 1' do
      subject do
        collator_one.memberships.map(&:member).map(&:user_id) +
        collator_two.memberships.map(&:member).map(&:user_id) +
        collator_three.memberships.map(&:member).map(&:user_id)
      end

      let(:collator_one) { CourseLisPersonCollator.new(@course, @teacher, per_page: 2, page: 1) }
      let(:collator_two) { CourseLisPersonCollator.new(@course, @teacher, per_page: 2, page: 2) }
      let(:collator_three) { CourseLisPersonCollator.new(@course, @teacher, per_page: 2, page: 3) }

      it 'does not render duplicate items when paginating' do
        expect(subject.length).to eq subject.uniq.length
      end

      it 'paginates the entire collection' do
        expect(subject.length).to eq @course.current_users.length
      end
    end

    describe '#memberships' do
      it 'returns the number of memberships specified by the per_page params' do
        collator = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 1)

        expect(collator.memberships.size).to eq(1)

        collator = CourseLisPersonCollator.new(@course, @teacher, per_page: 3, page: 1)

        expect(collator.memberships.size).to eq(3)
      end

      it 'returns the right page of memberships based on the page param' do
        collator1 = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 1)
        collator2 = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 2)
        collator3 = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 3)
        collator4 = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 4)
        collator5 = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 5)
        user_ids = [
          collator1.memberships.first.member.user_id,
          collator2.memberships.first.member.user_id,
          collator3.memberships.first.member.user_id,
          collator4.memberships.first.member.user_id,
          collator5.memberships.first.member.user_id
        ]

        expect(user_ids.uniq.size).to eq(5)
      end
    end

    describe '#next_page?' do
      it 'returns true when there is an additional page of results' do
        collator = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 1)
        expect(collator.next_page?).to eq(true)
      end

      it 'returns false when there are no more pages' do
        collator = CourseLisPersonCollator.new(@course, @teacher, per_page: 1, page: 5)
        collator.memberships
        expect(collator.next_page?).to eq(false)
      end
    end
  end
end
