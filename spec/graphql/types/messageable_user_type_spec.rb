# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::MessageableUserType do
  before(:once) do
    student_in_course(active_all: true).user
  end

  let(:messageable_user_type) do
    GraphQLTypeTester.new(
      @student,
      current_user: @teacher,
      domain_root_account: @course.account.root_account
    )
  end

  context "node" do
    it "works" do
      expect(messageable_user_type.resolve("_id")).to eq @student.id.to_s
      expect(messageable_user_type.resolve("name")).to eq @student.name
      expect(messageable_user_type.resolve("shortName")).to eq @student.short_name
      expect(messageable_user_type.resolve("pronouns")).to eq @student.pronouns
    end
  end

  context "pronouns" do
    it "returns user pronouns" do
      @student.account.root_account.settings[:can_add_pronouns] = true
      @student.account.root_account.save!
      @student.pronouns = "kame/hame"
      @student.save!
      expect(messageable_user_type.resolve("pronouns")).to eq "kame/hame"
    end
  end

  context "sis_id" do
    before(:once) do
      @account = @course.account.root_account
      @student.pseudonyms.create!(
        account: @account,
        unique_id: "student@example.com",
        sis_user_id: "SIS123456"
      )
    end

    let(:teacher_tester) do
      GraphQLTypeTester.new(
        @teacher,
        current_user: @teacher,
        domain_root_account: @account,
        request: ActionDispatch::TestRequest.create
      )
    end

    def resolve_sis_ids(tester, context_arg = "course_#{@course.id}_students")
      tester.resolve(
        "recipients(context: \"#{context_arg}\") { usersConnection { nodes { sisId } } }"
      )
    end

    context "when feature flag is disabled" do
      before do
        Account.site_admin.disable_feature!(:inbox_sis_id_for_duplicates)
      end

      it "returns nil even for teachers with read_sis permission" do
        result = resolve_sis_ids(teacher_tester)
        expect(result).to all(be_nil)
      end
    end

    context "when feature flag is enabled" do
      # TODO: clean :inbox_sis_id_for_duplicates flag after release, VICE-5840
      before do
        Account.site_admin.enable_feature!(:inbox_sis_id_for_duplicates)
      end

      it "returns sis_id for teachers with read_sis permission" do
        result = resolve_sis_ids(teacher_tester)
        expect(result).to include("SIS123456")
      end

      it "returns nil for users without read_sis permission" do
        # Create a second student with SIS so there is a recipient with a sisId
        other_student = student_in_course(active_all: true).user
        other_student.pseudonyms.create!(
          account: @account,
          unique_id: "other_student@example.com",
          sis_user_id: "SIS789"
        )
        student_tester = GraphQLTypeTester.new(
          @student,
          current_user: @student,
          domain_root_account: @account,
          request: ActionDispatch::TestRequest.create
        )
        result = resolve_sis_ids(student_tester)
        expect(result).to all(be_nil)
      end

      it "returns sis_id for users with manage_sis permission" do
        admin = account_admin_user(account: @account)
        admin_tester = GraphQLTypeTester.new(
          admin,
          current_user: admin,
          domain_root_account: @account,
          request: ActionDispatch::TestRequest.create
        )
        result = resolve_sis_ids(admin_tester)
        expect(result).to include("SIS123456")
      end

      it "returns nil when user has no pseudonym with sis_user_id" do
        student_in_course(active_all: true)
        result = resolve_sis_ids(teacher_tester)
        # @student has SIS123456; the newly added student has none
        expect(result).to include("SIS123456")
        expect(result).to include(nil)
      end

      # This test ensures that the current_user is properly passed through to the SisPseudonym extension, which is
      # necessary for correct filtering of instructure identity pseudonyms for the multiple_root_accounts plugin.
      it "passes current_user to SisPseudonym.for" do
        expect(SisPseudonym).to receive(:for)
          .with(having_attributes(id: @student.id), anything, hash_including(current_user: @teacher))
          .and_call_original
        teacher_tester.resolve(
          "recipients(context: \"course_#{@course.id}_students\") { usersConnection { nodes { sisId } } }"
        )
      end

      it "uses course context for permission check" do
        course_tester = GraphQLTypeTester.new(
          @teacher,
          current_user: @teacher,
          domain_root_account: @account,
          course: @course,
          request: ActionDispatch::TestRequest.create
        )
        result = resolve_sis_ids(course_tester)
        expect(result).to include("SIS123456")
      end
    end
  end
end
