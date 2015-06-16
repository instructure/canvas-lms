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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GradingPeriodGroup do
  describe "validation" do
    it "should not be valid without a course or account" do
      grading_period_group = GradingPeriodGroup.new
      expect(grading_period_group).to_not be_valid
    end

    it "should not be valid with a course AND an account" do
      course = course()
      grading_period_group = course.grading_period_groups.new
      grading_period_group.account = Account.default
      expect(grading_period_group).to_not be_valid
    end

    it "should be valid with an account" do
      grading_period_group = Account.default.grading_period_groups.new
      expect(grading_period_group).to be_valid
    end

    it "should not be able to mass-assign the account id" do
      grading_period_group = GradingPeriodGroup.new(account_id: Account.default.id)
      expect(grading_period_group).to_not be_valid
    end

    it "should be valid with a course" do
      course = course()
      grading_period_group = course.grading_period_groups.new
      expect(grading_period_group).to be_valid
    end

    it "should not be able to mass-assign the course id" do
      course = course()
      grading_period_group = GradingPeriodGroup.new(course_id: course.id)
      expect(grading_period_group).to_not be_valid
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

  describe "#destroy" do
    let(:grading_period_group) { Account.default.grading_period_groups.create }

    it "should soft delete by setting the workflow status to deleted" do
      expect(grading_period_group).to_not be_deleted
      grading_period_group.destroy
      expect(grading_period_group).to be_deleted
      expect(grading_period_group).to_not be_destroyed
    end

    it "should soft delete grading periods that belong to the grading period group when it is destroyed" do
      grading_period_1 = grading_period_group.grading_periods.create!(start_date: Time.now, end_date: 2.months.from_now)
      grading_period_2 = grading_period_group.grading_periods.create!(start_date: 2.months.from_now, end_date: 3.months.from_now)
      expect(grading_period_group).to_not be_deleted
      expect(grading_period_1).to_not be_deleted
      expect(grading_period_2).to_not be_deleted
      grading_period_group.destroy
      expect(grading_period_1).to be_deleted
      expect(grading_period_1).to_not be_destroyed
      expect(grading_period_2).to be_deleted
      expect(grading_period_2).to_not be_destroyed
    end
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
end
