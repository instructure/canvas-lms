# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "ims/concerns/advantage_services_shared_context"
require_relative "ims/concerns/lti_services_shared_examples"

module Lti
  describe PublicJwkController do
    describe "#update" do
      include_context "advantage services context"
      it_behaves_like "lti services" do
        let(:action) { :update }
        let(:expected_mime_type) { described_class::MIME_TYPE }
        let(:scope_to_remove) { "https://canvas.instructure.com/lti/public_jwk/scope/update" }
        let(:new_public_jwk) do
          key_hash = CanvasSecurity::RSAKeyPair.new.public_jwk.to_h
          key_hash["kty"] = key_hash["kty"].to_s
          key_hash
        end
        let(:params_overrides) do
          { developer_key: { public_jwk: new_public_jwk } }
        end
      end

      context "check public jwk" do
        let(:expected_mime_type) { described_class::MIME_TYPE }
        let(:scope_to_remove) { "https://canvas.instructure.com/lti/public_jwk/scope/update" }
        let(:action) { :update }
        let(:old_public_jwk) { developer_key.public_jwk }
        let(:new_public_jwk) do
          key_hash = CanvasSecurity::RSAKeyPair.new.public_jwk.to_h
          key_hash["kty"] = key_hash["kty"].to_s
          key_hash
        end
        let(:params_overrides) do
          { developer_key: { public_jwk: new_public_jwk } }
        end

        context "when public jwk is valid" do
          before do
            old_public_jwk
            send_request
          end

          it "update public jwk was successful" do
            expect(response.parsed_body["public_jwk"]).to_not eq old_public_jwk
            expect(response.parsed_body["public_jwk"]).to eq new_public_jwk
            expect(developer_key.reload.public_jwk).to eq new_public_jwk
          end

          it "return 200 success http status" do
            expect(response).to have_http_status http_success_status
          end
        end

        context "when pubic jwk is not valid" do
          let(:params_overrides) do
            { developer_key: { public_jwk: { hello: "world" } } }
          end

          before do
            old_public_jwk
            send_request
          end

          it "update public jwk was not successful" do
            expect(developer_key.public_jwk).to eq old_public_jwk
          end

          it "return 422 unathorized http status" do
            expect(response).to have_http_status :unprocessable_entity
          end
        end

        context "when pubic jwk is empty" do
          let(:params_overrides) do
            { developer_key: { public_jwk: {} } }
          end

          before do
            old_public_jwk
            send_request
          end

          it "update public jwk was not successful" do
            expect(response.parsed_body["public_jwk"]).to eq old_public_jwk
          end

          it "return 400 unathorized http status" do
            expect(response).to have_http_status :bad_request
          end
        end
      end
    end
  end
end
