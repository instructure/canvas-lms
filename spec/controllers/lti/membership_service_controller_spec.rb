#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/membership_service_controller"

module Lti
  describe MembershipServiceController do
    context 'user not enrolled in course' do
      before(:each) do
        course_model
        user_model
        pseudonym(@user)
        @user.save!
        token = @user.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#course_index' do
        it 'returns 401 if user is not part of course' do
          get 'course_index', course_id: @course.id
          assert_unauthorized
        end
      end
    end

    context 'course with single enrollment' do
      before(:each) do
        course_with_teacher
        @course.offer!
      end

      describe "#course_index" do
        context 'without access token' do
          it 'requires a user' do
            get 'course_index', course_id: @course.id
            assert_unauthorized
          end
        end

        context 'with access token' do
          before(:each) do
            pseudonym(@teacher)
            @teacher.save!
            token = @teacher.access_tokens.create!(purpose: 'test').full_token
            @request.headers['Authorization'] = "Bearer #{token}"
          end

          it 'outputs the expected data in the expected format at the top level' do
            get 'course_index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            expect(hash.keys.size).to eq(6)

            expect(hash.fetch(:@id)).to be_nil
            expect(hash.fetch(:@type)).to eq 'Page'
            expect(hash.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(hash.fetch(:differences)).to be_nil
            expect(hash.fetch(:nextPage)).to be_nil
            expect(hash.fetch(:pageOf)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the container level' do
            get 'course_index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            container = hash[:pageOf]

            expect(container.size).to eq 5
            expect(container.fetch(:@id)).to be_nil
            expect(container.fetch(:@type)).to eq 'LISMembershipContainer'
            expect(container.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(container.fetch(:membershipPredicate)).to eq 'http://www.w3.org/ns/org#membership'
            expect(container.fetch(:membershipSubject)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the context level' do
            get 'course_index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            @course.reload
            context = hash[:pageOf][:membershipSubject]

            expect(context.size).to eq 5
            expect(context.fetch(:@id)).to be_nil
            expect(context.fetch(:@type)).to eq 'Context'
            expect(context.fetch(:name)).to eq @course.name
            expect(context.fetch(:contextId)).to eq @course.lti_context_id
            expect(context.fetch(:membership)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the membership level' do
            get 'course_index', course_id: @course.id
            hash = json_parse.with_indifferent_access
            @teacher.reload
            memberships = hash[:pageOf][:membershipSubject][:membership]

            expect(memberships.size).to eq 1

            membership = memberships[0]

            expect(membership.size).to eq 4
            expect(membership.fetch(:@id)).to be_nil
            expect(membership.fetch(:status)).to eq IMS::LIS::Statuses::SimpleNames::Active
            expect(membership.fetch(:role)).to match_array([IMS::LIS::Roles::Context::URNs::Instructor])

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

          context 'course with a group' do
            before(:each) do
              @group_category = @course.group_categories.create!(name: 'Membership')
              @group = @course.groups.create!(name: "Group", group_category: @group_category)
            end

            it 'outputs the expected data in the expected format at the membership level' do
              get 'course_index', course_id: @course.id, role: IMS::LIS::ContextType::URNs::Group
              hash = json_parse.with_indifferent_access
              @group.reload
              memberships = hash[:pageOf][:membershipSubject][:membership]

              expect(memberships.size).to eq 1

              membership = memberships[0]

              expect(membership.size).to eq 4
              expect(membership.fetch(:@id)).to be_nil
              expect(membership.fetch(:status)).to eq IMS::LIS::Statuses::SimpleNames::Active
              expect(membership.fetch(:role)).to match_array([IMS::LIS::ContextType::URNs::Group])

              member = membership.fetch(:member)
              expect(member.fetch(:@id)).to be_nil
              expect(member.fetch(:name)).to eq @group.name
              expect(member.fetch(:contextId)).to eq @group.lti_context_id
            end
          end
        end
      end
    end

    context 'course with multiple enrollments' do
      before(:each) do
        course_with_teacher
        @course.enroll_user(@teacher, 'TeacherEnrollment', enrollment_state: 'active')
        @ta = user_model
        @course.enroll_user(@ta, 'TaEnrollment', enrollment_state: 'active')
        @student = user_model
        @course.enroll_user(@student, 'StudentEnrollment', enrollment_state: 'active')

        pseudonym(@teacher)
        @teacher.save!
        token = @teacher.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#as_json' do
        it 'provides the right next_page url when no page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'course_index', course_id: @course.id
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq 'page=2&per_page=1'
        end

        it 'provides the right next_page url when page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'course_index', course_id: @course.id, page: 2, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/courses/#{@course.id}/membership_service"
          expect(uri.query).to eq 'page=3&per_page=1&role=Instructor'
        end

        it 'returns nil for the next page url when the last page in the collection was requested' do
          Api.stubs(:per_page).returns(1)
          get 'course_index', course_id: @course.id, page: 3, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          expect(hash.fetch(:nextPage)).to be_nil
        end
      end
    end

    context 'user not in course group' do
      before(:each) do
        course_with_teacher
        @course.offer!
        user_model
        @course.enroll_user(@user, 'StudentEnrollment', enrollment_state: 'active')
        @group_category = @course.group_categories.create!(name: 'Membership')
        @group = @course.groups.create!(name: 'Group 1', group_category: @group_category)
        pseudonym(@user)
        @user.save!
        token = @user.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#group_index' do
        it 'returns 401 if user is not part of group' do
          get 'group_index', group_id: @group.id
          assert_unauthorized
        end
      end
    end

    context 'user not in account group' do
      before(:each) do
        user_model
        group_model
        pseudonym(@user)
        @user.save!
        token = @user.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#group_index' do
        it 'returns 401 if user is not part of group' do
          get 'group_index', group_id: @group.id
          assert_unauthorized
        end
      end
    end

    context 'group with single student' do
      before(:each) do
        course_with_teacher
        @course.offer!
        @student = user_model
        @course.enroll_user(@student, 'StudentEnrollment', enrollment_state: 'active')
        @group_category = @course.group_categories.create!(name: 'Membership')
        @group = @course.groups.create!(name: 'Group 1', group_category: @group_category)
        @group.add_user(@student)
      end

      describe "#group_index" do
        context 'without access token' do
          it 'requires a user' do
            get 'group_index', group_id: @group.id
            assert_unauthorized
          end
        end

        context 'with access token' do
          before(:each) do
            pseudonym(@student)
            @student.save!
            token = @student.access_tokens.create!(purpose: 'test').full_token
            @request.headers['Authorization'] = "Bearer #{token}"
          end

          it 'outputs the expected data in the expected format at the top level' do
            get 'group_index', group_id: @group.id
            hash = json_parse.with_indifferent_access
            expect(hash.keys.size).to eq(6)

            expect(hash.fetch(:@id)).to be_nil
            expect(hash.fetch(:@type)).to eq 'Page'
            expect(hash.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(hash.fetch(:differences)).to be_nil
            expect(hash.fetch(:nextPage)).to be_nil
            expect(hash.fetch(:pageOf)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the container level' do
            get 'group_index', group_id: @group.id
            hash = json_parse.with_indifferent_access
            container = hash[:pageOf]

            expect(container.size).to eq 5
            expect(container.fetch(:@id)).to be_nil
            expect(container.fetch(:@type)).to eq 'LISMembershipContainer'
            expect(container.fetch(:@context)).to eq 'http://purl.imsglobal.org/ctx/lis/v2/MembershipContainer'
            expect(container.fetch(:membershipPredicate)).to eq 'http://www.w3.org/ns/org#membership'
            expect(container.fetch(:membershipSubject)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the context level' do
            get 'group_index', group_id: @group.id
            hash = json_parse.with_indifferent_access
            @group.reload
            context = hash[:pageOf][:membershipSubject]

            expect(context.size).to eq 5
            expect(context.fetch(:@id)).to be_nil
            expect(context.fetch(:@type)).to eq 'Context'
            expect(context.fetch(:name)).to eq @group.name
            expect(context.fetch(:contextId)).to eq @group.lti_context_id
            expect(context.fetch(:membership)).not_to be_nil
          end

          it 'outputs the expected data in the expected format at the membership level' do
            get 'group_index', group_id: @group.id
            hash = json_parse.with_indifferent_access
            @student.reload
            memberships = hash[:pageOf][:membershipSubject][:membership]

            expect(memberships.size).to eq 1

            membership = memberships[0]

            expect(membership.size).to eq 4
            expect(membership.fetch(:@id)).to be_nil
            expect(membership.fetch(:status)).to eq IMS::LIS::Statuses::SimpleNames::Active
            expect(membership.fetch(:role)).to match_array([IMS::LIS::Roles::Context::URNs::Member])

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
    end

    context 'group with multiple students' do
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

        pseudonym(@student1)
        @student1.save!
        token = @student1.access_tokens.create!(purpose: 'test').full_token
        @request.headers['Authorization'] = "Bearer #{token}"
      end

      describe '#as_json' do
        it 'provides the right next_page url when no page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'group_index', group_id: @group.id
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/groups/#{@group.id}/membership_service"
          expect(uri.query).to eq 'page=2&per_page=1'
        end

        it 'provides the right next_page url when page/per_page/role params are given' do
          Api.stubs(:per_page).returns(1)
          get 'group_index', group_id: @group.id, page: 2, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          uri = URI(hash.fetch(:nextPage))
          expect(uri.scheme).to eq 'http'
          expect(uri.host).to eq 'test.host'
          expect(uri.path).to eq "/api/lti/groups/#{@group.id}/membership_service"
          expect(uri.query).to eq 'page=3&per_page=1&role=Instructor'
        end

        it 'returns nil for the next page url when the last page in the collection was requested' do
          Api.stubs(:per_page).returns(1)
          get 'group_index', group_id: @group.id, page: 3, per_page: 1, role: 'Instructor'
          hash = json_parse.with_indifferent_access

          expect(hash.fetch(:nextPage)).to be_nil
        end
      end
    end
  end
end
