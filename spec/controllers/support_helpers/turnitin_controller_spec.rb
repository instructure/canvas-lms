require 'spec_helper'

describe SupportHelpers::TurnitinController do
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

    context 'md5' do
      it "should create a new MD5Fixer" do
        fixer(SupportHelpers::Tii::MD5Fixer)
        get :md5
        expect(response.body).to eq("Enqueued TurnItIn MD5Fixer ##{@fixer.job_id}...")
      end
    end

    context 'error2305' do
      it "should create a new Error2305Fixer" do
        fixer(SupportHelpers::Tii::Error2305Fixer)
        get :error2305
        expect(response.body).to eq("Enqueued TurnItIn Error2305Fixer ##{@fixer.job_id}...")
      end
    end

    context 'shard' do
      it "should create a new ShardFixer" do
        fixer(SupportHelpers::Tii::ShardFixer)
        get :shard
        expect(response.body).to eq("Enqueued TurnItIn ShardFixer ##{@fixer.job_id}...")
      end

      it "should create a new ShardFixer with after_time" do
        fixer = SupportHelpers::Tii::ShardFixer.new(@user.email, '2016-05-01')
        SupportHelpers::Tii::ShardFixer.expects(:new).
          with(@user.email, Time.zone.parse('2016-05-01')).returns(fixer)
        fixer.expects(:monitor_and_fix)
        get :shard, after_time: '2016-05-01'
        expect(response.body).to eq("Enqueued TurnItIn ShardFixer ##{fixer.job_id}...")
      end
    end

    context 'assignment' do
      it "should create a new AssignmentFixer with id" do
        assignment_model
        fixer = SupportHelpers::Tii::AssignmentFixer.new(@user.email, nil, @assignment.id)
        SupportHelpers::Tii::AssignmentFixer.expects(:new).with(@user.email, nil, @assignment.id).returns(fixer)
        fixer.expects(:monitor_and_fix)
        get :assignment, id: @assignment.id
        expect(response.body).to eq("Enqueued TurnItIn AssignmentFixer ##{fixer.job_id}...")
      end

      it "should return 400 status without id" do
        SupportHelpers::Tii::AssignmentFixer.expects(:new).never
        get :assignment
        expect(response.body).to eq('Missing assignment `id` parameter')
        assert_status(400)
      end
    end

    context 'pending' do
      it "should create a new StuckInPendingFixer" do
        fixer(SupportHelpers::Tii::StuckInPendingFixer)
        get :pending
        expect(response.body).to eq("Enqueued TurnItIn StuckInPendingFixer ##{@fixer.job_id}...")
      end
    end

    context 'expired' do
      it "should create a new ExpiredAccountFixer" do
        fixer(SupportHelpers::Tii::ExpiredAccountFixer)
        get :expired
        expect(response.body).to eq("Enqueued TurnItIn ExpiredAccountFixer ##{@fixer.job_id}...")
      end
    end
  end

  def fixer(klass)
    @fixer = klass.new(@user.email)
    klass.expects(:new).with(@user.email, nil).returns(@fixer)
    @fixer.expects(:monitor_and_fix)
    @fixer
  end
end
