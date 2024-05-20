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
  describe PagePresenter do
    let(:base_url) { "https://localhost:3000" }
    let(:presenter) { PagePresenter.new(@course, @teacher, base_url) }
    let(:hash) { presenter.as_json }
    let(:group_presenter) { PagePresenter.new(@group, @student, base_url) }
    let(:group_hash) { group_presenter.as_json }

    context "course with single enrollment" do
      before do
        course_with_teacher
      end

      describe "#as_json" do
        it "outputs the expected data in the expected format at the top level" do
          expect(hash.keys.size).to eq(6)

          expect(hash.fetch(:@id)).to be_nil
          expect(hash.fetch(:@type)).to eq "Page"
          expect(hash.fetch(:@context)).to eq "http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer"
          expect(hash.fetch(:differences)).to be_nil
          expect(hash.fetch(:nextPage)).to be_nil
          expect(hash.fetch(:pageOf)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the container level" do
          container = hash[:pageOf]

          expect(container.size).to eq 5
          expect(container.fetch(:@id)).to be_nil
          expect(container.fetch(:@type)).to eq "LISMembershipContainer"
          expect(container.fetch(:@context)).to eq "http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer"
          expect(container.fetch(:membershipPredicate)).to eq "http://www.w3.org/ns/org#membership"
          expect(container.fetch(:membershipSubject)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the context level" do
          context = hash[:pageOf][:membershipSubject]

          expect(context.size).to eq 5
          expect(context.fetch(:@id)).to be_nil
          expect(context.fetch(:@type)).to eq "Context"
          expect(context.fetch(:name)).to eq @course.name
          expect(context.fetch(:contextId)).to eq @course.lti_context_id
          expect(context.fetch(:membership)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the membership level" do
          memberships = hash[:pageOf][:membershipSubject][:membership]
          @teacher.reload

          expect(memberships.size).to eq 1

          membership = memberships[0]

          expect(membership.size).to eq 4
          expect(membership.fetch(:@id)).to be_nil
          expect(membership.fetch(:status)).to eq ::IMS::LIS::Statuses::SimpleNames::Active
          expect(membership.fetch(:role)).to match_array([::IMS::LIS::Roles::Context::URNs::Instructor])

          member = membership.fetch(:member)
          expect(member.fetch(:@id)).to be_nil
          expect(member.fetch(:name)).to eq @teacher.name
          expect(member.fetch(:img)).to eq @teacher.avatar_image_url
          expect(member.fetch(:email)).to eq @teacher.email
          expect(member.fetch(:familyName)).to eq @teacher.last_name
          expect(member.fetch(:givenName)).to eq @teacher.first_name
          expect(member.fetch(:resultSourcedId)).to be_nil
          expect(member.fetch(:sourcedId)).to be_nil
          expect(member.fetch(:userId)).to eq(@teacher.lti_context_id)
        end
      end
    end

    context "group with single student" do
      before do
        course_with_teacher
        @course.offer!
        @student = user_model
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

        @group_category = @course.group_categories.create!(name: "Membership")
        @group = @course.groups.create!(name: "Group 1", group_category: @group_category)
        @group.add_user(@student)
      end

      describe "#as_json" do
        it "outputs the expected data in the expected format at the top level" do
          expect(group_hash.keys.size).to eq(6)

          expect(group_hash.fetch(:@id)).to be_nil
          expect(group_hash.fetch(:@type)).to eq "Page"
          expect(group_hash.fetch(:@context)).to eq "http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer"
          expect(group_hash.fetch(:differences)).to be_nil
          expect(group_hash.fetch(:nextPage)).to be_nil
          expect(group_hash.fetch(:pageOf)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the container level" do
          container = group_hash[:pageOf]

          expect(container.size).to eq 5
          expect(container.fetch(:@id)).to be_nil
          expect(container.fetch(:@type)).to eq "LISMembershipContainer"
          expect(container.fetch(:@context)).to eq "http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer"
          expect(container.fetch(:membershipPredicate)).to eq "http://www.w3.org/ns/org#membership"
          expect(container.fetch(:membershipSubject)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the context level" do
          context = group_hash[:pageOf][:membershipSubject]

          expect(context.size).to eq 5
          expect(context.fetch(:@id)).to be_nil
          expect(context.fetch(:@type)).to eq "Context"
          expect(context.fetch(:name)).to eq @group.name
          expect(context.fetch(:contextId)).to eq @group.lti_context_id
          expect(context.fetch(:membership)).not_to be_nil
        end

        it "outputs the expected data in the expected format at the membership level" do
          memberships = group_hash[:pageOf][:membershipSubject][:membership]
          @student.reload

          expect(memberships.size).to eq 1

          membership = memberships[0]

          expect(membership.size).to eq 4
          expect(membership.fetch(:@id)).to be_nil
          expect(membership.fetch(:status)).to eq ::IMS::LIS::Statuses::SimpleNames::Active
          expect(membership.fetch(:role)).to match_array([::IMS::LIS::Roles::Context::URNs::Member])

          member = membership.fetch(:member)
          expect(member.fetch(:@id)).to be_nil
          expect(member.fetch(:name)).to eq @student.name
          expect(member.fetch(:img)).to eq @student.avatar_image_url
          expect(member.fetch(:email)).to eq @student.email
          expect(member.fetch(:familyName)).to eq @student.last_name
          expect(member.fetch(:givenName)).to eq @student.first_name
          expect(member.fetch(:resultSourcedId)).to be_nil
          expect(member.fetch(:sourcedId)).to be_nil
          expect(member.fetch(:userId)).to eq(@student.lti_context_id)
        end
      end
    end

    context "course with multiple enrollments" do
      before do
        course_with_teacher(active_course: true)
        @course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")
        @ta = user_model
        @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")
        @student = user_model
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
      end

      describe "#as_json" do
        it "provides the right next_page url when no page/per_page/role params are given" do
          stub_const("Api::PER_PAGE", 1)
          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq "https"
          expect(uri.host).to eq "localhost"
          expect(uri.port).to eq 3000
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq "page=2&per_page=1"
        end

        it "provides the right next_page url when page/per_page/role params are given" do
          presenter = PagePresenter.new(@course, @user, base_url, page: 2, per_page: 1, role: "Instructor")
          hash = presenter.as_json

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq "https"
          expect(uri.host).to eq "localhost"
          expect(uri.port).to eq 3000
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq "page=3&per_page=1&role=Instructor"
        end

        it "returns nil for the next page url when the last page in the collection was requested" do
          allow(Api).to receive(:per_page).and_return(1)
          presenter = PagePresenter.new(@course, @user, base_url, page: 3, per_page: 1, role: "Instructor")
          hash = presenter.as_json

          expect(hash.fetch(:nextPage)).to be_nil
        end
      end
    end
  end
end
