# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe Loaders::OutcomeFriendlyDescriptionLoader do
  before do
    course_with_student(active_all: true)
    outcome_model(context: @course)
    @course_account = @course.account
    @parent_account = account_model
    @course_account.parent_account = @parent_account
    @course_account.save!

    Account.site_admin.enable_feature!(:outcomes_friendly_description)
    @parent_account.enable_feature!(:improved_outcomes_management)
    @course_account.enable_feature!(:improved_outcomes_management)
  end

  def create_course_fd
    @course_fd = OutcomeFriendlyDescription.create!({
                                                      learning_outcome: @outcome,
                                                      context: @course,
                                                      description: "course's description"
                                                    })
  end

  def create_account_fd
    @account_fd = OutcomeFriendlyDescription.create!({
                                                       learning_outcome: @outcome,
                                                       context: @course_account,
                                                       description: "account's description"
                                                     })
  end

  def create_parent_account_fd
    @parent_account_fd = OutcomeFriendlyDescription.create!({
                                                              learning_outcome: @outcome,
                                                              context: @parent_account,
                                                              description: "parent account's description"
                                                            })
  end

  it "correctly detect IOM FF for manually created courses" do
    course_model(account: Account.default.manually_created_courses_account)

    expect(@course.account.feature_enabled?(:improved_outcomes_management)).to be_falsey

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.valid_context? # this is needed to initialize @context
      expect(fd_loader.friendly_description_enabled?).to be_truthy
    end
  end

  it "prioritizes course fd" do
    create_course_fd
    create_account_fd
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to eq @course_fd
      end
    end
  end

  it "ignores course fd if we're loading for the account" do
    create_course_fd
    create_account_fd
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course_account.id, "Account"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to eq @account_fd
      end
    end
  end

  it "resolves account fd when there isn't any course fd" do
    create_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to eq @account_fd
      end
    end
  end

  it "resolves to parent account fd when there isn't any course and account fd" do
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to eq @parent_account_fd
      end
    end
  end

  it "resolves to parent account fd when there isn't any account fd" do
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @account.id, "Account"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to eq @parent_account_fd
      end
    end
  end

  it "resolves to nil when there is no fd associated with the outcome" do
    create_course_fd
    create_account_fd
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id + 1).then do |fd|
        expect(fd).to be_nil
      end
    end
  end

  it "resolves to nil when passsing invalid context type" do
    create_course_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "InvalidContextType"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to be_nil
      end
    end
  end

  it "resolves to nil when passsing invalid context id" do
    create_course_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id + 99, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to be_nil
      end
    end
  end

  it "resolves to nil if OFD FF disabled" do
    Account.site_admin.disable_feature!(:outcomes_friendly_description)

    create_course_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to be_nil
      end
    end
  end

  it "resolves to nil if IOM FF disabled" do
    @parent_account.disable_feature!(:improved_outcomes_management)

    create_course_fd
    create_account_fd
    create_parent_account_fd

    GraphQL::Batch.batch do
      fd_loader = Loaders::OutcomeFriendlyDescriptionLoader.for(
        @course.id, "Course"
      )
      fd_loader.load(@outcome.id).then do |fd|
        expect(fd).to be_nil
      end
    end
  end
end
