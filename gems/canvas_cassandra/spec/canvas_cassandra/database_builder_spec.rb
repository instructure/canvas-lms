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
#

require "spec_helper"

describe CanvasCassandra::DatabaseBuilder do

  let(:logger_klass) do
    Class.new do
      attr_reader :logs

      def initialize
        @logs = []
      end

      def error(message)
        @logs << message
      end
    end
  end

  before(:each) do
    target_location = Pathname.new(File.join(File.dirname(__FILE__), '..', 'fixtures'))
    allow(Rails).to receive(:root).and_return(target_location)
  end

  around(:each) do |example|
    @logger_obj = logger_klass.new
    prev_logger = CanvasCassandra.logger
    CanvasCassandra.logger = @logger_obj
    example.run
  ensure
    CanvasCassandra.logger = prev_logger
  end

  describe ".configured?" do
    it "loads config successfully" do
      configed = CanvasCassandra::DatabaseBuilder.configured?("foobars", "test")
      expect(configed).to be_truthy
    end
  end

  describe ".from_config" do
    it "boots a DB instance from config" do
      allow(CassandraCQL::Database).to receive(:new).and_return(double())
      db = CanvasCassandra::DatabaseBuilder.from_config("foobars")
      expect(@logger_obj.logs[0]).to be_nil
      expect(db).to be_a(CanvasCassandra::Database)
    end
  end

  describe ".read_consistency_setting" do
    it "loads setting from store" do
      store_klass = Class.new do
        def initialize(data={})
          @settings = data
        end

        def get(key, default)
          @settings.fetch(key, default)
        end
      end
      prev_store = CanvasCassandra.settings_store(true)
      settings = {
        'event_stream.read_consistency.foobars' => 'local_quorum'
      }
      CanvasCassandra.settings_store = store_klass.new(settings)
      val = CanvasCassandra::DatabaseBuilder.read_consistency_setting("foobars")
      expect(val).to eq("local_quorum")
    ensure
      CanvasCassandra.settings_store = prev_store
    end
  end
end
