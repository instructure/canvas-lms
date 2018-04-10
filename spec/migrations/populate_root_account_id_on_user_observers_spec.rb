require_relative '../sharding_spec_helper'

describe DataFixup::PopulateRootAccountIdOnUserObservers do
  before :once do
    course_with_student(:active_all => true)
    @observer = user_with_pseudonym(:active_all => true)
    @link = UserObservationLink.create!(:student => @student, :observer => @observer)
  end

  it "should populate the root account id" do
    described_class.run
    expect(@link.reload.root_account).to eq Account.default
    expect(UserObservationLink.where(:student => @student, :observer => @observer).count).to eq 1
  end

  it "should handle a uniqueness error when updating the root account id" do
    other_link = UserObservationLink.create!(:student => @student, :observer => @observer, :root_account => Account.default)
    described_class.run
    expect(@link.reload.workflow_state).to eq 'deleted'
    expect(@link.root_account_id).to eq UserObservationLink::MISSING_ROOT_ACCOUNT_ID
  end

  it "should destroy the link and populate a dummy id if it can't find a valid root account for observer" do
    @observer.destroy!
    described_class.run
    expect(@link.reload.workflow_state).to eq 'deleted'
    expect(@link.root_account_id).to eq UserObservationLink::MISSING_ROOT_ACCOUNT_ID
  end

  it "should destroy the link and populate a dummy id if it can't find a valid root account for student" do
    @student.destroy!
    described_class.run
    expect(@link.reload.workflow_state).to eq 'deleted'
    expect(@link.root_account_id).to eq UserObservationLink::MISSING_ROOT_ACCOUNT_ID
  end

  it "should create an additional link if there are multiple shared root accounts" do
    new_account = Account.create!
    pseudonym(@student, :account => new_account)
    pseudonym(@observer, :account => new_account)
    described_class.run
    ra_ids = UserObservationLink.where(:student => @student, :observer => @observer).pluck(:root_account_id)
    expect(ra_ids).to match_array([Account.default.id, new_account.id])
  end

  it "should handle a uniqueness error creating an additional link" do
    new_account = Account.create!
    pseudonym(@student, :account => new_account)
    pseudonym(@observer, :account => new_account)
    UserObservationLink.create!(:student => @student, :observer => @observer, :root_account => new_account)
    described_class.run
    ra_ids = UserObservationLink.active.where(:student => @student, :observer => @observer).pluck(:root_account_id)
    expect(ra_ids).to match_array([Account.default.id, new_account.id])
  end

  context "sharding" do
    specs_require_sharding

    before :once do
      @shard1.activate do
        @cs_account = Account.create!
        @cs_observer = user_with_pseudonym(:active_all => true, :account => @cs_account)
        @cs_link_shadow = UserObservationLink.create!(:student => @student, :observer => @cs_observer)
      end
      pseudonym(@cs_observer, :account => Account.default)
      @cs_link = UserObservationLink.create!(:student => @student, :observer => @cs_observer)
    end

    it "should not affect shadow records when run on their shard" do
      @shard1.activate do
        described_class.run
      end
      expect(@cs_link_shadow.reload.root_account_id).to be_nil
    end

    it "should update shadow records when run for primary record's shard" do
      described_class.run
      expect(@cs_link.reload.root_account).to eq Account.default
      expect(@cs_link_shadow.reload.root_account).to eq Account.default
    end

    it "should still add a link for shared cross shard accounts" do
      pseudonym(@student, :account => @cs_account)
      described_class.run
      expect(UserObservationLink.where(:student => @student, :observer => @cs_observer, :root_account_id => @cs_account.id).exists?).to be_truthy
    end
  end
end
