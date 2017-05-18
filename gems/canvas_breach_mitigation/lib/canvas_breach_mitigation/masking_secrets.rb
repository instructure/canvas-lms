#
# Copyright (C) 2013 - present Instructure, Inc.
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

module CanvasBreachMitigation
  class MaskingSecrets
    class << self
      AUTHENTICITY_TOKEN_LENGTH = 32

      # Sets the token value for the current session and returns it in
      # a masked form that's safe to send to the client. See section
      # 3.4 of "BREACH: Reviving the CRIME attack".
      def masked_authenticity_token(cookies, options={})
        # remask token
        encoded_masked_token = masked_token(unmasked_token(cookies['_csrf_token']))

        cookie = { value: encoded_masked_token }
        [:domain, :httponly, :secure].each do |key|
          next unless options.has_key?(key)
          cookie[key] = options[key]
        end
        cookies['_csrf_token'] = cookie

        encoded_masked_token
      end

      def reset_authenticity_token!(cookies)
        cookies['_csrf_token'] = nil
        masked_authenticity_token(cookies)
      end

      def valid_authenticity_token?(cookies, encoded_masked_token)
        unmasked_token(cookies['_csrf_token']) == unmasked_token(encoded_masked_token)
      end

      def masked_token(token)
        one_time_pad = SecureRandom.random_bytes(AUTHENTICITY_TOKEN_LENGTH)
        encrypted_csrf_token = xor_byte_strings(one_time_pad, token)
        masked_token = one_time_pad + encrypted_csrf_token
        Base64.strict_encode64(masked_token)
      end

      private

      def unmasked_token(encoded_masked_token)
        if encoded_masked_token.nil? || encoded_masked_token.length == 0
          return SecureRandom.base64(AUTHENTICITY_TOKEN_LENGTH)
        end
        masked_token = Base64.strict_decode64(encoded_masked_token)
        one_time_pad = masked_token[0...AUTHENTICITY_TOKEN_LENGTH]
        encrypted_csrf_token = masked_token[AUTHENTICITY_TOKEN_LENGTH..-1]
        xor_byte_strings(one_time_pad, encrypted_csrf_token)
      rescue
        SecureRandom.base64(AUTHENTICITY_TOKEN_LENGTH)
      end

      def xor_byte_strings(s1, s2)
        s1.bytes.zip(s2.bytes).map { |(c1,c2)| c1 ^ c2 }.pack('c*')
      end
    end
  end
end
