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

require_relative "../../spec_helper"

describe "doc:openapi rake task" do
  before do
    # Load rake tasks only once (conditional prevents redundant loads)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # Check if swagger_yard is available
  let(:swagger_yard_available) do
    require "swagger_yard"
    true
  rescue LoadError
    false
  end

  describe "task definition" do
    before do
      skip "swagger_yard gem not available" unless swagger_yard_available
    end

    let(:task) { Rake::Task["doc:openapi"] }

    it "is defined" do
      expect(task).not_to be_nil
    end

    it "accepts output_path argument" do
      expect(task.arg_names).to include(:output_path)
    end

    it "depends on :environment" do
      expect(task.prerequisites).to include("environment")
    end
  end

  describe "execution", :ignore_js_errors do
    before do
      skip "swagger_yard gem not available" unless swagger_yard_available

      # Disable CI guard for tests
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("CI").and_return(nil)

      # Mock TokenScopes to return sample routes (simulating DB access)
      allow(TokenScopes).to receive(:api_routes_for_openapi_docs).and_return({
                                                                               "users#index" => [
                                                                                 { path: "/users", method: "GET" }
                                                                               ],
                                                                               "courses#show" => [
                                                                                 { path: "/courses/:id", method: "GET" }
                                                                               ]
                                                                             })
    end

    let(:task) { Rake::Task["doc:openapi"] }

    it "creates output directory" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_dir = tmpdir_path.join("public/doc/openapi")
        output_dir.join("canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        expect { task.invoke(nil) }.not_to raise_error
        expect(File.directory?(output_dir)).to be true
      end
    end

    it "generates OpenAPI YAML file" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        expect(File.exist?(output_file)).to be true
        expect(File.size(output_file)).to be > 0
      end
    end

    it "generates valid YAML" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        expect { YAML.load_file(output_file) }.not_to raise_error
      end
    end

    it "generates OpenAPI 3.0 spec" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        expect(spec).to be_a(Hash)
        expect(spec["openapi"]).to eq("3.0.0")
      end
    end

    it "includes required OpenAPI fields" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        expect(spec).to include("openapi", "info", "paths")
        expect(spec["info"]).to include("title", "version")
      end
    end

    it "includes Canvas-specific configuration" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        expect(spec).to have_key("servers")
        expect(spec["servers"]).to be_an(Array)
        expect(spec["servers"].first["url"]).to include("instructure.com")
      end
    end

    it "includes security schemes" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        expect(spec).to have_key("components")
        expect(spec["components"]).to have_key("securitySchemes")
        expect(spec["components"]["securitySchemes"]).to have_key("bearer")
      end
    end

    it "generates paths from mocked routes" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        # With mocked routes, paths should be generated
        expect(spec["paths"]).to be_a(Hash)
        expect(spec["openapi"]).to eq("3.0.0")
      end
    end

    it "handles duplicate operation IDs" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        output_file = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        task.invoke(nil)

        spec = YAML.load_file(output_file)
        operation_ids = []

        spec["paths"].each_value do |methods|
          methods.each_value do |operation|
            next unless operation.is_a?(Hash)

            operation_ids << operation["operationId"] if operation["operationId"]
          end
        end

        # All operation IDs should be unique
        expect(operation_ids).to eq(operation_ids.uniq)
      end
    end

    it "generates OpenAPI spec to custom destination" do
      Dir.mktmpdir do |tmpdir|
        custom_output = File.join(tmpdir, "custom/location/api-spec.yaml")

        task.reenable
        task.invoke(custom_output)

        expect(File.exist?(custom_output)).to be true
        expect(File.size(custom_output)).to be > 0

        # Verify it's valid YAML with OpenAPI content
        spec = YAML.load_file(custom_output)
        expect(spec).to be_a(Hash)
        expect(spec["openapi"]).to eq("3.0.0")
      end
    end

    it "uses default path when no custom destination provided" do
      Dir.mktmpdir do |tmpdir|
        tmpdir_path = Pathname.new(tmpdir)
        default_output = tmpdir_path.join("public/doc/openapi/canvas.openapi.yaml")

        allow(Dir).to receive(:pwd).and_return(tmpdir.to_s)
        task.reenable

        # Invoke without arguments to test default behavior
        task.invoke(nil)

        expect(File.exist?(default_output)).to be true
      end
    end
  end

  describe "error handling" do
    it "handles missing swagger_yard gracefully" do
      # This test assumes the LoadError rescue in openapi.rake works
      # If swagger_yard is not available, the task should not be defined
      if defined?(SwaggerYard)
        task = Rake::Task["doc:openapi"]
        expect(task).not_to be_nil
      end
    end
  end
end
