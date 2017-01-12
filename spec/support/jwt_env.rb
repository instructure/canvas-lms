RSpec.shared_context "JWT setup" do
  let(:fake_signing_secret){ "asdfasdfasdfasdfasdfasdfasdfasdf" }
  let(:fake_encryption_secret){ "jkl;jkl;jkl;jkl;jkl;jkl;jkl;jkl;" }
  let(:fake_secrets){
    {
      "signing-secret" => fake_signing_secret,
      "encryption-secret" => fake_encryption_secret
    }
  }

  before do
    Canvas::DynamicSettings.stubs(:find).with("canvas").returns(fake_secrets)
  end

  after do
    Canvas::DynamicSettings.unstub(:find)
    Timecop.return
  end

  around do |example|
    Timecop.freeze(Time.utc(2013,3,13,9,12), &example)
  end
end
