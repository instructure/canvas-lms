# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "rubyzip encoding fix patch" do
  before(:all) do
    @utf8_name = "utf-8 molé"
    @ascii_name = (+"ascii mol\xE9").force_encoding("ASCII-8BIT")

    @tmpfile = Tempfile.new("datafile")
    @tmpfile.write("some data")
    @tmpfile.close

    tmpzipfile = Tempfile.new("zipfile")
    @zip_path = tmpzipfile.path
    tmpzipfile.close!
    Zip::File.open(@zip_path, true) do |arch|
      arch.add @utf8_name, @tmpfile.path
      arch.add @ascii_name, @tmpfile.path
    end
  end

  after(:all) do
    @tmpfile.unlink
    File.unlink @zip_path
  end

  context "with zip file" do
    before do
      @arch = Zip::File.open(@zip_path)
    end

    after do
      @arch.close
    end

    describe "entries" do
      it "returns UTF-8 names in UTF-8 encoding" do
        expect(@arch.entries.map(&:name).select { |filename| filename.encoding.to_s == "UTF-8" }).to eql [@utf8_name]
      end

      it "returns non-UTF-8 names in ASCII-8BIT encoding" do
        expect(@arch.entries.map(&:name).select { |filename| filename.encoding.to_s == "ASCII-8BIT" }).to eql [@ascii_name]
      end
    end

    describe "find_entry" do
      it "finds a UTF-8 name" do
        expect(@arch.find_entry(@utf8_name)).not_to be_nil
      end

      it "finds a non-UTF-8 name" do
        expect(@arch.find_entry(@ascii_name)).not_to be_nil
      end
    end
  end
end
