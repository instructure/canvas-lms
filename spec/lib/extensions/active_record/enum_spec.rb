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

module ActiveRecord
  describe Enum do
    let(:test_constant_name) { "TrafficLight" }

    describe ".enum" do
      subject(:enum) { TrafficLight.enum name, values }

      let(:instance) { TrafficLight.new }
      let(:name) { :color }
      let(:values) { %w[red yellow green] }

      before do
        stub_const(test_constant_name, Class.new(ActiveRecord::Base) do
          self.table_name = "pg_temp.traffic_lights"
        end)

        ActiveRecord::Base.connection.create_table("pg_temp.traffic_lights", temporary: true, force: true) do |t|
          t.string :color, default: "red"
        end

        TrafficLight.instance_variable_set(:@_enum_methods_module, nil)
      end

      after do
        ActiveRecord::Base.connection.drop_table("pg_temp.traffic_lights", if_exists: true)
      end

      it "defines the enum key/value pairs from values array" do
        enum
        expect(TrafficLight.colors).to eq("red" => "red", "yellow" => "yellow", "green" => "green")
      end

      it "sets the string value in the database" do
        enum
        instance.yellow!
        expect(instance.color_for_database).to eq("yellow")
      end

      it "defines scopes for each value" do
        enum
        expect(TrafficLight.red.to_sql).to eq(TrafficLight.where(color: "red").to_sql)
        expect(TrafficLight.yellow.to_sql).to eq(TrafficLight.where(color: "yellow").to_sql)
        expect(TrafficLight.green.to_sql).to eq(TrafficLight.where(color: "green").to_sql)
      end

      it "creates an instance with enum value" do
        enum
        instance.color = :yellow
        expect(instance.color).to eq("yellow")
      end

      it "sets the default value" do
        enum
        instance = TrafficLight.new
        expect(instance.color).to eq("red")
      end

      it "propagates options to the original enum method" do
        TrafficLight.enum name, values, prefix: true
        expect(TrafficLight).to respond_to(:color_red, :color_yellow, :color_green)
      end

      context "when the name is blank" do
        let(:name) { nil }

        it "raises an ArgumentError" do
          expect { enum }.to raise_error(ArgumentError, "Enum name is required")
        end
      end

      context "when the values are not an Array" do
        let(:values) { { red: 0, yellow: 1, green: 2 } }

        it "raises an ArgumentError" do
          expect { enum }.to raise_error(ArgumentError, "Enum values must be an Array")
        end
      end

      context "when values are symbols" do
        let(:values) { %i[red yellow green] }

        it "defines the enum key/value pairs from values array" do
          enum
          expect(TrafficLight.colors).to eq("red" => "red", "yellow" => "yellow", "green" => "green")
        end
      end

      context "when the set enum value is invalid" do
        it "raises an ArgumentError" do
          enum
          expect { instance.color = :invalid }.to raise_error(ArgumentError, "'invalid' is not a valid color")
        end
      end
    end
  end
end
