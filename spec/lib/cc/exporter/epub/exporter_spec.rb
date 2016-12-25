# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

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
      filename: 'exportable-test-file',
      uploaded_data: File.open(cartridge_path)
    })

    @attachment_without_modules = Attachment.create({
      context: course_factory,
      filename: 'exportable-test-file',
      uploaded_data: File.open(cartridge_without_modules_path)
    })

  end

  context "create ePub default settings" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment.open)
    end

    it "should sort content by module" do
      expect(exporter.base_template).to eq "../templates/module_sorting_template.html.erb"
    end

    it "should not contain content type keys" do
      # once we have a more robust imscc we should add another test to check
      # that the keys reflect the module migration ids
      content_keys = CC::Exporter::Epub::Exporter::LINKED_RESOURCE_KEY.except("Attachment").values
      expect(content_keys.any? {|k| exporter.templates.key?(k)}).to be_falsey
    end

    it "should contain a syllabus for assignments and quizzes in modules" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:syllabus)).to be_truthy
    end

    it "should contain a section for announcements" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:announcements)).to be_truthy
    end

    it "should contain a table of contents for items in modules" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:toc)).to be_truthy
    end
  end

  context "default settings with no modules present" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment_without_modules.open)
    end

    it "should fall back to sorting by content type" do
      expect(exporter.templates.key?(:modules)).to be_falsey
    end
  end

  context "create ePub with content type sorting" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment.open, true)
    end

    it "should sort by content" do
      expect(exporter.base_template).to eq "../templates/content_sorting_template.html.erb"
    end

    it "should not contain a top-level templates key for module content" do
      expect(exporter.templates.key?(:modules)).to be_falsey
    end

    it "should contain a syllabus entry for all assignments and quizzes" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:syllabus)).to be_truthy
    end

    it "should contain a section for announcements" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:announcements)).to be_truthy
    end

    it "should contain a table of contents for all items" do
      # currently only checking for the existence of the key, we'll need a more
      # robust example here once we have an .imscc example with complex content
      expect(exporter.templates.key?(:toc)).to be_truthy
    end
  end
end
