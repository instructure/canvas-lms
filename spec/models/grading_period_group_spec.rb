#
# Copyright (C) 2014-2016 Instructure, Inc.
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

require_relative '../spec_helper'

describe GradingPeriodGroup do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  describe "#title" do
    it "can be mass-assigned" do
      group = GradingPeriodGroup.new(title: "Example Title")
      expect(group.title).to eql("Example Title")
    end

    it "is optional" do
      group = GradingPeriodGroup.new
      expect(group.title).to be_nil
    end
  end

  describe "validation" do
    it "is valid with only an active enrollment term" do
      enrollment_term = Account.default.enrollment_terms.create!
      group = GradingPeriodGroup.new
      group.enrollment_terms << enrollment_term
      expect(group).to be_valid
    end

    it "is valid with a course" do
      course = Course.create!(account: Account.default)
      group = GradingPeriodGroup.new
      group.course = course
      expect(group).to be_valid
    end

    it "is not valid without a course or an enrollment term" do
      grading_period_group = GradingPeriodGroup.new
      expect(grading_period_group).not_to be_valid
    end

    it "is not valid with enrollment terms associated with different accounts" do
      account_1 = account_model
      account_2 = account_model
      term_1 = account_1.enrollment_terms.create!
      term_2 = account_2.enrollment_terms.create!
      grading_period_group = GradingPeriodGroup.new
      grading_period_group.enrollment_terms << term_1
      grading_period_group.enrollment_terms << term_2
      expect(grading_period_group).not_to be_valid
    end

    it "is valid with only deleted enrollment terms and is deleted" do
      enrollment_term = Account.default.enrollment_terms.create!
      enrollment_term.destroy
      group = GradingPeriodGroup.new
      group.enrollment_terms << enrollment_term
      group.workflow_state = 'deleted'
      expect(group).to be_valid
    end

    it "is not valid with only deleted enrollment terms and not deleted" do
      enrollment_term = Account.default.enrollment_terms.create!
      enrollment_term.destroy
      group = GradingPeriodGroup.new
      group.enrollment_terms << enrollment_term
      expect(group).not_to be_valid
    end

    it "is not valid with only deleted enrollment terms and undeleted" do
      enrollment_term = Account.default.enrollment_terms.create!
      group = group_helper.create_for_enrollment_term(enrollment_term)
      enrollment_term.destroy
      group.reload
      group.workflow_state = 'active'
      expect(group).not_to be_valid
    end

    it "is not valid with enrollment terms with different accounts and workflow states" do
      account_1 = account_model
      account_2 = account_model
      term_1 = account_1.enrollment_terms.create!
      term_2 = account_2.enrollment_terms.create!
      term_2.destroy
      group = GradingPeriodGroup.new
      group.enrollment_terms << term_1
      group.enrollment_terms << term_2
      expect(group).not_to be_valid
    end

    it "is not able to mass-assign the course id" do
      course = course()
      grading_period_group = GradingPeriodGroup.new(course_id: course.id)
      expect(grading_period_group.course_id).to be_nil
      expect(grading_period_group.course).to be_nil
    end
  end

  describe "#save" do
    it "deletes orphaned grading period groups" do
      term_1 = Account.default.enrollment_terms.create!
      group_1 = group_helper.create_for_enrollment_term(term_1)
      term_2 = Account.default.enrollment_terms.create!
      group_2 = GradingPeriodGroup.new
      group_2.enrollment_terms.concat([term_1, term_2])
      group_2.save!
      expect(group_1.reload).to be_deleted
    end
  end

  describe "#multiple_grading_periods_enabled?" do
    let(:account) { Account.default }

    context "when associated with an enrollment term" do
      let(:term) { account.enrollment_terms.create! }
      let(:group) { group_helper.create_for_enrollment_term(term) }

      it "returns false if the multiple grading periods feature flag has not been enabled" do
        expect(group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "returns true if the multiple grading periods feature flag has been enabled" do
        account.enable_feature!(:multiple_grading_periods)
        expect(group.multiple_grading_periods_enabled?).to eq(true)
      end
    end

    context "when associated with a course" do
      let(:course) { Course.create!(account: account) }
      let(:group) { group_helper.create_for_course(course) }

      it "returns false if the multiple grading periods feature flag has not been enabled" do
        expect(group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "returns true if the multiple grading periods feature flag has been enabled" do
        course.root_account.enable_feature!(:multiple_grading_periods)
        expect(group.multiple_grading_periods_enabled?).to eq(true)
      end
    end
  end

  context "Soft deletion" do
    let(:account) { Account.create! }
    let(:course) { Course.create!(account: account) }
    let(:creation_arguments) { {} }
    subject { course.grading_period_groups }
    include_examples "soft deletion"
  end

  describe "permissions" do
    let(:permissions) { [:read, :create, :update, :delete] }

    context "course belonging to root account" do
      before :once do
        @root_account = Account.default
        @root_account.enable_feature!(:multiple_grading_periods)
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        root_account_term = @root_account.enrollment_terms.create!
        sub_account_term = @sub_account.enrollment_terms.create!
        @root_account_group = group_helper.create_for_enrollment_term(root_account_term)
        @sub_account_group = group_helper.create_for_enrollment_term(sub_account_term)
        @course_group = group_helper.create_for_course(@course)
      end

      context "root-account admin" do
        before :once do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
        end

        it "can read, create, update, and delete root-account " \
          "grading period groups" do
          expect(@root_account_group.rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, update, and delete but NOT create course level " \
          "grading period groups" do
          expect(@course_group.rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
        end

        it "can read but NOT create, update, not delete root-account " \
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "cannot read, create, update, delete course " \
          "grading period groups, when the course is under a root-account" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end
      end

      context "teacher" do
        it "can read but NOT create, update, nor delete root-account " \
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "cannot read, create, update, nor delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, update, and delete but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "student" do
        it "can only read root account grading period groups" do
          expect(@root_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "cannot read, create, update, nor delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read course grading period groups" do
          expect(@course_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "cannot do anything with grading period groups" do
          expect(@course_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end
      end
    end

    context "course belonging to sub-account" do
      before(:once) do
        @root_account = Account.default
        @root_account.enable_feature!(:multiple_grading_periods)
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @sub_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        root_account_term = @root_account.enrollment_terms.create!
        sub_account_term = @sub_account.enrollment_terms.create!
        @root_account_group = group_helper.create_for_enrollment_term(root_account_term)
        @sub_account_group = group_helper.create_for_enrollment_term(sub_account_term)
        @course_group = group_helper.create_for_course(@course)
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account_admin = @admin
        end

        it "can read, create, update, and delete root-account " \
          "grading period groups" do
          expect(@root_account_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, update, and destroy but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@root_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
        end

        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, create, update, and delete sub-account " \
          "grading period groups" do
          expect(@sub_account_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: true,
            update: true,
            delete: true
          })
        end

        it "can read, update, and delete but NOT create course grading " \
          "period groups when the course is under the sub-account" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "teacher" do
        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read sub-account grading period groups" do
          expect(@sub_account_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can read, update and delete but NOT create course " \
          "grading period groups" do
          expect(@course_group.
            rights_status(@teacher, *permissions)).to eq({
            read:   true,
            create: false,
            update: true,
            delete: true
          })
        end
      end

      context "student" do
        it "can only read root-account grading period groups" do
          expect(@root_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read sub-account grading period groups" do
          expect(@sub_account_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end

        it "can only read sub-account grading period groups" do
          expect(@course_group.
            rights_status(@student, *permissions)).to eq({
            read:   true,
            create: false,
            update: false,
            delete: false
          })
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @sub_account_admin = @admin
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "cannot do anything with course grading period groups" do
          expect(@course_group.
            rights_status(@sub_account_admin, *permissions)).to eq({
            read:   false,
            create: false,
            update: false,
            delete: false
          })
        end
      end
    end
  end

  describe "#enrollment_terms" do
    it "returns the associated enrollment terms" do
      account = account_model
      term_1 = account.enrollment_terms.create!
      term_2 = account.enrollment_terms.create!
      group = group_helper.create_for_enrollment_term(term_1)
      term_2.update_attribute(:grading_period_group, group)
      group.reload
      expect(group.enrollment_terms).to match_array([term_1, term_2])
    end
  end
end
