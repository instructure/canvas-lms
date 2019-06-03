require_relative '../rails_helper'

RSpec.describe SettingsService, skip: 'todo: fix for running under LMS' do
  subject { described_class }

  describe '#get_settings' do
  end

  describe '#update_settings' do
    it 'calls the update setting command' do
      expect(
        SettingsService::Commands::UpdateSettings
      ).to receive(:new).with(
        id: 1,
        setting: "foo",
        value: "bar",
        object: 'assignment'
      ).and_return(double('command', call: nil))

      described_class.update_settings(
        id: 1,
        setting: 'foo',
        value: 'bar',
        object: 'assignment'
      )
    end
  end

  describe '#get_enrollment_settings' do
    it 'calls the update setting command' do
      expect(
        SettingsService::Commands::GetEnrollmentSettings
      ).to receive(:new).with(
        id: 1
      ).and_return(double('command', call: nil))

      described_class.get_enrollment_settings(id: 1)
    end
  end

  describe '#update_enrollment_setting' do
    it 'calls the get settings command' do
      expect(
        SettingsService::Commands::UpdateEnrollmentSetting
      ).to receive(:new).with(
        id: 1,
        setting: "foo",
        value: "bar"
      ).and_return(double('command', call: nil))

      described_class.update_enrollment_setting(
        id: 1,
        setting: 'foo',
        value: 'bar'
      )
    end
  end

  describe '#get_user_settings' do
    it 'calls the update setting command' do
      expect(
        SettingsService::Commands::GetUserSettings
      ).to receive(:new).with(
        id: 1
      ).and_return(double('command', call: nil))

      described_class.get_user_settings(id: 1)
    end
  end

  describe '#update_user_setting' do
    it 'calls the get settings command' do
      expect(
        SettingsService::Commands::UpdateUserSetting
      ).to receive(:new).with(
        id: 1,
        setting: "foo",
        value: "bar"
      ).and_return(double('command', call: nil))

      described_class.update_user_setting(
        id: 1,
        setting: 'foo',
        value: 'bar'
      )
    end
  end

  describe '#query' do
    it 'calls the query' do
      expect(SettingsService::Queries::ZeroGraderAudit).to receive(:run)
      described_class.query
    end
  end

end
