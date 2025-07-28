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
#

describe DataFixup::BulkColumnUpdater do
  let(:tools) { Array.new(3) { external_tool_model.tap(&:save!) } }

  def expect_values(values)
    expect(tools.map { |t| t.reload.unified_tool_id }).to eq values
  end

  def with_temp_file(&)
    temp_file = Tempfile.new("bulk_column_updater_spec")
    yield(temp_file)
    File.read(temp_file).split("\n")
  ensure
    temp_file&.close unless temp_file&.closed?
    temp_file&.unlink
  end

  before do
    # Disconnecting in Rails test env actually clears the table, so stop that
    allow(ContextExternalTool.connection).to receive(:disconnect!)
  end

  describe "happy path" do
    it "performs the writes at the end" do
      bcu = described_class.new(ContextExternalTool, :unified_tool_id)
      bcu.update! do |add_rows_fn|
        add_rows_fn.call [[tools[2].id, "three"]]
        add_rows_fn.call [[tools[0].id.to_s, "one"], [tools[1].id, "two"]]
        expect_values [nil, nil, nil]
      end
      expect_values %w[one two three]
    end

    it "returns the number of returned rows on success" do
      with_temp_file do |log_file|
        log_filename = log_file.path
        bcu = described_class.new(ContextExternalTool, :unified_tool_id, log_filename:)
        result = bcu.update! do |add_rows_fn|
          add_rows_fn.call [[tools[1].id, "two"]]
          add_rows_fn.call [[tools[2].id, "three"]]
        end
        expect(result).to eq 2
      end
    end

    it "chunks in insertions of INSERT_CHUNK_SIZE and transactions of TRANSACTION_CHUNK_SIZE" do
      stub_const("DataFixup::BulkColumnUpdater::INSERT_CHUNK_SIZE", 1)
      stub_const("DataFixup::BulkColumnUpdater::TRANSACTION_CHUNK_SIZE", 2)

      log_lines = with_temp_file do |log_file|
        log_filename = log_file.path
        bcu = described_class.new(ContextExternalTool, :unified_tool_id, log_filename:)
        bcu.update! do |add_rows_fn|
          add_rows_fn.call [[tools[2].id, "three"]]
          add_rows_fn.call [[tools[0].id.to_s, "one"], [tools[1].id, "two"]]
        end
      end

      expect(log_lines).not_to include(a_string_matching(/ERROR/))

      expect(log_lines).to include(a_string_matching(/Created temp table.*context_external_tools_/))

      expect(log_lines).to include(a_string_matching(/Wrote 1 rows to temp table/))
      expect(log_lines).not_to include(a_string_matching(/Wrote 2 rows to temp table/))

      expect(log_lines).not_to include(a_string_matching(/Flush .*context_external_tools_.* to .*context_external_tools.*complete: 3 rows updated/))
      expect(log_lines).to include(a_string_matching(/Flush .*context_external_tools_.* to .*context_external_tools.*complete: 2 rows updated/))
    end

    it "reads from a TSV file" do
      with_temp_file do |tsv_file|
        tsv_file.write("#{tools[0].id}\tone\n#{tools[1].id}\ttwo\n#{tools[2].id}\tthree\n")
        tsv_file.close
        bcu = described_class.new(ContextExternalTool, :unified_tool_id)
        bcu.update_from_tsv!(tsv_file.path)
        expect_values %w[one two three]
      end
    end

    it "batches the writes in the TSV file" do
      log_lines = with_temp_file do |log_file|
        with_temp_file do |tsv_file|
          tsv_file.write("#{tools[0].id}\tone\n#{tools[1].id}\ttwo\n#{tools[2].id}\tthree\n")
          tsv_file.close
          log_filename = log_file.path
          bcu = described_class.new(ContextExternalTool, :unified_tool_id, log_filename:)
          bcu.update_from_tsv!(tsv_file.path, batch_size: 1)
        end
      end

      expect_values %w[one two three]
      expect(log_lines).to include(a_string_matching(/Wrote 3 rows to temp table/))
    end
  end

  it "allows empty strings only when specified" do
    with_temp_file do |tsv_file|
      tsv_file.write("#{tools[0].id}\t\n")
      tsv_file.close

      bcu = described_class.new(ContextExternalTool, :unified_tool_id)
      expect { bcu.update_from_tsv!(tsv_file.path) }.to raise_error(ArgumentError)

      bcu = described_class.new(ContextExternalTool, :unified_tool_id, allow_empty_strings: true)
      bcu.update_from_tsv!(tsv_file.path)
      expect_values(["", nil, nil])
    end
  end

  it "allows nils only when specified" do
    tools[0].update!(unified_tool_id: "one")
    expect_values(["one", nil, nil])

    with_temp_file do |tsv_file|
      tsv_file.write("#{tools[0].id}\n")
      tsv_file.close

      bcu = described_class.new(ContextExternalTool, :unified_tool_id)
      expect { bcu.update_from_tsv!(tsv_file.path) }.to raise_error(ArgumentError)

      bcu = described_class.new(ContextExternalTool, :unified_tool_id, allow_nils: true)
      bcu.update_from_tsv!(tsv_file.path)
      expect_values([nil, nil, nil])
    end
  end

  it "rescues exceptions and returns -1 when used with a log file" do
    log_lines = with_temp_file do |log_file|
      log_filename = log_file.path
      bcu = described_class.new(ContextExternalTool, :unified_tool_id, log_filename:)
      result = bcu.update! do |_add_rows_fn|
        raise "oh no"
      end
      expect(result).to be(-1)
    end
    expect(log_lines).to include(a_string_matching(/ERROR: #<RuntimeError: oh no>/))
  end

  it "bubbles up errors when not used with a log file" do
    bcu = described_class.new(ContextExternalTool, :unified_tool_id)
    expect do
      bcu.update! do |_add_rows_fn|
        raise "oh no"
      end
    end.to raise_error("oh no")
  end

  it "validates that the model is an ActiveRecord model" do
    expect { described_class.new(Class.new, :bar) }.to raise_error(ArgumentError)
  end

  it "validates that the column is a string or symbol" do
    expect { described_class.new(ContextExternalTool, 123) }.to raise_error(ArgumentError)
  end

  it "validates that the column exists on the model"  do
    expect { described_class.new(ContextExternalTool, :bar) }.to raise_error(ArgumentError)
  end

  it "validates the structure of the rows" do
    bcu = described_class.new(ContextExternalTool, :unified_tool_id)
    bcu.update! do |add_rows_fn|
      bad_args = [
        [[tools[0].id, "one", "extra"]],
        [[tools[0].id]],
        [tools[0].id, "one"],
        [tools[0].id, "one", "two"],
        [tools[0].id],
        tools[0].id
      ]

      bad_args.each do |args|
        expect { add_rows_fn.call args }.to raise_error(ArgumentError)
      end
    end
  end

  it "creates a temporary table to be dropped on transaction commit" do
    allow(ContextExternalTool.connection).to receive(:create_table).and_call_original

    bcu = described_class.new(ContextExternalTool, :unified_tool_id)
    bcu.update! do |add_rows|
      add_rows.call [[tools[0].id, "one"]]
    end

    expect(ContextExternalTool.connection).to have_received(:create_table).with(/context_external_tools_/, temporary: true, id: an_instance_of(String), options: "ON COMMIT DROP")
  end
end
