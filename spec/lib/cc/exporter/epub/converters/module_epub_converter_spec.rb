# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../../../cc_spec_helper"

describe "ModuleEpubConverter" do
  let(:klass) do
    Class.new(Canvas::Migration::Migrator) do
      include CC::Exporter::Epub::Converters::ModuleEpubConverter
    end
  end

  describe "with cartrigde" do
    subject(:test_instance) do
      cartrige_path = File.join(File.dirname(__FILE__), "/../../../../../fixtures/exporter/cc-with-modules-export.imscc")
      klass.new({ archive_file: File.open(cartrige_path) }, "cc")
    end

    it "returns the page content" do
      test_instance.unzip_archive
      expect(test_instance.page_content["i72cba0aca506f9b9a7fc41a03777e779"]).to match("Those are my lucky numbers")
    end

    it "includes page content in the modules" do
      test_instance.unzip_archive

      module_b = test_instance.convert_modules.find { |m| m[:title] == "Module B" }
      page = module_b[:items].find { |i| i[:title] == "Wiki Page 2" }
      expect(page[:text]).to match("The dangers of fighting on the wing of moving airplanes")
    end
  end
end
