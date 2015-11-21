# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')

describe "Exportable" do
  class ExportableTest
    include CC::Exporter::Epub::Exportable

    def attachment
      @_attachment ||= Attachment.create({
        context: course,
        filename: 'exortable-test-file',
        uploaded_data: File.open(cartridge_path)
      })
    end

    def cartridge_path
      File.join(File.dirname(__FILE__), "/../../../../fixtures/migration/unicode-filename-test-export.imscc")
    end
  end

  context "#convert_to_epub" do
    let(:epub_path) do
      ExportableTest.new.convert_to_epub.first
    end

    let(:zip_path) do
      ExportableTest.new.convert_to_epub.last
    end

    let(:epub) do
      File.open(epub_path)
    end

    let(:zip) do
      File.open(zip_path)
    end

    it "should create an epub file" do
      expect(epub).not_to be_nil
    end

    it "should create a zip file" do
      expect(zip).not_to be_nil
    end

    after do
      File.delete(epub_path) if File.exist?(epub_path)
      File.delete(zip_path) if File.exist?(zip_path)
    end
  end

end
