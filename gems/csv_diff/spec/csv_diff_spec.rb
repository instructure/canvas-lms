# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "spec_helper"

describe CsvDiff::Diff do
  subject { described_class.new(%w[pk1 pk2]) }

  # not a let because I want a new object returned each time
  def csv1(options = { headers: true })
    CSV.new(<<~CSV, **options)
      pk1,col1,pk2,col2
      a,b,c,d
      1,2,3,4
    CSV
  end

  def only_pk1
    CSV.new(<<~CSV, headers: true)
      pk1,col1,col2
      1,2,4
    CSV
  end

  def missing_pk
    CSV.new(<<~CSV, headers: true)
      col1,col2
      1,2
    CSV
  end

  def with_new_row
    CSV.new(<<~CSV, headers: true)
      pk1,col1,pk2,col2
      a,b,c,d
      a,b,x,d
      1,2,3,4
    CSV
  end

  def with_new_shuffled_row
    CSV.new(<<~CSV, headers: true)
      pk1,pk2,col1,col2
      a,c,b,d
      w,y,x,z
      1,3,2,4
    CSV
  end

  def with_changed_row
    CSV.new(<<~CSV, headers: true)
      pk1,col1,pk2,col2
      a,b,c,z
      1,2,3,4
    CSV
  end

  def with_deleted_row
    CSV.new(<<~CSV, headers: true)
      pk1,col1,pk2,col2
      1,2,3,4
    CSV
  end

  def only_header_row
    CSV.new(<<~CSV, headers: true)
      pk1,col1,pk2,col2
    CSV
  end

  def with_trailing_commas
    CSV.new(<<~CSV, headers: true)
      pk1,col1,pk2,col2,
      a,b,c,d,
      1,2,3,4,
    CSV
  end

  def with_nil_column
    CSV.new(<<~CSV, headers: true)
      pk1,,col1,pk2,col2,
      a,,b,c,d,
      1,,2,3,4,
    CSV
  end

  context "validation" do
    it "rejects csvs without headers" do
      expect { subject.generate(csv1(headers: false), csv1) }.to raise_error(CsvDiff::Failure, /headers/)
      expect { subject.generate(csv1, csv1(headers: false)) }.to raise_error(CsvDiff::Failure, /headers/)
    end

    it "rejects csvs with different header sets" do
      other = CSV.new("pk1,col1,pk2,colx\n1,2,3,4\n", headers: true)
      expect { subject.generate(csv1, other) }.to raise_error(CsvDiff::Failure, /headers/)
    end

    it "requires at least one pk column to be present" do
      expect { subject.generate(missing_pk, missing_pk) }.to raise_error(CsvDiff::Failure, /primary key/)
    end

    it "handles empty files" do
      cb = ->(row) { row["col2"] = "deleted" }
      output = subject.generate(csv1, only_header_row, deletes: cb)
      expect(output.read).to eq "pk1,col1,pk2,col2\na,b,c,deleted\n1,2,3,deleted\n"
    end
  end

  context "creates and updates" do
    it "generates an empty diff" do
      output = subject.generate(csv1, csv1)
      expect(output.read).to eq "pk1,col1,pk2,col2\n"
    end

    it "generates an empty diff, even with extra commas" do
      output = subject.generate(csv1, with_trailing_commas)
      expect(output.read).to eq "pk1,col1,pk2,col2\n"
    end

    it "generates an empty diff, even with a nil column in the middle" do
      output = subject.generate(csv1, with_nil_column)
      expect(output.read).to eq "pk1,col1,pk2,col2\n"
    end

    it "detects new rows" do
      output = subject.generate(csv1, with_new_row)
      expect(output.read).to eq "pk1,col1,pk2,col2\na,b,x,d\n"
    end

    it "detects changed rows" do
      output = subject.generate(csv1, with_changed_row)
      expect(output.read).to eq "pk1,col1,pk2,col2\na,b,c,z\n"
    end
  end

  it "handles different csv ordering" do
    output = subject.generate(csv1, with_new_shuffled_row)
    expect(output.read).to eq "pk1,pk2,col1,col2\nw,y,x,z\n"
  end

  it "allows for part of the pk to be missing" do
    other = CSV.new("pk1,col1,col2\n1,2,5\n", headers: true)
    output = subject.generate(only_pk1, other)
    expect(output.read).to eq "pk1,col1,col2\n1,2,5\n"
  end

  context "synthesized deletes" do
    it "inserts a deleted row with the changes specified" do
      cb = ->(row) { row["col2"] = "deleted" }
      output = subject.generate(csv1, with_deleted_row, deletes: cb)
      expect(output.read).to eq "pk1,col1,pk2,col2\na,b,c,deleted\n"
    end

    it "does not delete a changed row" do
      cb = ->(row) { row["col2"] = "deleted" }
      output = subject.generate(csv1, with_changed_row, deletes: cb)
      expect(output.read).to eq "pk1,col1,pk2,col2\na,b,c,z\n"
    end
  end

  it "handles a larger, shuffled test" do
    subject = described_class.new(%w[user_id])
    files = File.dirname(__FILE__) + "/files"
    previous = CSV.open(files + "/1.prev.csv", headers: true)
    current  = CSV.open(files + "/1.curr.csv", headers: true)
    cb = ->(row) { row["state"] = "deleted" }
    output = subject.generate(previous, current, deletes: cb)

    sorted_output = CSV.new(output, headers: true).read.to_a.sort
    expected_output = CSV.open(files + "/1.out.csv", headers: true).read.to_a.sort
    expect(sorted_output).to eq expected_output
  end

  it "returns a hash with a count if requested" do
    subject = described_class.new(%w[user_id])
    files = File.dirname(__FILE__) + "/files"
    previous = CSV.open(files + "/1.prev.csv", headers: true)
    current  = CSV.open(files + "/1.curr.csv", headers: true)
    cb = ->(row) { row["state"] = "deleted" }

    hash = subject.generate(previous, current, deletes: cb, return_count: true)
    expect(hash[:file_io].is_a?(Tempfile)).to be_truthy
    expect(hash[:row_count]).to eq 29
  end
end
