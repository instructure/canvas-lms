require_relative '../../rails_helper'

RSpec.describe SettingsService::AuthToken do
  let(:role)  { 'root_admin' }
  let(:user)  { double('User', user_roles: [role]) }
  let(:token) { double('Token', user: user) }

  before do
    allow(SettingsService::AuthenticatorStub).to receive(:authenticate).and_return(token)
    allow(Account).to receive(:site_admin)
  end

  subject {
    described_class
  }

  it do
    skip 'todo: fix for running under LMS'
    expect(subject.authenticate('fdafdfdsfd')).to eq true
  end
end
