# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Canvas::Migration::PackageIdentifier do
  it "errors if you try to get it to parse a package it has no setting for" do
    archive = double(path: "archive.zip", find_entry: true)
    allow(Canvas::Plugin).to receive(:all_for_tag).with(:export_system).and_return([])
    identifier = Canvas::Migration::PackageIdentifier.new(archive)
    expect{ identifier.get_converter }.to raise_error(Canvas::Migration::UnsupportedPackage)
  end
end