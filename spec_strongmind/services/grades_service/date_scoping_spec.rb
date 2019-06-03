require_relative '../../rails_helper'

RSpec.describe GradesService do
  before do
    allow(GradesService).to receive(:save_audit)
    allow(SettingsService).to receive(:get_settings).and_return('zero_out_start_date' => nil)
  end

  it 'should not scope by date' do
    expect(GradesService.submissions.to_sql).to_not include('courses.start_at >=')
  end

  context 'zero out should only run after a certain day' do
    before do
      allow(SettingsService).to receive(:get_settings).and_return('zero_out_start_date' => Date.parse('12/1/2018'))
    end

    it 'should scope by date' do
      expect(GradesService.submissions.to_sql).to include("courses.start_at >= '2018-01-12'")
    end
  end
end
