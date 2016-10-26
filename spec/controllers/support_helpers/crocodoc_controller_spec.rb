require 'spec_helper'

describe SupportHelpers::CrocodocController do
  describe 'require_site_admin' do
    it 'should redirect to root url if current user is not a site admin' do
      account_admin_user
      user_session(@user)
      get :shard
      assert_unauthorized
    end

    it 'should redirect to login if current user is not logged in' do
      get :shard
      assert_unauthorized
    end

    it 'should render 200 if current user is a site admin' do
      site_admin_user
      user_session(@user)
      get :shard
      assert_status(200)
    end
  end

  describe 'helper action' do
    before do
      site_admin_user
      user_session(@user)
    end

    context 'shard' do
      it "should create a new ShardFixer" do
        fixer = SupportHelpers::Crocodoc::ShardFixer.new(@user.email)
        SupportHelpers::Crocodoc::ShardFixer.expects(:new).with(@user.email, nil).returns(fixer)
        fixer.expects(:monitor_and_fix)
        get :shard
        expect(response.body).to eq("Enqueued Crocodoc ShardFixer ##{fixer.job_id}...")
      end

      it "should create a new ShardFixer with after_time" do
        fixer = SupportHelpers::Crocodoc::ShardFixer.new(@user.email, '2016-05-01')
        SupportHelpers::Crocodoc::ShardFixer.expects(:new).
          with(@user.email, Time.zone.parse('2016-05-01')).returns(fixer)
        fixer.expects(:monitor_and_fix)
        get :shard, after_time: '2016-05-01'
        expect(response.body).to eq("Enqueued Crocodoc ShardFixer ##{fixer.job_id}...")
      end
    end

    context 'submission' do
      it "should create a new SubmissionFixer" do
        fixer = SupportHelpers::Crocodoc::SubmissionFixer.new(@user.email, nil, 1234, 5678)
        SupportHelpers::Crocodoc::SubmissionFixer.expects(:new).
          with(@user.email, nil, 1234, 5678).returns(fixer)
        fixer.expects(:monitor_and_fix)
        get :submission, assignment_id: 1234, user_id: 5678
        expect(response.body).to eq("Enqueued Crocodoc SubmissionFixer ##{fixer.job_id}...")
      end
    end
  end
end
