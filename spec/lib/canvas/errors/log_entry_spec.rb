# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Canvas
  class Errors
    describe LogEntry do
      let(:data) { { tags: { foo: "bar" } } }

      describe "with an exception" do
        before do
          @raised_error = nil
          raise ArgumentError, "Test Message"
        rescue ArgumentError => e
          @raised_error = e
          @entry = LogEntry.new(e, data)
        end

        describe "#message" do
          let(:message) { @entry.message }

          it "includes an easily greppable tag" do
            expect(message).to include("[CANVAS_ERRORS]")
          end

          it "contains the class and error message" do
            expect(message).to include("ArgumentError")
            expect(message).to include("Test Message")
          end

          it "has the backtrace" do
            expect(message).to include("log_entry_spec.rb")
          end

          it "splats the data context" do
            expect(message).to include("tags")
            expect(message).to include("foo")
            expect(message).to include("bar")
          end
        end

        describe ".write" do
          it "uses the error level to choose logger method" do
            expect(Rails.logger).to receive(:warn)
            LogEntry.write(@raised_error, data, :warn)
          end

          it "defaults to error" do
            expect(Rails.logger).to receive(:error)
            LogEntry.write(@raised_error, data)
          end
        end
      end

      describe "a nested exception" do
        before do
          @raised_error = nil
          begin
            begin
              raise "FOO"
            rescue RuntimeError
              raise ArgumentError, "Test Message"
            end
          rescue ArgumentError
            raise StandardError, "TopException"
          end
        rescue => e
          @raised_error = e
          @entry = LogEntry.new(e, data)
        end

        describe "#message" do
          let(:message) { @entry.message }

          it "includes an easily greppable tag" do
            expect(message).to include("[CANVAS_ERRORS]")
          end

          it "contains all the errors" do
            expect(message).to include("RuntimeError")
            expect(message).to include("ArgumentError")
            expect(message).to include("StandardError")
          end

          it "has breaks between exception levels" do
            expect(message).to include("****Caused By****")
          end

          it "splats the data context" do
            expect(message).to include("tags")
            expect(message).to include("foo")
            expect(message).to include("bar")
          end
        end
      end

      describe "capturing a message without exception" do
        it "just reports the string, no backtrace" do
          entry = LogEntry.new("some logging message", data)
          msg = entry.message
          expect(msg).to include("[CANVAS_ERRORS]")
          expect(msg).to_not include("String")
          expect(msg).to include("tags")
          expect(msg).to include("foo")
          expect(msg).to include("bar")
        end
      end
    end
  end
end
