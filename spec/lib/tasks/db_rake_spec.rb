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

describe "db rake tasks" do
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  let(:consul_key) { "store/canvas/#{DynamicSettings.environment}/activerecord/ignored_columns/users" }

  describe "db:set_ignored_columns" do
    let(:task) { Rake::Task["db:set_ignored_columns"] }

    before do
      task.reenable
      allow(Zeitwerk::Loader).to receive(:eager_load_all)
      allow(MultiCache).to receive(:delete)
    end

    after do
      task.reenable
    end

    describe "task definition" do
      it "is defined" do
        expect(task).not_to be_nil
      end

      it "accepts table_name and columns arguments" do
        expect(task.arg_names).to include(:table_name, :columns)
      end

      it "depends on :environment" do
        expect(task.prerequisites).to include("environment")
      end
    end

    describe "execution with + delimiter" do
      it "parses single column correctly" do
        expect(Diplomat::Kv).to receive(:put).with(consul_key, "new_column")

        expect do
          task.invoke("users", "new_column")
        end.to output(/Ignoring columns for users: \[new_column\]/).to_stdout
      end

      it "parses multiple columns correctly" do
        expect(Diplomat::Kv).to receive(:put).with(consul_key, "col1,col2,col3")

        expect do
          task.invoke("users", "col1+col2+col3")
        end.to output(/Ignoring columns for users: \[col1, col2, col3\].*delimiter '\+'/).to_stdout
      end

      it "stores columns in Consul as comma-separated" do
        expect(Diplomat::Kv).to receive(:put).with(consul_key, "col1,col2")

        task.invoke("users", "col1+col2")
      end

      it "deletes schema cache after setting columns" do
        allow(Diplomat::Kv).to receive(:put)

        expect(MultiCache).to receive(:delete).with("schema_cache")

        task.invoke("users", "new_column")
      end
    end

    describe "execution with comma delimiter (deprecated)" do
      it "still works with comma-separated columns" do
        expect(Diplomat::Kv).to receive(:put).with(consul_key, "col1,col2")

        expect do
          task.invoke("users", "col1,col2")
        end.to output(/DEPRECATED.*Use '\+' as delimiter instead/).to_stderr
           .and output(/delimiter ','/).to_stdout
      end

      it "warns about deprecation" do
        allow(Diplomat::Kv).to receive(:put)

        expect do
          task.invoke("users", "col1,col2")
        end.to output(/DEPRECATED: Using comma-separated columns/).to_stderr
      end
    end

    describe "column filtering" do
      it "filters out columns that already exist" do
        expect(Diplomat::Kv).to receive(:put).with(consul_key, "new_column")

        expect do
          task.invoke("users", "id+name+new_column")
        end.to output(/NOT ignoring column 'id,name'.*already exist/).to_stderr
      end

      it "removes all ignored columns if no valid columns remain" do
        expect(Diplomat::Kv).to receive(:delete).with(consul_key)

        expect do
          task.invoke("users", "id+name")
        end.to output(/No columns set for ignoring/).to_stderr
      end
    end

    describe "error handling" do
      it "skips if model is not found" do
        expect(Diplomat::Kv).not_to receive(:put)
        expect(Diplomat::Kv).not_to receive(:delete)

        expect do
          task.invoke("nonexistent_table", "col1+col2")
        end.to output(/Model for table 'nonexistent_table' not found/).to_stderr
      end

      it "skips if table does not exist" do
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with("users").and_return(false)

        expect(Diplomat::Kv).not_to receive(:put)
        expect(Diplomat::Kv).not_to receive(:delete)

        expect do
          task.invoke("users", "col1+col2")
        end.to output(/has no backing table/).to_stderr
      end
    end
  end

  describe "db:get_ignored_columns" do
    let(:task) { Rake::Task["db:get_ignored_columns"] }

    before do
      task.reenable
    end

    after do
      task.reenable
    end

    describe "task definition" do
      it "is defined" do
        expect(task).not_to be_nil
      end

      it "accepts table_name argument" do
        expect(task.arg_names).to include(:table_name)
      end

      it "depends on :environment" do
        expect(task.prerequisites).to include("environment")
      end
    end

    describe "execution" do
      it "retrieves ignored columns from Consul" do
        allow(Diplomat::Kv).to receive(:get).with(consul_key).and_return("col1,col2,col3")

        expect do
          task.invoke("users")
        end.to output(/Ignored Columns: col1,col2,col3/).to_stdout
      end

      it "handles missing key gracefully" do
        allow(Diplomat::Kv).to receive(:get).with(consul_key).and_raise(Diplomat::KeyNotFound)

        expect do
          task.invoke("users")
        end.to output(/Ignored Columns: -/).to_stdout
      end
    end
  end

  describe "db:clear_ignored_columns" do
    let(:task) { Rake::Task["db:clear_ignored_columns"] }

    before do
      task.reenable
      allow(MultiCache).to receive(:delete)
    end

    after do
      task.reenable
    end

    describe "task definition" do
      it "is defined" do
        expect(task).not_to be_nil
      end

      it "accepts table_name argument" do
        expect(task.arg_names).to include(:table_name)
      end

      it "depends on :environment" do
        expect(task.prerequisites).to include("environment")
      end
    end

    describe "execution" do
      it "deletes the key from Consul" do
        expect(Diplomat::Kv).to receive(:delete).with(consul_key)

        task.invoke("users")
      end

      it "deletes schema cache after clearing columns" do
        allow(Diplomat::Kv).to receive(:delete)

        expect(MultiCache).to receive(:delete).with("schema_cache")

        task.invoke("users")
      end
    end
  end

  describe "integration scenarios" do
    let(:set_task) { Rake::Task["db:set_ignored_columns"] }
    let(:get_task) { Rake::Task["db:get_ignored_columns"] }
    let(:clear_task) { Rake::Task["db:clear_ignored_columns"] }

    before do
      set_task.reenable
      get_task.reenable
      clear_task.reenable
      allow(Zeitwerk::Loader).to receive(:eager_load_all)
      allow(MultiCache).to receive(:delete)
    end

    it "sets and retrieves columns using + delimiter" do
      allow(Diplomat::Kv).to receive(:put)
      allow(Diplomat::Kv).to receive(:get).with(consul_key).and_return("col1,col2,col3")

      set_task.invoke("users", "col1+col2+col3")
      set_task.reenable

      output = capture_stdout do
        get_task.invoke("users")
      end

      expect(output).to include("Ignored Columns: col1,col2,col3")
    end

    it "clears previously set columns" do
      allow(Diplomat::Kv).to receive(:put)
      expect(Diplomat::Kv).to receive(:delete).with(consul_key)

      set_task.invoke("users", "col1+col2")
      set_task.reenable

      clear_task.invoke("users")
    end
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
