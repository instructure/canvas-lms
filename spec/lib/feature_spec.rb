#
# Copyright (C) 2013 Instructure, Inc.
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

describe Feature do
  let(:t_site_admin) { Account.site_admin }
  let(:t_root_account) { account_model }
  let(:t_sub_account) { account_model parent_account: t_root_account }
  let(:t_course) { course account: t_sub_account, active_all: true }
  let(:t_user) { user_with_pseudonym account: t_root_account }

  before do
    Feature.stubs(:definitions).returns({
        'RA' => Feature.new(feature: 'RA', applies_to: 'RootAccount', state: 'hidden'),
        'A' => Feature.new(feature: 'A', applies_to: 'Account', state: 'on'),
        'C' => Feature.new(feature: 'C', applies_to: 'Course', state: 'off'),
        'U' => Feature.new(feature: 'U', applies_to: 'User', state: 'allowed'),
    })
  end

  describe "applies_to_object" do
    it "should work for RootAccount features" do
      feature = Feature.definitions['RA']
      feature.applies_to_object(t_root_account).should be_true
      feature.applies_to_object(t_sub_account).should be_false
      feature.applies_to_object(t_course).should be_false
      feature.applies_to_object(t_user).should be_false
    end

    it "should work for Account features" do
      feature = Feature.definitions['A']
      feature.applies_to_object(t_root_account).should be_true
      feature.applies_to_object(t_sub_account).should be_true
      feature.applies_to_object(t_course).should be_false
      feature.applies_to_object(t_user).should be_false
    end

    it "should work for Course features" do
      feature = Feature.definitions['C']
      feature.applies_to_object(t_root_account).should be_true
      feature.applies_to_object(t_sub_account).should be_true
      feature.applies_to_object(t_course).should be_true
      feature.applies_to_object(t_user).should be_false
    end

    it "should work for User features" do
      feature = Feature.definitions['U']
      feature.applies_to_object(t_site_admin).should be_true
      feature.applies_to_object(t_root_account).should be_false
      feature.applies_to_object(t_sub_account).should be_false
      feature.applies_to_object(t_course).should be_false
      feature.applies_to_object(t_user).should be_true
    end
  end

  describe "applicable_features" do
    it "should work for Site Admin" do
      Feature.applicable_features(t_site_admin).map(&:feature).sort.should eql %w(A C RA U)
    end

    it "should work for RootAccounts" do
      Feature.applicable_features(t_root_account).map(&:feature).sort.should eql %w(A C RA)
    end

    it "should work for Accounts" do
      Feature.applicable_features(t_sub_account).map(&:feature).sort.should eql %w(A C)
    end

    it "should work for Courses" do
      Feature.applicable_features(t_course).map(&:feature).should eql %w(C)
    end

    it "should work for Users" do
      Feature.applicable_features(t_user).map(&:feature).should eql %w(U)
    end
  end

  describe "locked?" do
    it "should return true if context is nil" do
      Feature.definitions['RA'].locked?(nil).should be_true
      Feature.definitions['A'].locked?(nil).should be_true
      Feature.definitions['C'].locked?(nil).should be_true
      Feature.definitions['U'].locked?(nil).should be_true
    end

    it "should return true in a lower context if the definition disallows override" do
      Feature.definitions['RA'].locked?(t_site_admin).should be_false
      Feature.definitions['A'].locked?(t_site_admin).should be_true
      Feature.definitions['C'].locked?(t_site_admin).should be_true
      Feature.definitions['U'].locked?(t_site_admin).should be_false
    end
  end

  describe "RootAccount feature" do
    it "should imply root_opt_in" do
      Feature.definitions['RA'].root_opt_in.should be_true
    end
  end

  describe "default_transitions" do
    it "should enumerate RootAccount transitions" do
      fd = Feature.definitions['RA']
      fd.default_transitions(t_site_admin, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_site_admin, 'on').should eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      fd.default_transitions(t_site_admin, 'off').should eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_root_account, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_root_account, 'on').should eql({'allowed'=>{'locked'=>true},'off'=>{'locked'=>false}})
      fd.default_transitions(t_root_account, 'off').should eql({'allowed'=>{'locked'=>true},'on'=>{'locked'=>false}})
    end

    it "should enumerate Account transitions" do
      fd = Feature.definitions['A']
      fd.default_transitions(t_root_account, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_root_account, 'on').should eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      fd.default_transitions(t_root_account, 'off').should eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_sub_account, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_sub_account, 'on').should eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      fd.default_transitions(t_sub_account, 'off').should eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
    end

    it "should enumerate Course transitions" do
      fd = Feature.definitions['C']
      fd.default_transitions(t_course, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_course, 'on').should eql({'off'=>{'locked'=>false}})
      fd.default_transitions(t_course, 'off').should eql({'on'=>{'locked'=>false}})
    end

    it "should enumerate User transitions" do
      fd = Feature.definitions['U']
      fd.default_transitions(t_user, 'allowed').should eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      fd.default_transitions(t_user, 'on').should eql({'off'=>{'locked'=>false}})
      fd.default_transitions(t_user, 'off').should eql({'on'=>{'locked'=>false}})
    end
  end

end
