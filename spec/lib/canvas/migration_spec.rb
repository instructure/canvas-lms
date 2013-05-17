require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Migration package importers" do

  context "Detecting content package type" do
    
    def get_settings(name)
      path = File.dirname(__FILE__) + "/../../fixtures/migration/package_identifier/#{name}.zip"
      {:export_archive_path=>path}
    end
    
    supported = {
            "Old Canvas Cartridge" => [:old_canvas, CC::Importer::Canvas::Converter],
            "Canvas Cartridge" => [:canvas, CC::Importer::Canvas::Converter],
            "Common Cartridge 1.0" => ["cc1-0", CC::Importer::Standard::Converter],
            "Common Cartridge 1.1" => ["cc1-1", CC::Importer::Standard::Converter],
            "Common Cartridge 1.2" => ["cc1-2", CC::Importer::Standard::Converter],
            "QTI packages" => [:qti, Qti::Converter],
            "WebCT exports (as qti packages)" => [:webct, Qti::Converter],
    }
    
    unsupported = {
            "Blackboard packages" => [:bb_learn, :bb_learn],
            "Angel 7.3 packages" => ["angel7-3", :angel_7_3],
            "Angel 7.4 packages" => ["angel7-4", :angel_7_4],
            "D2L packages" => [:d2l, :d2l],
            "Generic IMS Content Package" => [:ims_cp, :unknown_ims_cp_package],
            "Moodle 1.9 Package" => ["moodle1-9", :moodle_1_9],
            "Moodle 2 Package" => ["moodle2", :moodle_2],
            "SCORM 1.1 Package" => ["scorm1-1", :scorm_1_1],
            "SCORM 1.2 Package" => ["scorm1-2", :scorm_1_2],
            "SCORM 1.3 Package" => ["scorm1-3", :scorm_1_3],
            "Unknown zip Package" => ["unknown", :unknown],
            "WebCT 4.1 Package" => ["webct4-1", :webct_4_1],
            "Invalid Archive" => [:invalid, :invalid_archive],
    }
    
    supported.each_pair do |key, val|
      it "should find converter for #{key}" do 
        settings = get_settings(val.first)
        Canvas::Migration::Worker::get_converter(settings).should == val.last
      end
    end
    
    unsupported.each_pair do |key, val|
      it "should correctly identify package type for #{key}" do 
        settings = get_settings(val.first)
        Canvas::Migration::PackageIdentifier.new(settings).identify_package.should == val.last
      end
    end
  end
  
  context "migrator" do
    file = File.new(File.dirname(__FILE__) + "/../../fixtures/migration/whatthebackslash.zip")
    cm = ContentMigration.new
    
    mig = Canvas::Migration::Migrator.new({:archive_file => file, :content_migration => cm}, "test")
    mig.unzip_archive
    
    cm.old_warnings_format.length.should == 1
    cm.old_warnings_format.first.tap do |w|
      w.first.should == "The content package unzipped successfully, but with a warning"
      w.last.should =~ /backslashes as path separators/
    end
  end
  
end
