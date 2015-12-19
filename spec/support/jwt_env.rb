RSpec.shared_context "JWT setup" do
  let(:signing_secret){ "asdfasdfasdfasdfasdfasdfasdfasdf" }
  let(:encryption_secret){ "jkl;jkl;jkl;jkl;jkl;jkl;jkl;jkl;" }

  before do
    @preexisting_signing_secret = ENV['ECOSYSTEM_SECRET']
    @preexisting_encryption_secret = ENV['ECOSYSTEM_KEY']
    ENV['ECOSYSTEM_SECRET'] = signing_secret
    ENV['ECOSYSTEM_KEY'] = encryption_secret
  end

  after do
    ENV['ECOSYSTEM_SECRET'] = @preexisting_signing_secret
    ENV['ECOSYSTEM_KEY'] = @preexisting_encryption_secret
    Timecop.return
  end

  around do |example|
    Timecop.freeze(Time.utc(2013,3,13,9,12), &example)
  end
end
