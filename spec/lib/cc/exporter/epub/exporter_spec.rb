# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

describe "Exporter" do
  include CC::Exporter::Epub

  before(:once) do
    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
    end

    @attachment = Attachment.create({
      context: course,
      filename: 'exortable-test-file',
      uploaded_data: File.open(cartridge_path)
    })
  end

  context "create ePub default settings" do
    let(:exporter) do
      CC::Exporter::Epub::Exporter.new(@attachment.open)
    end

    it "should sort content by module" do
      expect(exporter.base_template).to eq "../templates/module_sorting_template.html.erb"
    end

    it "should contain a top-level templates key for module content" do
      expect(exporter.templates.key?(:modules)).to be_truthy
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
  end
end
