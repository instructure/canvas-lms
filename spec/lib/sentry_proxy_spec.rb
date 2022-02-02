# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe SentryProxy do
  let(:data) { { a: "b", c: "d" } }
  let(:error_klass) { Class.new(StandardError) }

  before { SentryProxy.clear_ignorable_errors }

  describe ".capture" do
    it "forwards exceptions on to sentry" do
      e = error_klass.new
      expect(Sentry).to receive(:capture_exception).with(e, data)
      SentryProxy.capture(e, data)
    end

    it "passes messages to the capture_message sentry method" do
      e = "Some Message"
      expect(Sentry).to receive(:capture_message).with(e, data)
      SentryProxy.capture(e, data)
    end

    it "changes symbols to strings because sentry chokes otherwise" do
      e = :some_exception_type
      expect(Sentry).to receive(:capture_message).with("some_exception_type", data)
      SentryProxy.capture(e, data)
    end

    it "does not send the message if configured as ignorable" do
      SentryProxy.register_ignorable_error(error_klass)
      e = error_klass.new
      expect(Sentry).to_not receive(:capture_exception)
      SentryProxy.capture(e, data)
    end

    it "does not send to sentry for low-level errors" do
      e = error_klass.new
      expect(Sentry).not_to receive(:capture_exception)
      SentryProxy.capture(e, data, :warn)
    end
  end

  describe ".register_ignorable_error" do
    it "keeps track of errors we don't care about reporting" do
      SentryProxy.register_ignorable_error(error_klass)
      expect(SentryProxy.ignorable_errors).to include(error_klass.to_s)
    end

    it "prevents the same error from being registered many times" do
      start_count = SentryProxy.ignorable_errors.size
      10.times { SentryProxy.register_ignorable_error(error_klass) }
      expect(SentryProxy.ignorable_errors.size).to eq(start_count + 1)
    end

    it "registers strings to skip capture_message" do
      e = "Some Message"
      SentryProxy.register_ignorable_error(e)
      expect(Sentry).to_not receive(:capture_message)
      SentryProxy.capture(e, data)
    end
  end
end
