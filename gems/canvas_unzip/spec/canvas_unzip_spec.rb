#
# Copyright (C) 2011 Instructure, Inc.
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

require 'spec_helper'
require 'zip'

FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures'

def fixture_filename(fixture)
  File.join(FIXTURES_PATH, fixture)
end

describe "CanvasUnzip" do
  it "should extract an archive" do
    Dir.mktmpdir do |tmpdir|
      warnings = CanvasUnzip.extract_archive(fixture_filename('test.zip'), tmpdir)
      expect(warnings).to eq({})
      expect(File.directory?(File.join(tmpdir, 'empty_dir'))).to be true
      expect(File.read(File.join(tmpdir, 'file1.txt'))).to eq "file1\n"
      expect(File.read(File.join(tmpdir, 'sub_dir/file2.txt'))).to eq "file2\n"
      expect(File.read(File.join(tmpdir, 'implicit_dir/file3.txt'))).to eq "file3\n"
    end
  end

  it "should skip files that already exist by default" do
    Dir.mktmpdir do |tmpdir|
      File.open(File.join(tmpdir, 'file1.txt'), 'w') { |f| f.puts "OOGA" }
      warnings = CanvasUnzip.extract_archive(fixture_filename('test.zip'), tmpdir)
      expect(warnings).to eq({already_exists: ['file1.txt']})
      expect(File.read(File.join(tmpdir, 'file1.txt'))).to eq "OOGA\n"
      expect(File.read(File.join(tmpdir, 'sub_dir/file2.txt'))).to eq "file2\n"
    end
  end

  it "should overwrite files if specified by the block" do
    Dir.mktmpdir do |tmpdir|
      File.open(File.join(tmpdir, 'file1.txt'), 'w') { |f| f.puts "OOGA" }
      Dir.mkdir(File.join(tmpdir, 'sub_dir'))
      File.open(File.join(tmpdir, 'sub_dir/file2.txt'), 'w') { |f| f.puts "BOOGA" }
      warnings = CanvasUnzip.extract_archive(fixture_filename('test.zip'), tmpdir) do |entry, path|
        entry.name == 'sub_dir/file2.txt'
      end
      expect(warnings).to eq({already_exists: ['file1.txt']})
      expect(File.read(File.join(tmpdir, 'file1.txt'))).to eq "OOGA\n"
      expect(File.read(File.join(tmpdir, 'sub_dir/file2.txt'))).to eq "file2\n"
    end
  end

  it "should skip unsafe entries" do
    Dir.mktmpdir do |tmpdir|
      subdir = File.join(tmpdir, 'sub_dir')
      Dir.mkdir(subdir)
      warnings = CanvasUnzip.extract_archive(fixture_filename('evil.zip'), subdir)
      expect(warnings).to eq({unsafe: ['evil_symlink', '../outside.txt', 'tricky/../../outside.txt']})
      expect(File.exists?(File.join(tmpdir, 'outside.txt'))).to be false
      expect(File.exists?(File.join(subdir, 'evil_symlink'))).to be false
      expect(File.exists?(File.join(subdir, 'inside.txt'))).to be true
    end
  end

  it "should enumerate entries" do
    indices = []
    entries = []
    warnings = CanvasUnzip.extract_archive(fixture_filename('evil.zip')) do |entry, index|
      entries << entry
      indices << index
    end
    expect(warnings).to eq({unsafe: ['evil_symlink', '../outside.txt', 'tricky/../../outside.txt']})
    expect(indices.uniq.sort).to eq(indices)
    expect(entries.map(&:name)).to eq(['inside.txt', 'tricky/', 'tricky/innocuous_file'])
  end
end
