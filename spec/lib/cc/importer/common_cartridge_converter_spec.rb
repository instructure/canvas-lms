require File.dirname(__FILE__) + '/../cc_spec_helper'

describe "Standard Common Cartridge importing" do
  before(:all) do
    archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_full_test.zip")
    unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
    @export_folder = File.join(File.dirname(archive_file_path), "cc_cc_full_test")
    @converter = CC::Importer::Standard::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    @converter.export
    @course_data = @converter.course.with_indifferent_access
    @course_data['all_files_export'] ||= {}
    @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']
  end
  
  after(:all) do
    @converter.delete_unzipped_archive
    if File.exists?(@export_folder)
      FileUtils::rm_rf(@export_folder)
    end
  end
  
  before(:each) do
     @course = course
      @migration = ContentMigration.create(:context => @course)
      @migration.migration_settings[:migration_ids_to_import] = {:copy=>{}}
      @course.import_from_migration(@course_data, nil, @migration)
  end
  
  it "should import webcontent" do
    @course.attachments.count.should == 7
    %w{I_00001_R I_00006_Media I_media_R f3 f4 f5 802ccbaffe288c33580ae91db32764ab}.each do |mig_id|
      @course.attachments.find_by_migration_id(mig_id).migration_id.should ==  mig_id
    end
  end
  
  it "should import discussion topics" do
    @course.discussion_topics.count.should == 2
    file1_id = @course.attachments.find_by_migration_id("I_media_R").id
    file2_id = @course.attachments.find_by_migration_id("I_00006_Media").id
    
    dt =  @course.discussion_topics.find_by_migration_id("I_00006_R")
    dt.message.should == %{<p>Your face is ugly. <br /><img src="/courses/#{@course.id}/files/#{file1_id}/preview" /></p>}
    dt.attachment_id = file2_id
    
    dt =  @course.discussion_topics.find_by_migration_id("I_00009_R")
    dt.message.should == %{<p>Monkeys: Go!</p>\n<ul>\n<li>\n<a href="/courses/#{@course.id}/files/#{file2_id}/preview">angry_person.jpg</a>\n</li>\n<li>\n<a href="/courses/#{@course.id}/files/#{file1_id}/preview">smiling_dog.jpg</a>\n</li>\n</ul>} 
  end

  # This also tests the WebLinks, they are just content tags and don't have their own class
  it "should import modules from organization" do
    @course.context_modules.count.should == 3
    
    mod1 = @course.context_modules.find_by_migration_id("I_00000")
    mod1.name.should == "Your Mom, Research, & You"
    #mod1.content_tags.count.should == 5
    #mod1.content_tags.each{|ct|puts ct.inspect}
    tag = mod1.content_tags[0]
    tag.content_type.should == 'Attachment'
    tag.content_id.should == @course.attachments.find_by_migration_id("I_00001_R").id
    tag.indent.should == 0
    tag = mod1.content_tags[1]
    tag.content_type.should == 'ContextModuleSubHeader'
    tag.title.should == "Study Guide"
    tag.indent.should == 0
      # todo - once assessments are imported
      #tag = mod1.content_tags[2]
      #tag.title.should == "Pretest"
      #tag.content_type.should == 'AssessmentSomething'
      #tag.indent.should == 1
    tag = mod1.content_tags[2]
    tag.content_type.should == 'ExternalUrl'
    tag.title.should == "Wikipedia - Your Mom"
    tag.url.should == "http://en.wikipedia.org/wiki/Maternal_insult"
    tag.indent.should == 0
    
    mod1 = @course.context_modules.find_by_migration_id("m2")
    mod1.name.should == "Attachment module"
    mod1.content_tags.count.should == 5
    tag = mod1.content_tags[0]
    tag.content_type.should == 'Attachment'
    tag.content_id.should == @course.attachments.find_by_migration_id("f3").id
    tag.indent.should == 0
    tag = mod1.content_tags[1]
    tag.content_type.should == 'ContextModuleSubHeader'
    tag.title.should == "Sub-Folder"
    tag.indent.should == 0
      tag = mod1.content_tags[2]
      tag.content_type.should == 'Attachment'
      tag.content_id.should == @course.attachments.find_by_migration_id("f4").id
      tag.indent.should == 1
      tag = mod1.content_tags[3]
      tag.content_type.should == 'ContextModuleSubHeader'
      tag.title.should == "Sub-Folder 2"
      tag.indent.should == 1
        tag = mod1.content_tags[4]
        tag.content_type.should == 'Attachment'
        tag.content_id.should == @course.attachments.find_by_migration_id("f5").id
        tag.indent.should == 2
    
    mod1 = @course.context_modules.find_by_migration_id("m3")
    mod1.name.should == "Misc Module"
    mod1.content_tags.count.should == 3
    tag = mod1.content_tags[0]
    tag.content_type.should == 'ExternalUrl'
    tag.title.should == "Wikipedia - Sigmund Freud"
    tag.url.should == "http://en.wikipedia.org/wiki/Sigmund_Freud"
    tag.indent.should == 0
    tag = mod1.content_tags[1]
    tag.content_type.should == 'DiscussionTopic'
    tag.title.should == "Talk about the issues"
    tag.content_id.should == @course.discussion_topics.find_by_migration_id("I_00009_R").id
    tag.indent.should == 0
    tag = mod1.content_tags[2]
    tag.content_type.should == 'ContextExternalTool'
    tag.title.should == "BLTI Test"
    tag.url.should == "http://www.imsglobal.org/developers/BLTI/tool.php"
    tag.indent.should == 0
    
  end

  it "should get all the resources" do
    @converter.resources['f4'][:intended_use].should == 'assignment'
    @converter.resources['I_00004_R'][:intended_user_role].should == 'Instructor'
    @converter.resources['I_00006_R'][:dependencies].should == ['I_00006_Media', 'I_media_R']
    @converter.resources_by_type("webcontent").length.should == 5
    @converter.resources_by_type("webcontent", "associatedcontent").length.should == 6
    @converter.resources_by_type("imsdt").length.should == 2
    @converter.resources_by_type("imswl").length.should == 3
  end
  
  it "should import external tools" do
    @course.context_external_tools.count.should == 1
    et = @course.context_external_tools.find_by_migration_id("I_00010_R")
    et.name.should == "BLTI Test"
    et.url.should == 'http://www.imsglobal.org/developers/BLTI/tool.php'
    et.settings[:custom_fields].should == {"key1"=>"value1", "key2"=>"value2"}
    et.settings[:vendor_extensions].should == [{:platform=>"my.lms.com", :custom_fields=>{"key"=>"value"}}, {:platform=>"your.lms.com", :custom_fields=>{"key"=>"value", "key2"=>"value2"}}]
    @migration.warnings.member?("The security parameters for the external tool \"#{et.name}\" need to be set in Course Settings.").should be_true
  end

end