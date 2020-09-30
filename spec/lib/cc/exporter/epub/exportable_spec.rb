# coding: utf-8
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

require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

describe "Exportable" do
  class ExportableTest
    include CC::Exporter::Epub::Exportable

    def attachment
      @_attachment ||= Attachment.create({
        context: Course.create,
        filename: 'exortable-test-file',
        uploaded_data: File.open(cartridge_path)
      })
    end

    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
    end
  end

  context "#convert_to_epub" do

    before do
      @epub_export = ExportableTest.new.convert_to_epub
    end

    let(:epub_path) do
      @epub_export.first
    end

    let(:zip_path) do
      @epub_export.last
    end

    let(:epub) do
      File.open(epub_path)
    end

    let(:zip) do
      File.open(zip_path)
    end

    it "should create an epub file" do
      skip 'PHO-409 (9/30/2020)'
      expect(epub).not_to be_nil
    end

    it "should create a zip file" do
      skip 'PHO-409 (9/30/2020)'
      expect(zip).not_to be_nil
    end

    it "creates a zip file whose name includes the cartridge's name" do
      skip 'PHO-409 (9/30/2020)'
      expect(zip_path).to include('unicode-filename-test')
    end

    after do
      File.delete(epub_path) if File.exist?(epub_path)
      File.delete(zip_path) if File.exist?(zip_path)
    end
  end

end
