# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MicrosoftSync::Errors do
  describe '.user_facing_message' do
    context 'with a PublicError' do
      class MicrosoftSync::Errors::TestError < MicrosoftSync::Errors::PublicError
        def public_message
          'the public message'
        end
      end

      it 'shows the error class name and the public_message' do
        error = MicrosoftSync::Errors::TestError.new("abc")
        expect(described_class.user_facing_message(error)).to \
          eq("Microsoft Sync Errors Test Error: the public message")
      end
    end

    context 'with a non-PublicError error' do
      it 'shows only the error class name' do
        expect(described_class.user_facing_message(StandardError.new('foo'))).to \
          eq("Standard Error")
      end
    end
  end

  describe described_class::InvalidStatusCode do
    subject do
      described_class.new(
        service: 'my api', response: double(code: 404, body: body), tenant: 'mytenant'
      )
    end

    let(:body) { 'abc' }

    it 'gives a public message with the service name, status code, and tenant' do
      expect(subject.public_message).to eq('My api service returned 404 for tenant mytenant')
    end

    it 'gives an internal message with the public message plus full response body' do
      expect(subject.message).to eq('My api service returned 404 for tenant mytenant, full body: "abc"')
    end

    context 'when the body is very long' do
      let(:body) { 'abc' * 1000 }

      it 'is truncated' do
        expect(subject.message.length).to be_between(1000, 1300)
        expect(subject.message).to include('abc' * 250)
      end
    end

    context 'when body is nil' do
      let(:body) { nil }

      it 'gives a message showing a nil body' do
        expect(subject.message).to \
          eq('My api service returned 404 for tenant mytenant, full body: nil')
      end
    end
  end
end
