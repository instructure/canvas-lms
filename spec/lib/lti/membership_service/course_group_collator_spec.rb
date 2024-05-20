# frozen_string_literal: true

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

module Lti::MembershipService
  describe CourseGroupCollator do
    context "course with lots of groups" do
      before(:once) do
        course_with_teacher
        @group_category = @course.group_categories.create!(name: "Membership")

        101.times do |n|
          @course.groups.create!(name: "Group #{n}", group_category: @group_category)
        end
      end

      describe "#initialize" do
        it "sets sane defaults when no options are set" do
          collator = CourseGroupCollator.new(@course)

          # expect(collator.role).to eq(::IMS::LIS::ContextType::URNs::Group)
          expect(collator.per_page).to eq(Api::PER_PAGE)
          expect(collator.page).to eq(1)
        end

        it "handles negative values for :page option" do
          opts = {
            page: -1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.page).to eq(1)
        end

        it "handles negative values for :per_page option" do
          opts = {
            per_page: -1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.per_page).to eq(Api::PER_PAGE)
        end

        it "handles values for :per_page option that exceed per page max" do
          opts = {
            per_page: Api::MAX_PER_PAGE + 1
          }
          collator = CourseGroupCollator.new(@course, opts)

          expect(collator.per_page).to eq(Api::MAX_PER_PAGE)
        end

        it "generates a list of ::IMS::LTI::Models::Membership objects" do
          collator = CourseGroupCollator.new(@course)
          @teacher.reload
          memberships = collator.memberships
          membership = memberships[0]

          expect(memberships.size).to eq(10)

          expect(membership.status).to eq(::IMS::LIS::Statuses::SimpleNames::Active)
          expect(membership.role).to match_array([::IMS::LIS::ContextType::URNs::Group])
          expect(membership.member.name).to eq("Group 0")
        end
      end

      describe "#context" do
        it "returns a course for the context" do
          collator = CourseGroupCollator.new(@course)

          expect(collator.context).to eq(@course)
        end
      end

      context "pagination" do
        describe "#memberships" do
          it "returns the number of memberships specified by the per_page params" do
            allow(Api).to receive(:per_page).and_return(1)

            collator = CourseGroupCollator.new(@course, per_page: 1, page: 1)
            expect(collator.memberships.size).to eq(1)

            collator = CourseGroupCollator.new(@course, per_page: 3, page: 1)
            expect(collator.memberships.size).to eq(3)
          end
        end

        describe "#next_page?" do
          it "returns true when there is an additional page of results" do
            collator = CourseGroupCollator.new(@course, page: 1)
            expect(collator.next_page?).to be(true)
          end

          it "returns false when there are no more pages" do
            collator = CourseGroupCollator.new(@course, page: 11)
            collator.memberships
            expect(collator.next_page?).to be(false)
          end
        end
      end
    end
  end
end
