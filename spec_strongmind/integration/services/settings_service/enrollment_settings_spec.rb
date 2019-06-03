require_relative '../../../rails_helper'

# Not used, was at a time thought to boot/stub docker dynamo db instance in tests
RSpec.xdescribe 'Save an enrollment setting', dynamo_db: true do
  let(:enrollment) { SettingsService::Enrollment.new }

  before do
    ENV['CANVAS_DOMAIN'] = 'integration.example.com'
    ENV['AWS_SECRET_ACCESS_KEY'] = 'SecretKey'
    ENV['AWS_ACCESS_KEY_ID'] = 'SecretKeyID'
  end

  it 'creates a table' do
    expect(SettingsService::Enrollment.create_table).to eq true
  end

  it 'creates and reads items' do
    SettingsService::Enrollment.create_table
    SettingsService::Enrollment.put(id: 1, setting: 'foo', value: 'bar')
    SettingsService::Enrollment.put(id: 1, setting: 'foo2', value: 'bar2')

    expect( SettingsService::Enrollment.get(id: 1) ).to be == {
      "foo" => 'bar',
      'foo2' => 'bar2'
    }

  end
end
