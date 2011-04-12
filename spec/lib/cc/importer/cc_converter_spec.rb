require File.dirname(__FILE__) + '/../cc_spec_helper'

describe "Common Cartridge importing" do
  before(:each) do
    @converter = get_cc_converter
    @copy_from = course_model
    @from_teacher = @user
    @copy_to = course_model

    exporter = CC::CCExporter.new(nil, :course=>@copy_from, :user=>@from_teacher)
    manifest = CC::Manifest.new(exporter)
    @resource = CC::Resource.new(manifest, nil)
    @migration = Object.new
    @migration.stub!(:to_import).and_return(nil)
    @migration.stub!(:context).and_return(@copy_to)
  end

  it "should import course settings" do
    #set all the possible values to non-default values
    @copy_from.start_at = 5.minutes.ago
    @copy_from.conclude_at = 1.month.from_now
    @copy_from.is_public = false
    @copy_from.name = "haha copy from test &amp;"
    @copy_from.course_code = 'something funny'
    @copy_from.publish_grades_immediately = false
    @copy_from.allow_student_wiki_edits = true
    @copy_from.allow_student_assignment_edits = true
    @copy_from.hashtag = 'oi'
    @copy_from.show_public_context_messages = false
    @copy_from.allow_student_forum_attachments = false
    @copy_from.default_wiki_editing_roles = 'teachers'
    @copy_from.allow_student_organized_groups = false
    @copy_from.default_view = 'modules'
    @copy_from.show_all_discussion_entries = false
    @copy_from.open_enrollment = true
    @copy_from.storage_quota = 444
    @copy_from.allow_wiki_comments = true
    @copy_from.turnitin_comments = "Don't plagiarize"
    @copy_from.self_enrollment = true
    @copy_from.license = "cc_by_nc_nd"

    @copy_from.save!

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_course_settings("1", builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_course_settings(doc)
    #import json into new course
    hash = hash.with_indifferent_access
    @copy_to.import_settings_from_migration({:course_settings=>hash})
    @copy_to.save!

    #compare settings
    @copy_to.conclude_at.to_i.should == @copy_from.conclude_at.to_i
    @copy_to.start_at.to_i.should == @copy_from.start_at.to_i
    atts = Course.clonable_attributes
    atts -= [:start_at, :conclude_at, :grading_standard_id, :hidden_tabs, :tab_configuration, :syllabus_body]
    atts.each do |att|
      @copy_to.send(att).should == @copy_from.send(att)
    end
  end

  it "should convert assignment groups" do
    ag1 = @copy_from.assignment_groups.new
    ag1.name = "Boring assignments"
    ag1.position = 1
    ag1.group_weight = 77.7
    ag1.save!
    ag2 = @copy_from.assignment_groups.new
    ag2.name = "Super not boring assignments"
    ag2.position = 2
    ag2.group_weight = 20
    ag2.save!
    a = ag2.assignments.new
    a.title = "Can't drop me"
    a.context = @copy_from
    a.save!
    ag2.rules = "drop_lowest:2\ndrop_highest:5\nnever_drop:%s\n" % a.id
    ag2.save!

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_assignment_groups(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_assignment_groups(doc)
    #import json into new course
    @copy_to.assignment_group_no_drop_assignments = {}
    AssignmentGroup.process_migration({'assignment_groups'=>hash}, @migration)
    @copy_to.save!

    #compare settings
    ag1_2 = @copy_to.assignment_groups.find_by_migration_id(CC::CCHelper.create_key(ag1))
    ag1_2.name.should == ag1.name
    ag1_2.position.should == ag1.position
    ag1_2.group_weight.should == ag1.group_weight
    ag1_2.rules.should == ag1.rules

    ag2_2 = @copy_to.assignment_groups.find_by_migration_id(CC::CCHelper.create_key(ag2))
    ag2_2.name.should == ag2.name
    ag2_2.position.should == ag2.position
    ag2_2.group_weight.should == ag2.group_weight
    ag2_2.rules.should == "drop_lowest:2\ndrop_highest:5\n"

    #import assignment
    hash = {:migration_id=>CC::CCHelper.create_key(a),
            :title=>a.title,
            :assignment_group_migration_id=>CC::CCHelper.create_key(ag2)}
    Assignment.import_from_migration(hash, @copy_to)
    
    ag2_2.reload
    ag2_2.assignments.count.should == 1
    a_2 = ag2_2.assignments.first 
    ag2_2.rules.should == "drop_lowest:2\ndrop_highest:5\nnever_drop:%s\n" % a_2.id
  end

  it "should convert external tools" do
    tool1 = @copy_from.context_external_tools.new
    tool1.url = 'http://instructure.com'
    tool1.name = 'instructure'
    tool1.description = "description of boring"
    tool1.privacy_level = 'name_only'
    tool1.consumer_key = 'haha'
    tool1.shared_secret = "don't share me"
    tool1.save!
    tool2 = @copy_from.context_external_tools.new
    tool2.domain = 'example.com'
    tool2.name = 'example'
    tool2.description = "example.com? That's the best you could come up with?"
    tool2.privacy_level = 'anonymous'
    tool2.consumer_key = 'haha'
    tool2.shared_secret = "don't share me"
    tool2.save!

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_external_tools(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_external_tools(doc)
    #import json into new course
    ContextExternalTool.process_migration({'external_tools'=>hash}, @migration)
    @copy_to.save!

    #compare settings
    t1 = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(tool1))
    t1.url.should == tool1.url
    t1.name.should == tool1.name
    t1.description.should == tool1.description
    t1.workflow_state.should == tool1.workflow_state
    t1.domain.should == nil
    t1.consumer_key.should == 'fake'
    t1.shared_secret.should == 'fake'

    t2 = @copy_to.context_external_tools.find_by_migration_id(CC::CCHelper.create_key(tool2))
    t2.domain.should == tool2.domain
    t2.url.should == nil
    t2.name.should == tool2.name
    t2.description.should == tool2.description
    t2.workflow_state.should == tool2.workflow_state
    t2.consumer_key.should == 'fake'
    t2.shared_secret.should == 'fake'
  end

end
