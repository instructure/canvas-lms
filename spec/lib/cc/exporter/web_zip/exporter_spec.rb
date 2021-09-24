# frozen_string_literal: true

# coding: utf-8
#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe "Exporter" do
  include CC::Exporter::WebZip

  before(:once) do
    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/exporter/cc-with-modules-export.imscc")
    end

    @attachment = Attachment.create({
      context: course_factory,
      filename: 'exportable-test-file',
      uploaded_data: File.open(cartridge_path)
    })

  end

  context "create web zip package default settings" do
    let(:exporter) do
      CC::Exporter::WebZip::Exporter.new(@attachment.open, false, :web_zip)
    end

    it "should sort content by module" do
      expect(exporter.base_template).to eq "../templates/module_sorting_template.html.erb"
    end

    it "should not URL escape file names" do
      expect(exporter.unsupported_files[1][:file_name]).to eq '!@#$%^&*().txt'
    end
  end
end
