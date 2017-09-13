#
# Copyright (C) 2017 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Lti::Errors::ErrorLogger do
  describe '#log_error' do
    let(:message) { 'An error message!' }
    let(:error) { StandardError.new(message) }

    before do
      allow(error).to receive(:backtrace) { ['afile.rb line 23', 'another_file.rb line 33'] }
    end

    it 'creates a new error report' do
      expect { Lti::Errors::ErrorLogger.log_error(error) }.to change { ErrorReport.count }.from(0).to(1)
    end

    it 'sets the error report message to the message of the error' do
      Lti::Errors::ErrorLogger.log_error(error)
      expect(ErrorReport.last.message).to eq message
    end

    it 'includes the backtrace in the exception message' do
      Lti::Errors::ErrorLogger.log_error(error)
      expect(ErrorReport.last.data['exception_message']).to eq message + "\n\n#{error.backtrace.join("\n")}"
    end
  end
end