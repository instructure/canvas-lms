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

require_relative "../../cc_spec_helper"

describe "Exportable" do
  let(:klass) do
    Class.new do
      include CC::Exporter::Epub::Exportable

      def attachment
        cartridge_path = File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
        @attachment ||= Attachment.create({ context: Course.create, filename: "exportable-test-file", uploaded_data: File.open(cartridge_path) })
      end
    end
  end

  context "#convert_to_epub" do
    it "creates proper zip and an epub files" do
      @epub_export = klass.new.convert_to_epub
      expect(File.exist?(@epub_export.first) && File.exist?(@epub_export.last)).to be true
      sleep 0.1 # Wait just enough so we don't delete a parallel test's file
      FileUtils.rm_f(@epub_export.first)
      FileUtils.rm_f(@epub_export.last)
      expect(@epub_export.last).to include("unicode-filename-test")
    end
  end
end
