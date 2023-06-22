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

require_relative "../../spec_helper"
require "httparty"

# See also be_a_microsoft_sync_public_error matcher in support/microsoft_sync/errors.rb
describe MicrosoftSync::Errors do
  before do
    stub_const("MicrosoftSync::TestErrorNotPublic",
               Class.new(StandardError))

    stub_const("MicrosoftSync::TestError",
               Class.new(MicrosoftSync::Errors::PublicError) do
                 def self.public_message
                   I18n.t "oops, this is a public error"
                 end
               end)

    stub_const("MicrosoftSync::TestErrorInterpolations",
               Class.new(MicrosoftSync::Errors::PublicError) do
                 def self.public_message
                   I18n.t "An API named %{name} returned problem %{description} :("
                 end

                 def public_interpolated_values
                   { name: @name, description: @description }
                 end

                 def initialize(message, name, description)
                   super(message)
                   @name = name
                   @description = description
                 end
               end)

    stub_const("MicrosoftSync::TestErrorCountInterpolation",
               Class.new(MicrosoftSync::Errors::PublicError) do
                 def self.public_message
                   I18n.t(one: "One problem happened", other: "%{count} problems happened")
                 end

                 def public_interpolated_values
                   { count: @n_problems }
                 end

                 def initialize(message, n_problems)
                   super(message)
                   @n_problems = n_problems
                 end
               end)

    stub_const("MicrosoftSync::TestErrorBadInterpolations",
               Class.new(MicrosoftSync::Errors::PublicError) do
                 def self.public_message
                   I18n.t "Interpolation foo does not exist, see: %{foo}"
                 end

                 def public_interpolated_values
                   {}
                 end
               end)
  end

  describe ".serialize" do
    subject { JSON.parse(described_class.serialize(error)) }

    context "when the error is a non-public error" do
      let(:error) { MicrosoftSync::TestErrorNotPublic.new("abc") }

      it "returns a JSON blob with error class and message" do
        expect(subject).to eq(
          "class" => "MicrosoftSync::TestErrorNotPublic",
          "message" => "abc",
          "extra_metadata" => {}
        )
      end
    end

    context "when the error is a PublicError" do
      let(:error) { MicrosoftSync::TestErrorCountInterpolation.new("foo", 123) }

      it "returns a JSON blob with error class, message, public message, extra_metadata, and interpolations" do
        expect(subject).to eq(
          "class" => "MicrosoftSync::TestErrorCountInterpolation",
          "message" => "foo",
          "public_message" =>
            { "one" => "One problem happened", "other" => "%{count} problems happened" },
          "public_interpolated_values" => { "count" => 123 },
          "extra_metadata" => {}
        )
      end
    end
  end

  describe ".extra_metadata_from_serialized" do
    it "returns the metadata given in serialize, with symbol keys" do
      serialized = MicrosoftSync::Errors.serialize(
        StandardError.new,
        :hello => "abc",
        "foo" => 123
      )
      metadata = MicrosoftSync::Errors.extra_metadata_from_serialized(serialized)
      expect(metadata).to eq(
        hello: "abc",
        foo: 123
      )
    end
  end

  describe ".deserialize_and_localize" do
    let(:serialized) { described_class.serialize(error) }
    let(:deserialized) { described_class.deserialize_and_localize(serialized) }
    let(:t_calls_args) { [] }

    before do
      orig_t = I18n.method(:t!)
      allow(I18n).to receive(:t!) do |*args|
        # I18n.t! mutates the second arg, so can't use normal expect().to have_received,
        # duplicate & save off args like this
        t_calls_args << args.map(&:dup)
        orig_t.call(*args)
      end
    end

    context "with a serialized non-PublicError" do
      let(:error) { MicrosoftSync::TestErrorNotPublic.new("foo") }

      it "returns an I18nized generic error message" do
        expected = "Microsoft Sync has encountered an internal error."
        allow(I18n).to receive(:t).and_call_original
        expect(deserialized).to eq(expected)
        expect(I18n).to have_received(:t).with(expected)
      end
    end

    context "with a serialized PublicError with no interpolations" do
      let(:error) { MicrosoftSync::TestError.new("foo") }

      it "returns the I18nized public_message" do
        expected = "oops, this is a public error"
        expect(deserialized).to eq(expected)
        expect(t_calls_args).to include([expected, {}])
      end
    end

    context "with a serialized PublicError with interpolations" do
      let(:error) do
        MicrosoftSync::TestErrorInterpolations.new("foo", "some_api", "oh no, something happened")
      end

      it "returns the I18nized public_message with interpolated values" do
        expect(deserialized).to eq(
          "An API named some_api returned problem oh no, something happened :("
        )
      end
    end

    context 'with a serialized PublicError with "count" interpolations' do
      context "when count == 1" do
        let(:error) { MicrosoftSync::TestErrorCountInterpolation.new("foo", 1) }

        it 'returns the I18nized public_message using the "one" string' do
          expect(deserialized).to eq("One problem happened")
        end
      end

      context "when count > 1" do
        let(:error) { MicrosoftSync::TestErrorCountInterpolation.new("foo", 2) }

        it 'returns the I18nized public_message using the "multiple" string' do
          expect(deserialized).to eq("2 problems happened")
        end
      end
    end

    context "with an old (non-JSON serialized) error string" do
      it "just returns the string" do
        err_string = "Some old error string"
        expect(described_class.deserialize_and_localize(err_string)).to eq(err_string)
      end
    end
  end

  describe described_class::HTTPInvalidStatus do
    subject do
      described_class.for(
        service: "my api",
        response: double(code:, body:, headers: HTTParty::Response::Headers.new(headers)),
        tenant: "mytenant"
      )
    end

    let(:code) { 422 }
    let(:body) { "abc" }
    let(:headers) { {} }

    it "gives a public message with the service name, status code, and tenant" do
      expect(subject).to be_a_microsoft_sync_public_error(
        "Unexpected response from Microsoft API: got 422 status code"
      )
    end

    it "gives an internal message with the public message plus full response body" do
      expect(subject.message).to \
        eq('My api service returned 422 for tenant mytenant, full body: "abc"')
    end

    context "when the body is very long" do
      let(:body) { "abc" * 1000 }

      it "is truncated" do
        expect(subject.message.length).to be_between(1000, 1300)
        expect(subject.message).to include("abc" * 250)
      end
    end

    context "when body is nil" do
      let(:body) { nil }

      it "gives a message showing a nil body" do
        expect(subject.message).to \
          eq("My api service returned 422 for tenant mytenant, full body: nil")
      end
    end

    describe ".for" do
      {
        400 => MicrosoftSync::Errors::HTTPBadRequest,
        404 => MicrosoftSync::Errors::HTTPNotFound,
        409 => MicrosoftSync::Errors::HTTPConflict,
        500 => MicrosoftSync::Errors::HTTPInternalServerError,
        502 => MicrosoftSync::Errors::HTTPBadGateway,
        503 => MicrosoftSync::Errors::HTTPServiceUnavailable,
        504 => MicrosoftSync::Errors::HTTPGatewayTimeout,
      }.each do |status_code, error_class|
        context "when the response status code is #{status_code}" do
          let(:code) { status_code }

          it "returns a #{error_class}" do
            expect(subject).to be_a(error_class)
          end
        end
      end

      context "when the response status code is 429" do
        let(:code) { 429 }

        it { expect(subject.retry_after_seconds).to be_nil }

        context "when the retry-after header is set" do
          let(:headers) { { "Retry-After" => "12.345" } }

          it "sets retry_after_seconds" do
            expect(subject.retry_after_seconds).to eq(12.345)
          end
        end
      end
    end
  end

  describe "GroupHasNoOwners" do
    it "has a public message" do
      expect(described_class::GroupHasNoOwners.public_message).to eq(
        I18n.t(
          "The team could be not be created because the Microsoft group has no owners. " \
          "This may be an intermittent error: please try to sync again, and " \
          "if the problem persists, contact support."
        )
      )
    end
  end

  describe "GracefulCancelError" do
    it "is a type of PublicError" do
      # ... since expected errors should have error messages for users
      expect(described_class::GracefulCancelError.new).to be_a(described_class::PublicError)
    end
  end
end
