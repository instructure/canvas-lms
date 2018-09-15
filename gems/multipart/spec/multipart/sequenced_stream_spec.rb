#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper.rb'

describe Multipart::SequencedStream do
  def test_copy(content, content_string)
    source = Multipart::SequencedStream.new([StringIO.new("prefix|"), content, StringIO.new("|suffix")])
    destination = StringIO.new
    IO.copy_stream(source, destination)
    destination.rewind
    expect(destination.read).to eq("prefix|#{content_string}|suffix")
  end

  it "should work as a source for IO.copy_stream" do
    file = Tempfile.new(["test","txt"])
    file.write("file on disk")
    file.rewind
    test_copy(file, "file on disk")
  end

  class CustomStream
    def initialize(content_string, &reader)
      @source = StringIO.new(content_string)
      @reader = lambda { |*args| reader.(@source, *args) }
    end

    def size; @source.size; end
    def read(*args); @reader.call(*args); end
  end

  it "only requires `size` and `read` on the component stream" do
    # just delegate read to the source, but it's wrapped to hide the other
    # StringIO methods
    content_string = "howdy, howdy, howdy!"
    content = CustomStream.new(content_string) do |source, *args|
      source.read(*args)
    end
    test_copy(content, content_string)
  end

  it "allows partial read responses without EOF from component stream" do
    # leave read() and read(0) alone, but restrict to one byte returned at a
    # time for read(n)
    content_string = "howdy, howdy, howdy!"
    content = CustomStream.new(content_string) do |source, n, *args|
      n = 1 if n && n > 0
      source.read(n, *args)
    end
    test_copy(content, content_string)
  end
end
