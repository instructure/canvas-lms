require File.dirname(__FILE__) + '/../cc_spec_helper'

describe "Standard Common Cartridge importing" do
  before(:each) do
    @converter = get_standard_converter
    @copy_to = course_model
    @copy_to.name = "alt name"
    @copy_to.course_code = "alt name"

    @migration = Object.new
    @migration.stub!(:to_import).and_return(nil)
    @migration.stub!(:context).and_return(@copy_to)
  end
  
  it "should import modules from organization" do
    orgs = <<-XML
<organizations>
  <organization structure="rooted-hierarchy" identifier="org_1">
    <item identifier="LearningModules">
      <item identifier="m1">
        <title>some module</title>
        <item identifier="ct1" identifierref="a1">
          <title>some assignment</title>
        </item>
        <item identifier="ct2" identifierref="w1">
          <title>some page</title>
        </item>
      </item>
      <item identifier="m2">
        <title>next module</title>
      </item>
      <item identifier="m3">
        <title>attachment module</title>
        <item identifier="ct5" identifierref="f3">
          <title>Super exciting!</title>
        </item>
        <item identifier="sf1">
          <title>Sub-Folder</title>
          <item identifier="ct6" identifierref="f4">
            <title>test answers</title>
          </item>
          <item identifier="sf2">
            <title>Sub-Folder 2</title>
            <item identifier="ct7" identifierref="f5">
              <title>test answers</title>
            </item>
          </item>
        </item>
      </item>
    </item>
  </organization>
</organizations>
    XML
    
    #convert to json
    # pretend there were resources for the referenced items
    @converter.resources = {'a1' => {:type=>"webcontent"},'w1' => {:type=>"webcontent"},'f3' => {:type=>"webcontent"},'f4' => {:type=>"webcontent"},'f5' => {:type=>"webcontent"},}
    doc = Nokogiri::XML(orgs)
    hash = @converter.convert_organizations(doc)
    #pp hash
    
    # make all the fake attachments for the module items to link to
    unfiled_folder = Folder.unfiled_folder(@copy_to)
    a1 = Attachment.create!(:filename => 'a1.html', :uploaded_data => StringIO.new('a1'), :folder => unfiled_folder, :context => @copy_to)
    a1.migration_id = "a1"; a1.save
    w1 = Attachment.create!(:filename => 'w1.html', :uploaded_data => StringIO.new('w1'), :folder => unfiled_folder, :context => @copy_to)
    w1.migration_id = "w1"; w1.save
    f3 = Attachment.create!(:filename => 'f3.html', :uploaded_data => StringIO.new('f3'), :folder => unfiled_folder, :context => @copy_to)
    f3.migration_id = "f3"; f3.save
    f4 = Attachment.create!(:filename => 'f4.html', :uploaded_data => StringIO.new('f4'), :folder => unfiled_folder, :context => @copy_to)
    f4.migration_id = "f4"; f4.save
    f5 = Attachment.create!(:filename => 'f5.html', :uploaded_data => StringIO.new('f5'), :folder => unfiled_folder, :context => @copy_to)
    f5.migration_id = "f5"; f5.save
    
    #import json into new course
    hash = hash.map{|h|h.with_indifferent_access}
    ContextModule.process_migration({'modules' =>hash}, @migration)
    @copy_to.save!
    
    @copy_to.context_modules.count.should == 3
    
    mod1 = @copy_to.context_modules.find_by_migration_id("m1")
    mod1.name.should == "some module"
    mod1.content_tags.count.should == 2
    tag = mod1.content_tags.first
    tag.content_id.should == a1.id
    tag.content_type.should == 'Attachment'
    tag.indent.should == 0
    tag = mod1.content_tags.last
    tag.content_id.should == w1.id
    tag.content_type.should == 'Attachment'
    tag.indent.should == 0
    
    mod2 = @copy_to.context_modules.find_by_migration_id("m2")
    mod2.name.should == "next module"
    mod2.content_tags.count.should == 0
    
    mod3 = @copy_to.context_modules.find_by_migration_id("m3")
    mod3.name.should == "attachment module"
    mod3.content_tags.count.should == 5
    tag = mod3.content_tags.first
    tag.content_id.should == f3.id
    tag.content_type.should == 'Attachment'
    tag.indent.should == 0
    
    tag = mod3.content_tags[1]
    tag.title.should == "Sub-Folder"
    tag.content_type.should == 'ContextModuleSubHeader'
    tag.indent.should == 0
    
    tag = mod3.content_tags[2]
    tag.content_id.should == f4.id
    tag.content_type.should == 'Attachment'
    tag.indent.should == 1
    
    tag = mod3.content_tags[3]
    tag.title.should == "Sub-Folder 2"
    tag.content_type.should == 'ContextModuleSubHeader'
    tag.indent.should == 1
    
    tag = mod3.content_tags[4]
    tag.content_id.should == f5.id
    tag.content_type.should == 'Attachment'
    tag.indent.should == 2
  end
  
  it "should get all the resources" do
    resources = <<-XML
<resources>
  <resource href="a1/a1.html" identifier="a1" type="webcontent" intendeduse="assignment">
    <file href="a1/a1.html"/>
  </resource>
  <resource identifier="w1" type="webcontent" href="w1/w1.html">
    <file href="w1/w1.html"/>
  </resource>
  <resource identifier="f1" type="webcontent" href="f1/f1.txt">
    <metadata>
      <lom:lom>
        <lom:educational>
          <lom:intendedEndUserRole>
            <lom:source>IMSGLC_CC_Rolesv1p1</lom:source>
            <lom:value>Instructor</lom:value>
          </lom:intendedEndUserRole>
        </lom:educational>
      </lom:lom>
    </metadata>
    <file href="f1/f1.txt"/>
  </resource>
  <resource identifier="q1" type="imsqti_xmlv1p2/imscc_xmlv1p2/assessment" href="q1/q1.xml">
    <file href="q1/q1.xml"/>
  </resource>
  <resource identifier="wl1" type="imswl_xmlv1p2" href="wl1/weblink1.xml">
    <file href="wl1/weblink1.xml"/>
  </resource>
  <resource identifier="dt1" type="imsdt_xmlv1p2" href="dt1/discussion.xml">
    <file href="dt1/discussion.xml"/>
    <dependency identifierref="f2"/>
    <dependency identifierref="f3"/>
  </resource>
  <resource identifier="f2" type="associatedcontent/imscc_xmlv1p2/learning-application-resource" href="f2/f2.jpg">
    <file href="f2/f2.jpg"/>
  </resource>
  <resource identifier="f3" type="webcontent" href="f3/f3.jpg">
    <file href="f3/f3.jpg"/>
  </resource>
</resources>
XML
    
    doc = Nokogiri::XML(resources)
    @converter.unzipped_file_path = 'testing/'
    @converter.get_all_resources(doc)
    @converter.resources['a1'][:intended_use].should == 'assignment'
    @converter.resources['f1'][:intended_user_role].should == 'Instructor'
    @converter.resources['dt1'][:dependencies].should == ['f2', 'f3']
  end
  
end