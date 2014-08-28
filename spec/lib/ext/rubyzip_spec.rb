# coding: utf-8

require 'spec_helper'

describe "rubyzip encoding fix patch" do
  before(:all) do
    @utf8_name = "utf-8 molé"
    @ascii_name = "ascii mol\xE9".force_encoding('ASCII-8BIT')

    @tmpfile = Tempfile.new('datafile')
    @tmpfile.write('some data')
    @tmpfile.close

    tmpzipfile = Tempfile.new('zipfile')
    @zip_path = tmpzipfile.path
    tmpzipfile.close!
    Zip::File.open(@zip_path, true) do |arch|
      arch.add @utf8_name, @tmpfile.path
      arch.add @ascii_name, @tmpfile.path
    end
  end

  after(:all) do
    @tmpfile.unlink
    File.unlink @zip_path
  end

  context "with zip file" do
    before(:each) do
      @arch = Zip::File.open(@zip_path, 'r')
    end

    after(:each) do
      @arch.close
    end

    describe "entries" do
      it "should return UTF-8 names in UTF-8 encoding" do
        @arch.entries.map(&:name).select { |filename| filename.encoding.to_s == 'UTF-8' }.should eql [@utf8_name]
      end

      it "should return non-UTF-8 names in ASCII-8BIT encoding" do
        @arch.entries.map(&:name).select { |filename| filename.encoding.to_s == 'ASCII-8BIT' }.should eql [@ascii_name]
      end
    end

    describe "find_entry" do
      it "should find a UTF-8 name" do
        @arch.find_entry(@utf8_name).should_not be_nil
      end

      it "should find a non-UTF-8 name" do
        @arch.find_entry(@ascii_name).should_not be_nil
      end
    end
  end
end
