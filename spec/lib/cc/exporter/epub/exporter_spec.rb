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

describe "Exporter" do
  include CC::Exporter::Epub

  before(:once) do
    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/exporter/cc-with-modules-export.imscc")
    end

    def cartridge_without_modules_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/exporter/cc-without-modules-export.imscc")
    end

    @attachment = Attachment.create({
                                      context: course_factory,
                                      filename: "exportable-test-file",
                                      uploaded_data: File.open(cartridge_path)
                                    })

    @attachment_without_modules = Attachment.create({
                                                      context: course_factory,
                                                      filename: "exportable-test-file",
                                                      uploaded_data: File.open(cartridge_without_modules_path)
                                                    })
  end

  context "create ePub default settings" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment.open)
    end

    it "sorts content by module" do
      expect(exporter.base_template).to eq "../templates/module_sorting_template.html.erb"
      expect(exporter.templates.keys[0..4]).to eq(%i[title files toc syllabus announcements])
    end

    it "does not contain content type keys" do
      # once we have a more robust imscc we should add another test to check
      # that the keys reflect the module migration ids
      content_keys = CC::Exporter::Epub::Exporter::LINKED_RESOURCE_KEY.except("Attachment").values
      expect(content_keys.any? { |k| exporter.templates.key?(k) }).to be_falsey
    end

    it "contains a syllabus for assignments and quizzes in modules" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:syllabus)
    end

    it "contains a section for announcements" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:announcements)
    end

    it "contains a table of contents for items in modules" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:toc)
    end
  end

  context "default settings with no modules present" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment_without_modules.open)
    end

    it "falls back to sorting by content type" do
      expect(exporter.templates).not_to have_key(:modules)
    end
  end

  context "create ePub with content type sorting" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment.open, true)
    end

    it "sorts by content" do
      expect(exporter.base_template).to eq "../templates/content_sorting_template.html.erb"
    end

    it "does not contain a top-level templates key for module content" do
      expect(exporter.templates).not_to have_key(:modules)
    end

    it "contains a syllabus entry for all assignments and quizzes" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:syllabus)
    end

    it "contains a section for announcements" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:announcements)
    end

    it "contains a table of contents for all items" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates).to have_key(:toc)
    end
  end
end
