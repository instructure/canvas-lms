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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradingPeriodGroup do
  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  describe "validation" do
    it "is valid with only an active enrollment term" do
      enrollment_term = Account.default.enrollment_terms.create!
      group = GradingPeriodGroup.new
      group.enrollment_terms << enrollment_term
      expect(group).to be_valid
    end

    it "is valid with an account" do
      group = GradingPeriodGroup.new
      group.account = Account.default
      expect(group).to be_valid
    end

    it "is valid with a course" do
      course = Course.create!(account: Account.default)
      group = GradingPeriodGroup.new
      group.course = course
      expect(group).to be_valid
    end

    it "is valid with both an account and enrollment terms" do
      term_1 = Account.default.enrollment_terms.create!
      term_2 = Account.default.enrollment_terms.create!
      group = GradingPeriodGroup.new
      group.account = Account.default
      group.enrollment_terms << term_1
      group.enrollment_terms << term_2
      expect(group).to be_valid
    end

    it "is not valid without an account, a course, or an enrollment term" do
      group = GradingPeriodGroup.new
      expect(group).not_to be_valid
    end

    it "is not valid with both an account and a course" do
      course = Course.create!(account: Account.default)
      group = GradingPeriodGroup.new
      group.account = Account.default
      group.course = course
      expect(group).not_to be_valid
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

    it "is not valid with an account and enrollment terms from different accounts" do
      group = GradingPeriodGroup.new
      group.account = Account.default
      other_account = account_model
      term = other_account.enrollment_terms.create!
      group.enrollment_terms << term
      expect(group).not_to be_valid
    end

    it "is not valid with enrollment terms associated with different accounts" do
      account_1 = account_model
      account_2 = account_model
      term_1 = account_1.enrollment_terms.create!
      term_2 = account_2.enrollment_terms.create!
      group = GradingPeriodGroup.new
      group.enrollment_terms << term_1
      group.enrollment_terms << term_2
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

    it "is not able to mass-assign the account id" do
      group = GradingPeriodGroup.new(account_id: Account.default.id)
      expect(group.account_id).to be_nil
      expect(group.account).to be_nil
    end

    it "is not able to mass-assign the course id" do
      course = course()
      group = GradingPeriodGroup.new(course_id: course.id)
      expect(group.course_id).to be_nil
      expect(group.course).to be_nil
    end
  end

  describe "#multiple_grading_periods_enabled?" do
    context "grading period group with an account" do
      let(:grading_period_group) { Account.default.grading_period_groups.new }

      it "should return false if the multiple grading periods feature flag has not been enabled" do
        expect(grading_period_group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "should return true if the multiple grading periods feature flag has been enabled" do
        grading_period_group.account.enable_feature!(:multiple_grading_periods)
        expect(grading_period_group.multiple_grading_periods_enabled?).to eq(true)
      end
    end

    context "grading period group with a course" do
      let(:grading_period_group) do
        course = course()
        course.grading_period_groups.new
      end

      it "should return false if the multiple grading periods feature flag has not been enabled" do
        expect(grading_period_group.multiple_grading_periods_enabled?).to eq(false)
      end

      it "should return true if the multiple grading periods feature flag has been enabled" do
        grading_period_group.course.root_account.enable_feature!(:multiple_grading_periods)
        expect(grading_period_group.multiple_grading_periods_enabled?).to eq(true)
      end
    end
  end

  context "Soft deletion" do
    let(:account) { Account.create! }
    let(:creation_arguments) { {} }
    subject { account.grading_period_groups }
    include_examples "soft deletion"
  end

  describe "permissions:" do
    context "course belonging to root account" do
      before :once do
        @root_account = Account.default
        @root_account.enable_feature!(:multiple_grading_periods)
        @sub_account = @root_account.sub_accounts.create!
        course_with_teacher(account: @root_account, active_all: true)
        course_with_student(course: @course, active_all: true)
        @root_account_grading_period_group = @root_account.grading_period_groups.create!
        @sub_account_grading_period_group = @sub_account.grading_period_groups.create!
        @course_grading_period_group = @course.grading_period_groups.create!
      end

      context "root-account admin" do
        before :once do
          account_admin_user(account: @root_account)
        end

        it "should be able to read and manage root-account level grading period groups" do
          expect(@root_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage course level grading period groups" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end


        it "should NOT be able to read or manage course level grading period groups, when the course is under the root-account" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
        end
      end

      context "teacher" do
        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to read or manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: false, manage: false })
        end

        it "should be able to read and manage course level grading period groups" do
          expect(@course_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: true})
        end
      end

      context "student" do
        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to read or manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: false, manage: false })
        end

        it "should NOT be able to manage course level grading period groups, but should be able to read them" do
          expect(@course_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false})
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @root_account)
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "should return false for once permissions" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
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
        @root_account_grading_period_group = @root_account.grading_period_groups.create!
        @sub_account_grading_period_group = @sub_account.grading_period_groups.create!
        @course_grading_period_group = @course.grading_period_groups.create!
      end

      context "root-account admin" do
        before(:once) do
          account_admin_user(account: @root_account)
        end

        it "should be able to read and manage root-account level grading period groups" do
          expect(@root_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end

        it "should be able to read and manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end


        it "should be able to read and manage course level grading period groups" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "sub-account admin" do
        before(:once) do
          account_admin_user(account: @sub_account)
        end

        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage sub-account level grading period groups" do
          expect(@sub_account_grading_period_group.rights_status(@admin, :read, :manage)).to eq({read: true, manage: true })
        end


        it "should be able to read and manage course level grading period groups, when the course is under the sub-account" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({read: true, manage: true })
        end
      end

      context "teacher" do
        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage sub-account level grading period groups, but should be able to read them" do
          expect(@sub_account_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should be able to read and manage course level grading period groups" do
          expect(@course_grading_period_group.rights_status(@teacher, :read, :manage)).to eq({ read: true, manage: true })
        end
      end

      context "student" do
        it "should NOT be able to manage root-account level grading period groups, but should be able to read them" do
          expect(@root_account_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage sub-account level grading period groups, but should be able to read them" do
          expect(@sub_account_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false })
        end

        it "should NOT be able to manage course level grading period groups, but should be able to read them" do
          expect(@course_grading_period_group.rights_status(@student, :read, :manage)).to eq({ read: true, manage: false})
        end
      end

      context "multiple grading periods feature flag turned off" do
        before(:once) do
          account_admin_user(account: @sub_account)
          @root_account.disable_feature! :multiple_grading_periods
        end

        it "should return false for all permissions" do
          expect(@course_grading_period_group.rights_status(@admin, :read, :manage)).to eq({ read: false, manage: false })
        end
      end
    end
  end

  describe "#enrollment_terms" do
    it "returns the associated enrollment terms" do
      account = Account.default
      term_1 = account.enrollment_terms.create!
      term_2 = account.enrollment_terms.create!
      group = group_helper.create_for_enrollment_term(term_1)
      term_2.update_attribute(:grading_period_group, group)
      group.save!
      group.reload
      expect(group.enrollment_terms).to match_array([term_1, term_2])
    end
  end
end
