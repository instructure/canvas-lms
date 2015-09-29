# coding: utf-8
require File.expand_path(File.dirname(__FILE__) + '/../../cc_spec_helper')
require 'nokogiri'

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
      ExportableTest.new.convert_to_epub
    end

    let(:epub) do
      File.open(epub_path)
    end

    it "should create an epub file" do
      expect(epub).not_to be_nil
    end

    after do
      File.delete(epub_path) if File.exist?(epub_path)
    end
  end

end
