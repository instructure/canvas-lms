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

require 'spec_helper'

describe Twitter::Connection do

  describe ".config=" do
    it "accepts any object with a call interface" do
      conf_class = Class.new do
        def call
          { 'monkey' => 'banana' }
        end
      end

      described_class.config =  conf_class.new
      expect(described_class.config['monkey']).to eq('banana')
    end

    it "rejects configs that are not callable" do
      expect { described_class.config = Object.new }.to(
        raise_error(RuntimeError) do |e|
          expect(e.message).to match(/must respond to/)
        end
      )
    end
  end

  describe ".config_check" do
    it "checks new key/secret" do
      settings = { api_key: "key", secret_key: "secret" }

      config = double(call: {})
      Twitter::Connection.config = config
      consumer = double(get_request_token: "token")
      expect(OAuth::Consumer).to receive(:new).
        with("key", "secret", anything).and_return(consumer)

      expect(Twitter::Connection.config_check(settings)).to be_nil
    end
  end

end
