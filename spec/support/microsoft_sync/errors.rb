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

module MicrosoftSync::Matchers
  # Matcher the tests the following:
  # * Error descends from MicrosoftSync::Errors::PublicError
  # * error.class.public_message calls I18n.t
  # * public_message and public_interpolated_values combined, when serialized
  #   and deserialized (values interpolated), equal the expected message
  #   (default locale).  In doing so, it tests that the interpolated values
  #   match up with what is in the public_message.
  RSpec::Matchers.define :be_a_microsoft_sync_public_error do |expected_matched_message|
    match do |actual|
      @is_public_error_matcher = be_a(MicrosoftSync::Errors::PublicError)
      if (@is_public_error = @is_public_error_matcher.matches?(actual))
        original = I18n.method(:t)
        allow(I18n).to receive(:t) do |*args, **kwargs|
          @calls_i18n = true
          original.call(*args, **kwargs)
        end
        actual.class.public_message

        serialized = MicrosoftSync::Errors.serialize(actual)
        msg = MicrosoftSync::Errors.deserialize_and_localize(serialized)
        @msg_equals_matcher = match(expected_matched_message)
        @msg_equals = @msg_equals_matcher.matches?(msg)
      end

      @is_public_error && @calls_i18n && @msg_equals
    end

    failure_message do
      msgs = []
      if @is_public_error
        msgs << "expected error.class.public_message to call I18n.t" unless @calls_i18n
        msgs << "localized message: #{@msg_equals_matcher&.failure_message}" unless @msg_equals
      else
        msgs << @is_public_error_matcher.failure_message
      end
      msgs.join("\n")
    end
  end

  RSpec::Matchers.define :be_a_microsoft_sync_graceful_cancel_error do |expected_matched_message|
    match do |actual|
      @matchers = [
        be_a_microsoft_sync_public_error(expected_matched_message),
        be_a(MicrosoftSync::Errors::GracefulCancelError)
      ]
      @matches = @matchers.map { |m| m.matches?(actual) }
      @matches.all?
    end

    failure_message do
      matchers_that_failed = @matches.zip(@matchers).reject(&:first).map(&:last)
      matchers_that_failed.map(&:failure_message).join("\n")
    end
  end

  RSpec::Matchers.define :raise_microsoft_sync_public_error do |error_class, public_message|
    match do |actual|
      @matcher = raise_error(error_class) do |e|
        expect(e).to be_a_microsoft_sync_public_error(public_message)
      end
      @matcher.matches?(actual)
    end

    failure_message { @matcher.failure_message }

    def supports_block_expectations?
      true
    end
  end

  RSpec::Matchers.define :raise_microsoft_sync_graceful_cancel_error do |error_class, public_message|
    match do |actual|
      @matcher = raise_error(error_class) do |e|
        expect(e).to be_a_microsoft_sync_graceful_cancel_error(public_message)
      end
      @matcher.matches?(actual)
    end

    failure_message { @matcher.failure_message }

    def supports_block_expectations?
      true
    end
  end
end
