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

require 'rails_helper'
require 'audits'

RSpec.describe Audits do

  after(:each) do
    DynamicSettings.config = nil
    DynamicSettings.reset_cache!
    DynamicSettings.fallback_data = nil
  end

  def inject_auditors_settings(yaml_string)
    DynamicSettings.fallback_data = {
        "private": {
          "canvas": {
            "auditors.yml": yaml_string
          }
        }
      }
  end

  describe "settings parsing" do
    it "parses pre-change write paths" do
      inject_auditors_settings("write_paths:\n  - cassandra\nread_path: cassandra")
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Audits.write_to_postgres?).to eq(false)
      expect(Audits.read_from_cassandra?).to eq(true)
      expect(Audits.read_from_postgres?).to eq(false)
    end

    it "understands dual write path" do
      inject_auditors_settings("write_paths:\n  - cassandra\n  - active_record\nread_path: cassandra")
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Audits.write_to_postgres?).to eq(true)
      expect(Audits.read_from_cassandra?).to eq(true)
      expect(Audits.read_from_postgres?).to eq(false)
    end

    it "understands postgres reading path" do
      inject_auditors_settings("write_paths:\n  - cassandra\n  - active_record\nread_path: active_record")
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Audits.write_to_postgres?).to eq(true)
      expect(Audits.read_from_cassandra?).to eq(false)
      expect(Audits.read_from_postgres?).to eq(true)
    end

    it "understands full cutover" do
      inject_auditors_settings("write_paths:\n  - active_record\nread_path: active_record")
      expect(Audits.write_to_cassandra?).to eq(false)
      expect(Audits.write_to_postgres?).to eq(true)
      expect(Audits.read_from_cassandra?).to eq(false)
      expect(Audits.read_from_postgres?).to eq(true)
    end

    it "defaults to cassandra read/write" do
      expect(Audits.write_to_cassandra?).to eq(true)
      expect(Audits.write_to_postgres?).to eq(true)
      expect(Audits.read_from_cassandra?).to eq(true)
      expect(Audits.read_from_postgres?).to eq(false)
    end
  end

  describe ".read_stream_options" do
    it "cleanly decorates arbitrary options with backend" do
      opts = Audits.read_stream_options({foo: :bar})
      expect(opts[:foo]).to eq(:bar)
      expect(opts[:backend_strategy]).to eq(:cassandra)
    end
  end

  describe ".configured?" do
    it "depends on cass db config for cassandra backend" do
      inject_auditors_settings("write_paths:\n  - cassandra\nread_path: cassandra")
      expect(Audits.backend_strategy).to eq(:cassandra)
      expect(CanvasCassandra::DatabaseBuilder).to receive(:configured?).with('auditors').and_return(true)
      expect(Audits.configured?).to eq(true)
      expect(CanvasCassandra::DatabaseBuilder).to receive(:configured?).with('auditors').and_return(false)
      expect(Audits.configured?).to eq(false)
    end

    it "depends on AR connection for AR backend" do
      inject_auditors_settings("write_paths:\n  - active_record\nread_path: active_record")
      expect(Audits.backend_strategy).to eq(:active_record)
      expect(Rails.configuration).to receive(:database_configuration).and_return({'test' => {"foo" => "bar"}})
      expect(Audits.configured?).to eq(true)
      expect(Rails.configuration).to receive(:database_configuration).and_return({})
      expect(Audits.configured?).to eq(false)
    end

    it "complains loudly under other configurations" do
      expect(Audits).to receive(:backend_strategy).and_return(:s3)
      expect{ Audits.configured? }.to raise_error(ArgumentError)
    end
  end

  describe ".stream" do
    it "constructs an event stream object with config on board" do
      ar_klass = Class.new
      record_klass = Class.new
      stream_obj = Audits.stream do
        backend_strategy ->{ :active_record }
        active_record_type ar_klass
        record_type record_klass
        table :test_stream_items
      end
      expect(stream_obj).to be_a(EventStream::Stream)
    end
  end
end