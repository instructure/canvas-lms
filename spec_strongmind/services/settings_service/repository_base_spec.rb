require_relative '../../rails_helper'

RSpec.describe SettingsService::RepositoryBase do
  subject {
    described_class.instance
  }

  context '#dynamodb' do
    it 'is an instance method not a class method' do
      allow(Aws::DynamoDB::Client).to receive(:new).and_return(instance_double(Aws::DynamoDB::Client))

      expect {
        subject.dynamodb
      }.to_not raise_error

      expect {
        SettingsService::RepositoryBase.dynamodb
      }.to raise_error(NoMethodError)
    end
  end
end
