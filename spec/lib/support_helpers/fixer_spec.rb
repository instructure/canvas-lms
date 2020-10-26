# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
      expect(Message).to receive(:new) do |actual|
        actual.slice(:to, :from, :subject, :delay_for) == {
          to: 'email',
          from: 'supporthelperscript@instructure.com',
          subject: 'Fixer Success',
          delay_for: 0
        } && actual[:body] =~ /done in \d+ seconds!/
      end
      expect(fixer).to receive(:fix).and_return(nil)
      expect(Mailer).to receive(:create_message)
      fixer.monitor_and_fix
    end

    it 'emails the caller upon error' do
      fixer = SupportHelpers::Fixer.new('email')
      expect(Message).to receive(:new)
      expect(Mailer).to receive(:create_message)
      begin
        fixer.monitor_and_fix
      rescue => error
        expect(error.message).to eq 'SupportHelpers::Fixer must implement #fix'
      end
    end
  end
end
