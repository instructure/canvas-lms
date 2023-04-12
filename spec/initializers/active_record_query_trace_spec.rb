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

require "active_record_query_trace"
require_relative "../../config/initializers/active_record_query_trace"

describe "#configure!" do
  subject do
    ActiveRecordQueryTrace.enabled = false
    ActiveRecordQueryTrace.lines = nil
    ActiveRecordQueryTrace.query_type = nil

    ARQueryTraceInitializer.configure!
    ActiveRecordQueryTrace
  end

  before do
    allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_LINES").and_return(nil)
    allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_TYPE").and_return(nil)
    allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_LEVEL").and_return(nil)
  end

  context "when Rails ENV is test" do
    before { allow(ENV).to receive(:[]).with("AR_QUERY_TRACE").and_return("true") }

    it "enables AR query trace" do
      expect(subject.enabled).to be true
    end
  end

  context "when Rails ENV is production" do
    before do
      allow(ENV).to receive(:[]).with("AR_QUERY_TRACE").and_return("true")
      allow(Rails).to receive(:env) { "production".inquiry } # rubocop:disable Rails/Inquiry
    end

    it "does not enable AR query trace" do
      expect(subject.enabled).to be false
    end
  end

  context "when Rails ENV is development" do
    before do
      allow(Rails).to receive(:env) { "development".inquiry } # rubocop:disable Rails/Inquiry
    end

    context "and AR_QUERY_TRACE is falsy" do
      before do
        allow(ENV).to receive(:[]).with("AR_QUERY_TRACE").and_return("0")
      end

      it "disables AR query trace" do
        expect(subject.enabled).to be false
      end
    end

    context "and AR_QUERY_TRACE is set" do
      before do
        allow(ENV).to receive(:[]).with("AR_QUERY_TRACE").and_return("true")
      end

      it "enables AR query trace" do
        expect(subject.enabled).to be true
      end

      it 'defaults "lines" to 10' do
        expect(subject.lines).to eq 10
      end

      it 'defaults "query_type" to :all' do
        expect(subject.query_type).to eq :all
      end

      context "and AR_QUERY_TRACE_LINES is set" do
        before do
          allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_LINES").and_return(25)
        end

        it 'sets "lines" to the provided value' do
          expect(subject.lines).to eq 25
        end
      end

      context "and AR_QUERY_TRACE_TYPE is set" do
        before do
          allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_TYPE").and_return("read")
        end

        it 'sets "query_type" to the provided value' do
          expect(subject.query_type).to eq :read
        end

        context "and AR_QUERY_TRACE_TYPE is an invalid value" do
          before do
            allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_TYPE").and_return("banana")
          end

          it 'sets "query_type" to :all' do
            expect(subject.query_type).to eq :all
          end
        end
      end

      context "and AR_QUERY_TRACE_LEVEL is set" do
        before do
          allow(ENV).to receive(:[]).with("AR_QUERY_TRACE_LEVEL").and_return("full")
        end

        it 'sets "level" to the provided value' do
          expect(subject.level).to eq :full
        end
      end
    end
  end
end
