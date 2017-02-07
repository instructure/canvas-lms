require_relative "../sharding_spec_helper"

describe SisPseudonym do
  let_once(:course1) { course_factory active_all: true, account: Account.default }
  let_once(:course2) { course_factory active_all: true, account: account2 }
  let_once(:account1) { account_model }
  let_once(:account2) { account_model }
  let_once(:u) { User.create! }

  def pseud_params(unique_id, account = Account.default)
    {
      account: account,
      unique_id: unique_id,
      password: "asdfasdf",
      password_confirmation: "asdfasdf"
    }
  end

  context "when there is a deleted pseudonym" do
    before do
      u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
        x.workflow_state = 'deleted'
        x.sis_user_id = "user2"
      end
    end

    it "should return active pseudonyms only" do
      expect(SisPseudonym.for(u, course1)).to be_nil
      active_pseudonym = u.pseudonyms.create!(pseud_params("user1@example.com")) do |x|
        x.workflow_state = 'active'
        x.sis_user_id = "user1"
      end
      expect(SisPseudonym.for(u, course1)).to eq(active_pseudonym)
    end

    it "returns only active pseudonyms when loading from user collection too" do
      u.pseudonyms # make sure user collection is loaded
      expect(SisPseudonym.for(u, course1)).to be_nil
    end
  end

  it "should return pseudonyms in the right account" do
    other_account = account_model
    u.pseudonyms.create!(pseud_params("user1@example.com", other_account)) do |x|
      x.workflow_state = 'active'
      x.sis_user_id = "user1"
    end
    expect(SisPseudonym.for(u, course1)).to be_nil
    @p = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
      x.workflow_state = 'active'
      x.sis_user_id = "user2"
    end
    expect(SisPseudonym.for(u, course1)).to eq @p
  end

  it "should return pseudonyms with a sis id only" do
    u.pseudonyms.create!(pseud_params("user1@example.com")) do |x|
      x.workflow_state = 'active'
    end
    expect(SisPseudonym.for(u, course1)).to be_nil
    @p = u.pseudonyms.create!(pseud_params("user2@example.com")) do |x|
      x.workflow_state = 'active'
      x.sis_user_id = "user2"
    end
    expect(SisPseudonym.for(u, course1)).to eq @p
  end

  it "should find the right root account for a course" do
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: 'user') do |p|
      p.sis_user_id = 'abc'
    end
    expect(SisPseudonym.for(u, course2)).to eq(pseudonym)
  end

  it "should find the right root account for a group" do
    @group = group :group_context => course2
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: 'user') { |p| p.sis_user_id = 'abc'}
    expect(SisPseudonym.for(u, @group)).to eq(pseudonym)
  end

  it "should find the right root account for a non-root-account" do
    @root_account = account1
    @account = @root_account.sub_accounts.create!
    pseudonym = @root_account.pseudonyms.create!(user: u, unique_id: 'user') { |p| p.sis_user_id = 'abc'}
    expect(SisPseudonym.for(u, @account)).to eq(pseudonym)
  end

  it "should find the right root account for a root account" do
    pseudonym = account1.pseudonyms.create!(user: u, unique_id: 'user') { |p| p.sis_user_id = 'abc'}
    expect(SisPseudonym.for(u, account1)).to eq(pseudonym)
  end

  it "should bail if it can't find a root account" do
    context = Course.new # some context that doesn't have an account
    expect { SisPseudonym.for(u, context) }.to raise_error("could not resolve root account")
  end

  it "should include a pseudonym from a trusted account" do
    pseudonym = account2.pseudonyms.create!(user: u, unique_id: 'user') { |p| p.sis_user_id = 'abc' }
    account1.stubs(:trust_exists?).returns(true)
    account1.stubs(:trusted_account_ids).returns([account2.id])
    expect(SisPseudonym.for(u, account1)).to be_nil
    expect(SisPseudonym.for(u, account1, true)).to eq(pseudonym)
  end

  context "with multiple acceptable sis pseudonyms" do
    before(:each) do
      u.pseudonyms.create!(pseud_params("user2@example.com")) do |p|
        p.workflow_state = 'active'
        p.sis_user_id = "SIS1"
      end
      u.pseudonyms.create!(pseud_params("alphabet@example.com")) do |p|
        p.workflow_state = 'active'
        p.sis_user_id = "SIS2"
      end
      u.pseudonyms.create!(pseud_params("zebra@example.com")) do |p|
        p.workflow_state = 'active'
        p.sis_user_id = "SIS3"
      end
      u.reload # to clear psuedonyms collection for sure
    end

    it "finds the alphabetically first pseudonym when the pseudonyms aren't loaded" do
      found_pseudonym = SisPseudonym.for(u, Account.default)
      expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
    end

    it "uses the sames pseudonym when the pseudonyms have been loaded" do
      u.pseudonyms # to get pseudonyms collection pre-loaded
      found_pseudonym = SisPseudonym.for(u, Account.default)
      expect(found_pseudonym.unique_id).to eq("alphabet@example.com")
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should find a pseudonym on a different shard" do
      @shard1.activate do
        @user = User.create!
      end
      @pseudonym = Account.default.pseudonyms.create!(user: @user, unique_id: 'user') do |p|
        p.sis_user_id = 'abc'
      end
      @shard2.activate do
        expect(SisPseudonym.for(@user, Account.default)).to eq @pseudonym
      end
      @shard1.activate do
        expect(SisPseudonym.for(@user, Account.default)).to eq @pseudonym
      end
    end
  end

end
