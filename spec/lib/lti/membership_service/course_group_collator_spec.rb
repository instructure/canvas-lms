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
require_dependency "lti/membership_service/course_group_collator"

module Lti::MembershipService
  describe CourseGroupCollator do
    context 'course with lots of groups' do
      before(:once) do
        course_with_teacher
        @group_category = @course.group_categories.create!(name: 'Membership')

        (0..100).each do |n|
          @course.groups.create!(name: "Group #{n}", group_category: @group_category)
        end
      end

      describe '#initialize' do
        it 'sets sane defaults when no options are set' do
          collator = CourseGroupCollator.new(@course)

          # expect(collator.role).to eq(IMS::LIS::ContextType::URNs::Group)
          expect(collator.per_page).to eq(Api.per_page)
          expect(collator.page).to eq(0)
        end

        it 'handles negative values for :page option' do
          opts = {
            page: -1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.page).to eq(0)
        end

        it 'handles negative values for :per_page option' do
          opts = {
            per_page: -1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.per_page).to eq(Api.per_page)
        end

        it 'handles values for :per_page option that exceed per page max' do
          opts = {
            per_page: Api.max_per_page + 1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.per_page).to eq(Api.max_per_page)
        end

        it 'generates a list of IMS::LTI::Models::Membership objects' do
          collator = CourseGroupCollator.new(@course)
          @teacher.reload
          memberships = collator.memberships
          membership = memberships[0]

          expect(memberships.size).to eq(10)

          expect(membership.status).to eq(IMS::LIS::Statuses::SimpleNames::Active)
          expect(membership.role).to match_array([IMS::LIS::ContextType::URNs::Group])
          expect(membership.member.name).to eq("Group 0")
        end
      end

      describe '#context' do
        it 'returns a course for the context' do
          collator = CourseGroupCollator.new(@course)

          expect(collator.context).to eq(@course)
        end
      end

      context 'pagination' do
        describe '#memberships' do
          it 'returns the number of memberships specified by the per_page params' do
            Api.stubs(:per_page).returns(1)

            collator = CourseGroupCollator.new(@course,  per_page: 1, page: 1)
            expect(collator.memberships.size).to eq(1)

            collator = CourseGroupCollator.new(@course, per_page: 3, page: 1)
            expect(collator.memberships.size).to eq(3)
          end
        end

        describe '#next_page?' do
          it 'returns true when there is an additional page of results' do
            collator = CourseGroupCollator.new(@course, page: 1)
            expect(collator.next_page?).to eq(true)
          end

          it 'returns false when there are no more pages' do
            collator = CourseGroupCollator.new(@course, page: 11)
            expect(collator.next_page?).to eq(false)
          end
        end
      end
    end
  end
end
