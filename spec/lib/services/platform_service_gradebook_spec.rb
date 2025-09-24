# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Services
  describe PlatformServiceGradebook do
    let_once(:course) { course_factory(active_all: true) }
    let_once(:global_course_id) { course.global_id }
    let_once(:global_account_id) { course.account.global_id }
    let(:mock_dynamic_settings) { double("DynamicSettings") }

    before do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(mock_dynamic_settings)
      described_class.instance_variable_set(:@config, nil)
    end

    describe ".config" do
      context "with valid YAML" do
        it "parses and returns configuration hash" do
          yaml_content = <<~YAML
            overrides:
              course:
                #{global_course_id}: true
          YAML
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return(yaml_content)

          config = described_class.send(:config)
          expect(config).to eq({ "overrides" => { "course" => { global_course_id => true } } })
        end
      end

      context "with nil YAML content" do
        it "returns empty hash" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return(nil)

          config = described_class.send(:config)
          expect(config).to eq({})
        end
      end

      context "with empty YAML content" do
        it "returns empty hash" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return("")

          config = described_class.send(:config)
          expect(config).to eq({})
        end
      end

      context "with malformed YAML" do
        it "returns empty hash" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return("invalid: yaml: content:")

          config = described_class.send(:config)
          expect(config).to eq({})
        end
      end

      context "with non-hash YAML content" do
        it "returns empty hash for array" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return("- item1\n- item2")

          config = described_class.send(:config)
          expect(config).to eq({})
        end

        it "returns empty hash for string" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return("just a string")

          config = described_class.send(:config)
          expect(config).to eq({})
        end
      end

      context "with YAML parsing exception" do
        it "returns empty hash" do
          allow(mock_dynamic_settings).to receive(:[]).with("platform_service_gradebook.yml", failsafe: nil)
                                                      .and_return('{"invalid": json}')
          allow(YAML).to receive(:safe_load).and_raise(StandardError, "parsing error")

          config = described_class.send(:config)
          expect(config).to eq({})
        end
      end
    end

    describe ".overrides" do
      it "returns overrides from config when present" do
        yaml_content = <<~YAML
          overrides:
            course:
              #{global_course_id}: true
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.overrides).to eq({ "course" => { global_course_id => true } })
      end

      it "returns empty hash when overrides key missing" do
        yaml_content = <<~YAML
          other_key: value
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.overrides).to eq({})
      end

      it "returns empty hash when config is empty" do
        allow(mock_dynamic_settings).to receive(:[]).and_return(nil)

        expect(described_class.overrides).to eq({})
      end
    end

    describe ".graphql_usage_rate" do
      it "returns configured rate when valid" do
        yaml_content = <<~YAML
          graphql_usage_rate: 50
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.graphql_usage_rate).to eq(50)
      end

      it "clamps rate above 100 to 100" do
        yaml_content = <<~YAML
          graphql_usage_rate: 150
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.graphql_usage_rate).to eq(100)
      end

      it "clamps rate below 0 to 0" do
        yaml_content = <<~YAML
          graphql_usage_rate: -10
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.graphql_usage_rate).to eq(0)
      end

      it "returns 0 when value is not numeric" do
        yaml_content = <<~YAML
          graphql_usage_rate: not_a_number
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.graphql_usage_rate).to eq(0)
      end

      it "returns 0 when value is null" do
        yaml_content = <<~YAML
          graphql_usage_rate: null
        YAML
        allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

        expect(described_class.graphql_usage_rate).to eq(0)
      end

      it "returns 0 when config is empty" do
        allow(mock_dynamic_settings).to receive(:[]).and_return(nil)

        expect(described_class.graphql_usage_rate).to eq(0)
      end
    end

    describe ".use_graphql?" do
      context "with course override" do
        it "returns true when course override is true" do
          yaml_content = <<~YAML
            overrides:
              course:
                #{global_course_id}: true
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "returns false when course override is false" do
          yaml_content = <<~YAML
            overrides:
              course:
                #{global_course_id}: false
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be false
        end

        it "coerces truthy values to true" do
          yaml_content = <<~YAML
            overrides:
              course:
                #{global_course_id}: yes
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end
      end

      context "with account override (no course override)" do
        it "returns true when account override is true" do
          yaml_content = <<~YAML
            overrides:
              account:
                #{global_account_id}: true
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "coerces truthy values to true" do
          yaml_content = <<~YAML
            overrides:
              account:
                #{global_account_id}: yes
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "returns false when account override is false" do
          yaml_content = <<~YAML
            overrides:
              account:
                #{global_account_id}: false
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)
          expect(described_class).not_to receive(:rand)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be false
        end
      end

      context "without overrides (fallback to rate)" do
        before do
          allow(described_class).to receive(:rand).with(0..100).and_return(25)
        end

        it "returns true when rand <= usage_rate" do
          yaml_content = <<~YAML
            graphql_usage_rate: 50
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "returns false when rand > usage_rate" do
          yaml_content = <<~YAML
            graphql_usage_rate: 10
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be false
        end

        it "returns false when usage_rate is 0" do
          allow(described_class).to receive(:rand).with(0..100).and_return(1)
          yaml_content = <<~YAML
            graphql_usage_rate: 0
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be false
        end

        it "returns true when usage_rate is 100" do
          allow(described_class).to receive(:rand).with(0..100).and_return(100)
          yaml_content = <<~YAML
            graphql_usage_rate: 100
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end
      end

      context "edge cases" do
        it "handles missing account key in overrides" do
          allow(described_class).to receive(:rand).with(0..100).and_return(50)
          yaml_content = <<~YAML
            overrides:
              course: {}
            graphql_usage_rate: 75
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class).to receive(:rand)
          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "handles empty overrides object" do
          allow(described_class).to receive(:rand).with(0..100).and_return(25)
          yaml_content = <<~YAML
            overrides: {}
            graphql_usage_rate: 50
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class).to receive(:rand)
          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "handles nil overrides" do
          allow(described_class).to receive(:rand).with(0..100).and_return(25)
          yaml_content = <<~YAML
            overrides: null
            graphql_usage_rate: 50
          YAML
          allow(mock_dynamic_settings).to receive(:[]).and_return(yaml_content)

          expect(described_class).to receive(:rand)
          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be true
        end

        it "handles completely empty config" do
          allow(described_class).to receive(:rand).with(0..100).and_return(25)
          allow(mock_dynamic_settings).to receive(:[]).and_return(nil)

          expect(described_class).to receive(:rand)
          expect(described_class.use_graphql?(global_account_id, global_course_id)).to be false
        end
      end
    end
  end
end
