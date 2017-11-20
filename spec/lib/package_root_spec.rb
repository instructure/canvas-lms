#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/package_root'

describe PackageRoot do
  let(:root_path) { File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/importer/unzipped')) }
  let(:subject) { PackageRoot.new(root_path) }

  it "returns the root_path" do
    expect(subject.root_path).to eq(root_path)
  end

  it "returns the name of an item inside" do
    expect(subject.item_path('imsmanifest.xml')).to eq(File.join(root_path, 'imsmanifest.xml'))
  end

  it "follows .. paths" do
    expect(subject.item_path('course_settings', '..', 'imsmanifest.xml')).to eq(File.join(root_path, 'imsmanifest.xml'))
  end

  it "refuses to follow .. paths above the package root" do
    expect {
      subject.item_path('course_settings', '..', '..', 'assessments.json')
    }.to raise_error(ArgumentError)
  end

  it "makes relative paths" do
    expect(subject.relative_path(File.join(root_path, 'course_settings', 'course_settings.xml'))).to eq 'course_settings/course_settings.xml'
  end

  it "enumerates contents" do
    expect(subject.contents).to include File.join(root_path, 'imsmanifest.xml')
    expect(subject.contents).to include File.join(root_path, 'course_settings', 'course_settings.xml')
    expect(subject.contents('**/files_meta.xml').to_a).to eq([File.join(root_path, 'course_settings/files_meta.xml')])
  end
end
