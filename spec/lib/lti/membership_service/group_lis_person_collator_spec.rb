#
# Copyright (C) 2016 Instructure, Inc.
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

module Lti::MembershipService
  describe GroupLisPersonCollator do
    context 'group with many students' do
      before(:each) do
        course_with_teacher
        @course.offer!
        @student1 = user_model
        @course.enroll_user(@student1, 'StudentEnrollment', enrollment_state: 'active')
        @student2 = user_model
        @course.enroll_user(@student2, 'StudentEnrollment', enrollment_state: 'active')
        @student3 = user_model
        @course.enroll_user(@student3, 'StudentEnrollment', enrollment_state: 'active')

        @group_category = @course.group_categories.create!(name: 'Membership')
        @group = @course.groups.create!(name: 'Group 1', group_category: @group_category)
        @group.add_user(@student1)
        @group.add_user(@student2)
        @group.add_user(@student3)

        @group.leader = @student1
        @group.save!
      end

      describe '#context' do
        it 'returns the correct context' do
          collator = GroupLisPersonCollator.new(@group, @student1)

          expect(collator.context).to eq(@group)
        end
      end

      describe '#membership' do
        it 'outputs the membership in a group' do
          collator = GroupLisPersonCollator.new(@group, @student1)

          memberships = collator.memberships
          @student1.reload
          @student2.reload
          @student3.reload
          expect(memberships.size).to eq(3)

          [@student1, @student2, @student3].each do |student|
            membership = memberships.find { |m| m.member.user_id == student.lti_context_id }

            expect(membership.status).to eq(IMS::LIS::Statuses::SimpleNames::Active)
            if student == @group.leader
              expect(membership.role).to match_array([IMS::LIS::Roles::Context::URNs::Member,
                                                      IMS::LIS::Roles::Context::URNs::Manager])
            else
              expect(membership.role).to match_array([IMS::LIS::Roles::Context::URNs::Member])
            end
            expect(membership.member.name).to eq(student.name)
            expect(membership.member.given_name).to eq(student.first_name)
            expect(membership.member.family_name).to eq(student.last_name)
            expect(membership.member.img).to eq(student.avatar_image_url)
            expect(membership.member.email).to eq(student.email)
            expect(membership.member.result_sourced_id).to be_nil
            expect(membership.member.sourced_id).to be_nil
          end
        end
      end

      context 'pagination' do
        describe '#memberships' do
          it 'returns the number of memberships specified by the per_page params' do
            Api.stubs(:per_page).returns(1)
            collator = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 1)

            expect(collator.memberships.size).to eq(1)

            collator = GroupLisPersonCollator.new(@group, @student1, per_page: 3, page: 1)

            expect(collator.memberships.size).to eq(3)
          end

          it 'returns the right page of memberships based on the page param' do
            Api.stubs(:per_page).returns(1)
            collator1 = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 1)
            collator2 = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 2)
            collator3 = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 3)
            user_ids = [
              collator1.memberships.first.member.user_id,
              collator2.memberships.first.member.user_id,
              collator3.memberships.first.member.user_id,
            ]

            expect(user_ids.uniq.size).to eq(3)
          end
        end

        describe '#next_page?' do
          it 'returns true when there is an additional page of results' do
            Api.stubs(:per_page).returns(1)
            collator = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 1)

            expect(collator.next_page?).to eq(true)
          end

          it 'returns false when there are no more pages' do
            Api.stubs(:per_page).returns(1)
            collator = GroupLisPersonCollator.new(@group, @student1, per_page: 1, page: 5)

            expect(collator.next_page?).to eq(false)
          end
        end
      end
    end
  end
end
