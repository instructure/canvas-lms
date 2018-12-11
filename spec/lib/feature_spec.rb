#
# Copyright (C) 2013 - present Instructure, Inc.
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
  let(:t_course) { course_factory account: t_sub_account, active_all: true }
  let(:t_user) { user_with_pseudonym account: t_root_account }

  before do
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(Feature).to receive(:definitions).and_return({
        'RA' => Feature.new(feature: 'RA', applies_to: 'RootAccount', state: 'hidden'),
        'A' => Feature.new(feature: 'A', applies_to: 'Account', state: 'on'),
        'C' => Feature.new(feature: 'C', applies_to: 'Course', state: 'off'),
        'U' => Feature.new(feature: 'U', applies_to: 'User', state: 'allowed'),
    })
  end

  describe "applies_to_object" do
    it "should work for RootAccount features" do
      feature = Feature.definitions['RA']
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for Account features" do
      feature = Feature.definitions['A']
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for Course features" do
      feature = Feature.definitions['C']
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_truthy
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for User features" do
      feature = Feature.definitions['U']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_falsey
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_truthy
    end
  end

  describe "applicable_features" do
    it "should work for Site Admin" do
      expect(Feature.applicable_features(t_site_admin).map(&:feature).sort).to eql %w(A C RA U)
    end

    it "should work for RootAccounts" do
      expect(Feature.applicable_features(t_root_account).map(&:feature).sort).to eql %w(A C RA)
    end

    it "should work for Accounts" do
      expect(Feature.applicable_features(t_sub_account).map(&:feature).sort).to eql %w(A C)
    end

    it "should work for Courses" do
      expect(Feature.applicable_features(t_course).map(&:feature)).to eql %w(C)
    end

    it "should work for Users" do
      expect(Feature.applicable_features(t_user).map(&:feature)).to eql %w(U)
    end
  end

  describe "locked?" do
    it "should return true if context is nil" do
      expect(Feature.definitions['RA'].locked?(nil)).to be_truthy
      expect(Feature.definitions['A'].locked?(nil)).to be_truthy
      expect(Feature.definitions['C'].locked?(nil)).to be_truthy
      expect(Feature.definitions['U'].locked?(nil)).to be_truthy
    end

    it "should return true in a lower context if the definition disallows override" do
      expect(Feature.definitions['RA'].locked?(t_site_admin)).to be_falsey
      expect(Feature.definitions['A'].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions['C'].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions['U'].locked?(t_site_admin)).to be_falsey
    end
  end

  describe "RootAccount feature" do
    it "should imply root_opt_in" do
      expect(Feature.definitions['RA'].root_opt_in).to be_truthy
    end
  end

  describe "default_transitions" do
    it "should enumerate RootAccount transitions" do
      fd = Feature.definitions['RA']
      expect(fd.default_transitions(t_site_admin, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'on')).to eql({'allowed'=>{'locked'=>true},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'off')).to eql({'allowed'=>{'locked'=>true},'on'=>{'locked'=>false}})
    end

    it "should enumerate Account transitions" do
      fd = Feature.definitions['A']
      expect(fd.default_transitions(t_root_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
    end

    it "should enumerate Course transitions" do
      fd = Feature.definitions['C']
      expect(fd.default_transitions(t_course, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_course, 'on')).to eql({'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_course, 'off')).to eql({'on'=>{'locked'=>false}})
    end

    it "should enumerate User transitions" do
      fd = Feature.definitions['U']
      expect(fd.default_transitions(t_user, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_user, 'on')).to eql({'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_user, 'off')).to eql({'on'=>{'locked'=>false}})
    end
  end
end

describe "Feature.register" do
  before do
    # unregister the default features
    @old_features = Feature.instance_variable_get(:@features)
    Feature.instance_variable_set(:@features, nil)
  end

  after do
    Feature.instance_variable_set(:@features, @old_features)
  end

  let(:t_feature_hash) do
    {
      display_name: -> { "some feature or other" },
      description: -> { "this does something" },
      applies_to: 'RootAccount',
      state: 'allowed'
    }
  end

  let(:t_dev_feature_hash) do
    t_feature_hash.merge(development: true)
  end

  it "should register a feature" do
    Feature.register({some_feature: t_feature_hash})
    expect(Feature.definitions).to be_frozen
    expect(Feature.definitions['some_feature'].display_name.call).to eql('some feature or other')
  end

  describe "development" do
    it "should register in a test environment" do
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should register in a dev environment" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:development?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should register in a production test cluster" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should not register in production" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).to eq Feature::DISABLED_FEATURE
    end
  end

  let(:t_hidden_in_prod_feature_hash) do
    t_feature_hash.merge(state: 'hidden_in_prod')
  end

  describe 'hidden_in_prod' do
    it "should register as 'allowed' in a test environment" do
      Feature.register({dev_feature: t_hidden_in_prod_feature_hash})
      expect(Feature.definitions['dev_feature']).to be_allowed
    end

    it "should register as 'hidden' in production" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      Feature.register({dev_feature: t_hidden_in_prod_feature_hash})
      expect(Feature.definitions['dev_feature']).to be_hidden
    end
  end
end

describe "new_gradebook" do
  let(:ngb_trans_proc) { Feature.definitions["new_gradebook"].custom_transition_proc }
  let(:root_account) { account_model }
  let(:transitions) { { "on" => {}, "allowed" => {}, "off" => {} } }
  let(:course) { course_factory(account: root_account, active_all: true) }
  let(:teacher) { teacher_in_course(course: course).user }
  let(:ta) { ta_in_course(course: course).user }
  let(:admin) { account_admin_user(account: root_account) }

  LOCKED = { "locked" => true }.freeze
  UNLOCKED = { "locked" => false }.freeze

  it "allows admins to enable the new gradebook" do
    ngb_trans_proc.call(admin, course, nil, transitions)
    expect(transitions).to include({ "on" => {}, "off" => UNLOCKED })
  end

  it "allows teachers to enable the new gradebook" do
    ngb_trans_proc.call(teacher, course, nil, transitions)
    expect(transitions).to include({ "on" => {}, "off" => UNLOCKED })
  end

  it "doesn't allow tas to enable the new gradebook" do
    ngb_trans_proc.call(ta, course, nil, transitions)
    expect(transitions).to include({ "on" => LOCKED, "off" => LOCKED })
  end

  describe "course-level backwards compatibility" do
    let(:student) { student_in_course(course: course).user }
    let!(:assignment) { course.assignments.create!(title: 'assignment', points_possible: 10) }
    let(:submission) { assignment.submissions.find_by(user: student) }

    it "blocks disabling new gradebook on a course if there are any submissions with a late_policy_status of none" do
      submission.late_policy_status = 'none'
      submission.save!

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "on" => {}, "off" => LOCKED })
    end

    it "blocks disabling new gradebook on a course if there are any submissions with a late_policy_status of missing" do
      submission.late_policy_status = 'missing'
      submission.save!

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => LOCKED })
    end

    it "blocks disabling new gradebook on a course if there are any submissions with a late_policy_status of late" do
      submission.late_policy_status = 'late'
      submission.save!

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => LOCKED })
    end

    it "allows disabling new gradebook on a course if there are no submissions with a late_policy_status" do
      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => UNLOCKED })
    end

    it "blocks disabling new gradebook on a course if a late policy is configured" do
      course.late_policy = LatePolicy.new(late_submission_deduction_enabled: true)

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => LOCKED })
    end

    it "blocks disabling new gradebook on a course if a missing policy is configured" do
      course.late_policy = LatePolicy.new(missing_submission_deduction_enabled: true)

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => LOCKED })
    end

    it "blocks disabling new gradebook on a course if both a late and missing policy is configured" do
      course.late_policy =
        LatePolicy.new(late_submission_deduction_enabled: true, missing_submission_deduction_enabled: true)

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => LOCKED })
    end

    it "allows disabling new gradebook on a course if both policies are disabled" do
      course.late_policy =
        LatePolicy.new(late_submission_deduction_enabled: false, missing_submission_deduction_enabled: false)

      ngb_trans_proc.call(admin, course, nil, transitions)
      expect(transitions).to include({ "off" => UNLOCKED })
    end
  end

  describe 'account-level backwards compatibility' do
    let(:sub_account) do
      first_level = account_model(parent_account: root_account)
      account_model(parent_account: first_level)
    end

    let(:course_at_sub_account) { course_factory(account: sub_account, active_all: true) }

    context 'when no course or sub-account has the flag enabled' do
      it 'allows disabling the flag' do
        expect(transitions['off']['locked']).to be_falsey
      end

      it 'adds no warnings' do
        expect(transitions['off']['warning']).to be_blank
      end
    end

    context 'when any course has the flag enabled' do
      before do
        course_at_sub_account.enable_feature!(:new_gradebook)

        ngb_trans_proc.call(admin, root_account, nil, transitions)
      end

      it 'blocks disabling the flag' do
        expect(transitions['off']['locked']).to be(true)
      end

      it 'adds a warning' do
        expect(transitions['off']['warning']).to be_present
      end
    end

    context 'when any sub-account has the flag enabled' do
      before do
        sub_account.enable_feature!(:new_gradebook)

        ngb_trans_proc.call(admin, root_account, nil, transitions)
      end

      it 'blocks disabling the flag' do
        expect(transitions['off']['locked']).to be(true)
      end

      it 'adds a warning' do
        expect(transitions['off']['warning']).to be_present
      end
    end
  end
end
