# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe InstLLMHelper do
  # TODO: rewrite tests for fetching credentials from the vault
  describe ".client" do
    before do
      InstLLMHelper.instance_variable_set(:@clients, nil)
    end

    it "creates a client for the given model_id" do
      model_id = "model123"
      expect(ENV).to receive(:[]).with("AWS_REGION").and_return("us-west-2")
      expect(ENV).to receive(:[]).with("AWS_ACCESS_KEY_ID").and_return("access_key_id")
      expect(ENV).to receive(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("secret_access_key")
      expect(ENV).to receive(:[]).with("AWS_SESSION_TOKEN").and_return("session_token")

      expect(InstLLM::Client).to receive(:new).with(
        model_id,
        region: "us-west-2",
        access_key_id: "access_key_id",
        secret_access_key: "secret_access_key",
        session_token: "session_token"
      )
      InstLLMHelper.client(model_id)
    end

    it "caches the client" do
      model_id = "model123"
      client = double
      allow(InstLLM::Client).to receive(:new).and_return(client)
      expect(InstLLMHelper.client(model_id)).to eq(client)
      expect(InstLLMHelper.client(model_id)).to eq(client)
    end
  end
end
