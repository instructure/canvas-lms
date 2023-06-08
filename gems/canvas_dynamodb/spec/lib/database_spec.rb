# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

describe CanvasDynamoDB::Database do
  let(:logger_cls) do
    Class.new do
      attr_reader :messages

      def initialize
        @messages = []
      end

      def debug(msg)
        @messages << msg
      end
    end
  end

  let(:db) do
    fingerprint = "asdf"
    prefix = "sdfa"
    CanvasDynamoDB::Database.new(fingerprint, prefix:, client_opts: {}, logger: logger_cls.new)
  end

  describe "#get_item" do
    before do
      ddb_client_class = Class.new do
        attr_reader :last_query

        def get_item(hash)
          @last_query = hash
          {}
        end
      end
      allow(Aws::DynamoDB::Client).to receive(:new).and_return(ddb_client_class.new)
    end

    it "prefixes table name on query" do
      db.get_item(table_name: "my_table", key: { object_id: "dfas", mutation_id: "fasd" })
      expect(db.client.last_query[:table_name]).to eq("sdfa-my_table")
    end

    it "does not require prefix" do
      unprefix_db = CanvasDynamoDB::Database.new("123456", logger: logger_cls.new)
      unprefix_db.get_item(table_name: "the_table", key: { object_id: "zxcv", mutation_id: "vcxz" })
      expect(unprefix_db.client.last_query[:table_name]).to eq("the_table")
    end

    it "logs requests" do
      db.get_item(table_name: "my_table", key: { object_id: "adsf", mutation_id: "afsd" })
      log_message = db.logger.messages.last
      expect(log_message).to match(/ DDB /)
      expect(log_message).to match(/\d+.\d+ms/)
      expect(log_message).to include("get_item({:table_name=>\"sdfa-my_table\"")
    end

    it "can just be given a client object" do
      fake = Object.new
      db = CanvasDynamoDB::Database.new("jklh", client_opts: { client: fake })
      expect(db.client).to eq(fake)
    end
  end
end
