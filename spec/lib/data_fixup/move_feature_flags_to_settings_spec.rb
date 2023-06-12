# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe DataFixup::MoveFeatureFlagsToSettings do
  before :once do
    Account.add_setting :some_root_only_setting, boolean: true, root_only: true, default: false
    Account.add_setting :some_course_setting, boolean: true, default: false, inheritable: true
    Course.add_setting :some_course_setting, boolean: true, inherited: true

    @root_account = account_model
    @teacher = user_with_pseudonym account: @root_account
    @sub_account = account_model parent_account: @root_account
    @course = course_with_teacher(user: @teacher, account: @sub_account, active_all: true).course
  end

  def reload_all
    @root_account = Account.find(@root_account.id)
    @sub_account = Account.find(@sub_account.id)
    @course = Course.find(@course.id)
    @teacher = User.find(@teacher.id)
  end

  def with_feature_definitions
    allow(Feature).to receive(:definitions).and_return({
                                                         "course_feature_going_away" => Feature.new(feature: "course_feature_going_away", applies_to: "Course", state: "hidden"),
                                                         "root_account_feature_going_away" => Feature.new(feature: "root_account_feature_going_away", applies_to: "RootAccount", state: "hidden"),
                                                       })
    yield
    allow(Feature).to receive(:definitions).and_call_original
  end

  it "handles unknown ff state gracefully" do
    override = @root_account.feature_flags.build(feature: "root_account_feature_going_away")
    override.state = "some_invalid_state"
    override.save!(validate: false)

    DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_root_only_setting)
    reload_all

    expect(@root_account.some_root_only_setting?).to be(false)
    expect(@root_account.settings).not_to have_key(:some_root_only_setting)
  end

  context "RootAccount" do
    it "works for root account feature flag when allowed" do
      with_feature_definitions do
        @root_account.allow_feature!(:root_account_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_root_only_setting)
      reload_all

      expect { @root_account.feature_enabled?(:root_account_feature_going_away) }.to raise_error("no such feature - root_account_feature_going_away")
      expect(@root_account.some_root_only_setting?).to be(false)
      expect(@root_account.settings).not_to have_key(:some_root_only_setting)
    end

    it "works for root account feature flag when off" do
      with_feature_definitions do
        @root_account.disable_feature!(:root_account_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_root_only_setting)
      reload_all

      expect(@root_account.some_root_only_setting?).to be(false)
      expect(@root_account.settings).to have_key(:some_root_only_setting)
    end

    it "works for root account feature flag when on" do
      with_feature_definitions do
        @root_account.enable_feature!(:root_account_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_root_only_setting)
      reload_all

      expect(@root_account.some_root_only_setting?).to be(true)
      expect(@root_account.settings).to have_key(:some_root_only_setting)
    end

    it "works for root account feature flag when not overridden" do
      DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_root_only_setting)
      reload_all

      expect(@root_account.some_root_only_setting?).to be(false)
      expect(@root_account.settings).not_to have_key(:some_root_only_setting)
    end

    it "migrates an unknown setting" do
      with_feature_definitions do
        @root_account.enable_feature!(:root_account_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:root_account_feature_going_away, "RootAccount", :some_other_root_only_setting)
      reload_all

      expect(@root_account.settings[:some_other_root_only_setting]).to be(true)
    end
  end

  context "AccountAndCourseInherited" do
    it "works for course feature flag when allowed and enabled in course" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @sub_account.allow_feature!(:course_feature_going_away)
        @course.enable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(false)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).not_to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(false)
      expect(@sub_account.some_course_setting[:locked]).to be(false)
      expect(@sub_account.settings).not_to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(true)
      expect(@course.settings).to have_key(:some_course_setting)
    end

    it "works for course feature flag when allowed and disabled in course" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @sub_account.allow_feature!(:course_feature_going_away)
        @course.disable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(false)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).not_to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(false)
      expect(@sub_account.some_course_setting[:locked]).to be(false)
      expect(@sub_account.settings).not_to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(false)
      expect(@course.settings).to have_key(:some_course_setting)
    end

    it "works for course feature flag when off" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @sub_account.disable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(false)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).not_to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(false)
      expect(@sub_account.some_course_setting[:locked]).to be(true)
      expect(@sub_account.settings).to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(false)
      expect(@course.settings).not_to have_key(:some_course_setting)
    end

    it "works for course feature flag when on" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @sub_account.enable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(false)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).not_to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(true)
      expect(@sub_account.some_course_setting[:locked]).to be(true)
      expect(@sub_account.settings).to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(true)
      expect(@course.settings).not_to have_key(:some_course_setting)
    end

    it "works for course feature flag when allowed_on" do
      with_feature_definitions do
        @root_account.set_feature_flag!(:course_feature_going_away, Feature::STATE_DEFAULT_ON)
        @sub_account.set_feature_flag!(:course_feature_going_away, Feature::STATE_DEFAULT_ON)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(true)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(true)
      expect(@sub_account.some_course_setting[:locked]).to be(false)
      expect(@sub_account.settings).to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(true)
      expect(@course.settings).not_to have_key(:some_course_setting)
    end

    it "works for course feature flag when not overridden" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_course_setting)
      reload_all

      expect(@root_account.some_course_setting[:value]).to be(false)
      expect(@root_account.some_course_setting[:locked]).to be(false)
      expect(@root_account.settings).not_to have_key(:some_course_setting)
      expect(@sub_account.some_course_setting[:value]).to be(false)
      expect(@sub_account.some_course_setting[:locked]).to be(false)
      expect(@sub_account.settings).not_to have_key(:some_course_setting)
      expect(@course.some_course_setting).to be(false)
      expect(@course.settings).not_to have_key(:some_course_setting)
    end

    it "migrates an unknown setting" do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @sub_account.enable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_other_account_setting)
      reload_all

      expect(@root_account.settings).not_to have_key(:some_other_account_setting)
      expect(@sub_account.settings).to have_key(:some_other_account_setting)
      expect(@sub_account.settings[:some_other_account_setting][:value]).to be(true)
      expect(@sub_account.settings[:some_other_account_setting][:locked]).to be(true)
      expect(@course.settings[:some_other_account_setting]).to be_nil
    end

    it "migrates an unknown setting that is overridden at a course, and it should not be enabled." do
      with_feature_definitions do
        @root_account.allow_feature!(:course_feature_going_away)
        @course.disable_feature!(:course_feature_going_away)
        @sub_account.enable_feature!(:course_feature_going_away)
      end
      DataFixup::MoveFeatureFlagsToSettings.run(:course_feature_going_away, "AccountAndCourseInherited", :some_other_account_setting)
      reload_all

      expect(@root_account.settings).not_to have_key(:some_other_account_setting)
      expect(@sub_account.settings).to have_key(:some_other_account_setting)
      expect(@sub_account.settings[:some_other_account_setting][:value]).to be(true)
      expect(@sub_account.settings[:some_other_account_setting][:locked]).to be(true)
      expect(@course.settings[:some_other_account_setting]).to be_nil
    end
  end
end
