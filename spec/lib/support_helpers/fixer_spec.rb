require_relative '../../spec_helper'

describe SupportHelpers::Fixer do

  describe "#job_id" do
    it 'generates a unique id' do
      fixer1 = SupportHelpers::Fixer.new('email')
      fixer2 = SupportHelpers::Fixer.new('email')
      expect(fixer1.job_id).not_to eq(fixer2.job_id)
    end
  end

  describe '#fixer_name' do
    it 'returns the fixer class name and job id' do
      fixer = SupportHelpers::Fixer.new('email')
      expect(fixer.fixer_name).to eq "Fixer ##{fixer.job_id}"
    end
  end

  describe '#monitor_and_fix' do
    it 'emails the caller upon success' do
      fixer = SupportHelpers::Fixer.new('email')
      Message.expects(:new).with do |actual|
        actual.slice(:to, :from, :subject, :delay_for) == {
          to: 'email',
          from: 'supporthelperscript@instructure.com',
          subject: 'Fixer Success',
          delay_for: 0
        } && actual[:body] =~ /done in \d+ seconds!/
      end
      fixer.expects(:fix).returns(nil)
      Mailer.expects(:create_message)
      fixer.monitor_and_fix
    end

    it 'emails the caller upon error' do
      fixer = SupportHelpers::Fixer.new('email')
      Message.expects(:new)
      Mailer.expects(:create_message)
      begin
        fixer.monitor_and_fix
      rescue => error
        expect(error.message).to eq 'SupportHelpers::Fixer must implement #fix'
      end
    end
  end
end
