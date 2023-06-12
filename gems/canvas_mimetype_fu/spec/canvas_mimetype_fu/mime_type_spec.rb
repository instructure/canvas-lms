# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe "A file with a know extension" do
  before do
    @file = File.open(File.dirname(__FILE__) + "/../fixtures/file.jpg")
  end

  it "has an extension" do
    expect(File.extname(@file.path)).to eq(".jpg")
  end

  it "has a mime type" do
    expect(File.mime_type?(@file)).to eq("image/jpeg")
  end

  it "find a extension from mime_typee" do
    expect(File.mime_types["application/pdf"]).to eq "pdf"

    expect(File.mime_types["application/x-kontour"]).to eq "kon"
    expect(File.mime_types["application/vnd.kde.kontour"]).to eq "kon"

    expect(File.mime_types["image/webp"]).to eq "webp"
  end
end

describe "A file with an unknow extension" do
  before do
    @file = File.open(File.dirname(__FILE__) + "/../fixtures/file.unknown")
  end

  it "has an extension" do
    expect(File.extname(@file.path)).to eq(".unknown")
  end

  it "has an unkwown mime type" do
    expect(File.mime_type?(@file)).to eq("unknown/unknown")
  end
end

describe "A valid file path" do
  before do
    @file_path = "#{Dir.pwd} + /picture.png"
  end

  it "has a mime type" do
    expect(File.mime_type?(@file_path)).to eq("image/png")

    @file_path = "#{Dir.pwd} + /picture.zip"

    expect(File.mime_type?(@file_path)).to eq("application/zip")
  end
end

describe "An unknown extension" do
  before do
    @file_path = "file.unknown"
  end

  it "has an unknown mime type" do
    expect(File.mime_type?(@file_path)).to eq("unknown/unknown")
  end
end
