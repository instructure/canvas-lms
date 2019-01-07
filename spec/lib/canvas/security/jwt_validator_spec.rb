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

require_relative '../../../spec_helper'
require_dependency "canvas/security/jwt_validator"

module Canvas::Security
  describe JwtValidator do
    subject { validator.error_message }

    let(:validator) do
      described_class.new(
        jwt: jwt, expected_aud: expected_aud, require_iss: require_iss, skip_jti_check: skip_jti_check
      )
    end
    let(:aud) { Rails.application.routes.url_helpers.oauth2_token_url }
    let(:expected_aud) { Rails.application.routes.url_helpers.oauth2_token_url }
    let(:iat) { 1.minute.ago.to_i }
    let(:exp) { 10.minutes.from_now.to_i }
    let(:require_iss) { false }
    let(:skip_jti_check) { false }
    let(:jwt) do
      {
        'iss' => 'someiss',
        'sub' => '1',
        'aud' => aud,
        'iat' => iat,
        'exp' => exp,
        'jti' => SecureRandom.uuid
      }
    end

    before do |ex|
      Rails.application.routes.default_url_options[:host] = 'example.com'
      unless ex.metadata[:skip_before]
        validator.validate
      end
    end

    it { is_expected.to be_empty }

    context 'with bad aud' do
      let(:aud) { 'doesnotexist' }

      it { is_expected.not_to be_empty }
    end

    context 'with bad exp' do
      let(:exp) { 1.minute.ago.to_i }

      it { is_expected.not_to be_empty }
    end

    context 'with bad iat' do
      let(:iat) { 1.minute.from_now.to_i }

      it { is_expected.not_to be_empty }

      context 'with iat too far in future' do
        let(:iat) { 6.minutes.from_now.to_i }

        it { is_expected.not_to be_empty }
      end
    end

    context 'jti check' do
      it 'is false when validated twice', skip_before: true do
        enable_cache do
          validator.validate
          expect(validator.validate).to eq false
        end
      end

      context 'when skip_jti_check is on' do
        let(:skip_jti_check) { true }

        it 'is true when when validated twice', skip_before: true do
          enable_cache do
            validator.validate
            expect(validator.validate).to eq true
          end
        end
      end
    end

    context 'with missing assertion' do
      Canvas::Security::JwtValidator::REQUIRED_ASSERTIONS.each do |assertion|
        it "returns an error message when #{assertion} missing", skip_before: true do
          jwt.delete assertion
          validator.validate
          expect(subject).not_to be_empty
        end
      end

      context 'with require_iss set to true' do
        let(:require_iss) { true }

        it 'returns an error message when iss is missing', skip_before: true do
          jwt.delete 'iss'
          validator.validate
          expect(subject).not_to be_empty
        end
      end

      context 'with require_iss set to false' do
        it 'returns no error message when iss is missing', skip_before: true do
          validator.validate
          expect(subject).to be_empty
        end
      end
    end
  end
end
