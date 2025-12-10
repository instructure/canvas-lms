# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AuthenticationMethods::FederatedPseudonymAttributes do
  describe "#load_from" do
    let(:session) { {} }

    before do
      described_class.reset
    end

    context "with complete federated attributes" do
      before do
        session[:federated_pseudonym_attributes] = {
          "username" => "federated_user",
          "sis" => { "user_id" => "sis_12345" }
        }
      end

      it "loads both attributes" do
        described_class.load_from(session)
        expect(described_class.unique_id).to eq "federated_user"
        expect(described_class.sis_user_id).to eq "sis_12345"
      end

      it "logs the loaded attributes" do
        expect(Rails.logger).to receive(:info).with("[AUTH] Loaded federated pseudonym attributes: sis_user_id, unique_id")
        described_class.load_from(session)
      end
    end

    context "with only username" do
      before do
        session[:federated_pseudonym_attributes] = { "username" => "federated_user" }
      end

      it "loads only unique_id" do
        described_class.load_from(session)
        expect(described_class.unique_id).to eq "federated_user"
        expect(described_class.sis_user_id).to be_nil
      end
    end

    context "with only sis user_id" do
      before do
        session[:federated_pseudonym_attributes] = { "sis" => { "user_id" => "sis_12345" } }
      end

      it "loads only sis_user_id" do
        described_class.load_from(session)
        expect(described_class.unique_id).to be_nil
        expect(described_class.sis_user_id).to eq "sis_12345"
      end
    end

    context "with nil federated_pseudonym_attributes" do
      before do
        session[:federated_pseudonym_attributes] = nil
      end

      it "returns early without setting attributes" do
        described_class.load_from(session)
        expect(described_class.unique_id).to be_nil
        expect(described_class.sis_user_id).to be_nil
      end
    end

    context "with missing session key" do
      it "returns early without setting attributes" do
        described_class.load_from(session)
        expect(described_class.unique_id).to be_nil
        expect(described_class.sis_user_id).to be_nil
      end
    end

    context "with empty attributes hash" do
      before do
        session[:federated_pseudonym_attributes] = {}
      end

      it "does not log anything" do
        expect(Rails.logger).not_to receive(:info)
        described_class.load_from(session)
      end
    end
  end
end
