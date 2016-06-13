#
# Copyright (C) 2015-2016 Instructure, Inc.
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

describe GradingPeriod, "permissions:" do
  let(:period_helper) { Factories::GradingPeriodHelper.new }
  let(:permissions) { [:read, :create, :update, :delete] }

  context "course belonging to root account" do
    before(:once) do
      @root_account = Account.default
      Account.default.enable_feature!(:multiple_grading_periods)
      @sub_account = @root_account.sub_accounts.create!
      course_with_teacher(account: @root_account, active_all: true)
      course_with_student(course: @course, active_all: true)
      @root_account_period = period_helper.create_with_group_for_account(@root_account)
      @course_period = period_helper.create_with_group_for_course(@course)
    end

    context "root-account admin" do
      before(:once) do
        account_admin_user(account: @root_account)
        @root_account_admin = @admin
      end

      it "can read, create, update, and delete root-account level " \
       "grading periods" do
        expect(@root_account_period.
          rights_status(@root_account_admin, *permissions)).to eq({
          read:   true,
          create: true,
          update: true,
          delete: true
        })
      end

      it "can read, update and delete but NOT create course level " \
        "grading periods" do
        expect(@course_period.
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

      it "can read but NOT create, update, nor delete root-account " \
        "grading periods" do
        expect(@root_account_period.
          rights_status(@sub_account_admin, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can NOT read, create, update, nor delete course level " \
        "grading periods, when the course is under the root-account" do
        expect(@course_period.
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
        "grading periods" do
        expect(@root_account_period.
          rights_status(@teacher, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can read, update, and delete but NOT create course level " \
       "grading periods" do
        expect(@course_period.
          rights_status(@teacher, *permissions)).to eq({
          read:   true,
          create: false,
          update: true,
          delete: true
        })
      end
    end

    context "student" do
      it "can read but NOT create, update, nor delete root-account " \
        "grading periods" do
        expect(@root_account_period.
          rights_status(@student, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can read but NOT create, update, nor delete course level " \
        "grading periods" do
        expect(@course_period.
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

      it "can not do anything" do
        expect(@course_period.
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
      Account.default.enable_feature!(:multiple_grading_periods)
      @sub_account = @root_account.sub_accounts.create!
      course_with_teacher(account: @sub_account, active_all: true)
      course_with_student(course: @course, active_all: true)
      @root_account_period = period_helper.create_with_group_for_account(@root_account)
      @course_period = period_helper.create_with_group_for_course(@course)
    end

    context "root-account admin" do
      before(:once) do
        account_admin_user(account: @root_account)
        @root_account_admin = @admin
      end

      it "can read, create, update, and delete root-account level " \
        "grading periods" do
        expect(@root_account_period.
          rights_status(@root_account_admin, *permissions)).to eq({
          read:   true,
          create: true,
          update: true,
          delete: true
        })
      end

      it "can read, update, and delete but NOT create course level " \
        "grading periods" do
        expect(@course_period.
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

      it "can NOT create, update, nor delete root-account level grading " \
        "periods, but can read them" do
        expect(@root_account_period.
          rights_status(@sub_account_admin, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can NOT create course level grading periods when the course is " \
        "under the sub-account, but can read, update, and delete" do
        expect(@course_period.
          rights_status(@sub_account_admin, *permissions)).to eq({
          read:   true,
          create: false,
          update: true,
          delete: true
        })
      end
    end

    context "teacher" do
      it "can NOT create, update, nor delete root-account level grading " \
        "periods, but can read them" do
        expect(@root_account_period.
          rights_status(@teacher, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can read, update, and delete but NOT create course level " \
        "grading periods" do
        expect(@course_period.
          rights_status(@teacher, *permissions)).to eq({
          read:   true,
          create: false,
          update: true,
          delete: true
        })
      end
    end

    context "student" do
      it "can read but NOT create, update, nor delete root-account level " \
        "grading periods" do
        expect(@root_account_period.
          rights_status(@student, *permissions)).to eq({
          read:   true,
          create: false,
          update: false,
          delete: false
        })
      end

      it "can read but NOT create, update, nor delete course level " \
        "grading periods" do
        expect(@course_period.
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

      it "cannot do anything with grading periods" do
        expect(@course_period.
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
