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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Features::QuizStatFeatureFlag" do
  let(:account) { Account.default }
  context "enables the feature" do
    it "when in a development env" do
      remove_quiz_stats!
      flag = Features::QuizStatFeatureFlag.new

      Rails.env.stubs(:test?).returns(false)
      Rails.env.stubs(:development?).returns(true)
      flag.register!

      account.feature_allowed?('quiz_stats').should be_truthy
    end

    it "when in a test env" do
      remove_quiz_stats!
      flag = Features::QuizStatFeatureFlag.new

      Rails.env.stubs(:test?).returns(true)
      Rails.env.stubs(:development?).returns(false)
      flag.register!

      account.feature_allowed?('quiz_stats').should be_truthy
    end

    it "when in beta" do
      remove_quiz_stats!
      flag = Features::QuizStatFeatureFlag.new

      Rails.env.stubs(:test?).returns(false)
      Rails.env.stubs(:development?).returns(false)
      flag.stubs(:in_beta?).returns(true)

      flag.register!

      account.feature_allowed?('quiz_stats').should be_truthy
    end
  end

  context "doesn't enable the feature" do
    it "when in production" do
      remove_quiz_stats!
      flag = Features::QuizStatFeatureFlag.new

      Rails.env.stubs(:test?).returns(false)
      Rails.env.stubs(:development?).returns(false)
      Rails.env.stubs(:production?).returns(true)

      flag.register!

      account.feature_allowed?('quiz_stats').should be_falsey
    end
  end

  def remove_quiz_stats!
    # need to strip quiz_stats from the frozen definitions hash on Feature
    features = {}
    Feature.definitions.each do |k, v|
      features[k] = v
    end

    features.delete('quiz_stats')

    Feature.instance_variable_set(:@features, features)
  end
end

