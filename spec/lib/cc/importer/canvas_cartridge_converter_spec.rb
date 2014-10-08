require File.expand_path(File.dirname(__FILE__) + '/../cc_spec_helper')

describe "Canvas Cartridge importing" do
  before(:each) do
    @converter = get_cc_converter
    @copy_from = course_model
    @from_teacher = @user
    @copy_to = course_model
    @copy_to.conclude_at = nil
    @copy_to.start_at = nil
    @copy_to.name = "alt name"
    @copy_to.course_code = "alt name"

    @exporter = CC::CCExporter.new(nil, :course=>@copy_from, :user=>@from_teacher, :for_course_copy => true)
    manifest = CC::Manifest.new(@exporter)
    @resource = CC::Resource.new(manifest, nil)
    @migration = ContentMigration.new
    @migration.context = @copy_to
    @migration.save
  end

  it "should import assignment groups" do
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

    ag3 = @copy_from.assignment_groups.create!(:name => 'group to import implicitly')
    ag4 = @copy_from.assignment_groups.create!(:name => 'group to not import implicitly')

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_assignment_groups(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    ag_hash = @converter.convert_assignment_groups(doc)
    data = {
      'assignment_groups' => ag_hash,
      'assignments' => [
          # just a dummy assignment, but will implicitly import ag3
          {'migration_id' => 42, 'assignment_group_migration_id' => CC::CCHelper.create_key(ag3)},
          {'migration_id' => 43, 'assignment_group_migration_id' => CC::CCHelper.create_key(ag4)}
      ]
    }

    @migration.migration_ids_to_import = {
      :copy => {
        'assignments' => {42 => true},
        'assignment_groups' => {
          CC::CCHelper.create_key(ag1) => true,
          CC::CCHelper.create_key(ag2) => true,
        }
      }
    }
    expect(@migration.import_object?('assignment_group', CC::CCHelper.create_key(ag3))).to eq false
    expect(@migration.import_object?('assignment_group', CC::CCHelper.create_key(ag4))).to eq false

    #import json into new course
    @copy_to.assignment_group_no_drop_assignments = {}
    Importers::AssignmentGroupImporter.process_migration(data, @migration)
    @copy_to.save!

    #compare settings
    ag1_2 = @copy_to.assignment_groups.where(migration_id: CC::CCHelper.create_key(ag1)).first
    expect(ag1_2.name).to eq ag1.name
    expect(ag1_2.position).to eq ag1.position
    expect(ag1_2.group_weight).to eq ag1.group_weight
    expect(ag1_2.rules).to eq ag1.rules

    ag2_2 = @copy_to.assignment_groups.where(migration_id: CC::CCHelper.create_key(ag2)).first
    expect(ag2_2.name).to eq ag2.name
    expect(ag2_2.position).to eq ag2.position
    expect(ag2_2.group_weight).to eq ag2.group_weight
    expect(ag2_2.rules).to eq "drop_lowest:2\ndrop_highest:5\n"

    expect(@copy_to.assignment_groups.where(migration_id: CC::CCHelper.create_key(ag3))).to be_exists
    expect(@copy_to.assignment_groups.where(migration_id: CC::CCHelper.create_key(ag4))).not_to be_exists

    #import assignment
    hash = {:migration_id=>CC::CCHelper.create_key(a),
            :title=>a.title,
            :assignment_group_migration_id=>CC::CCHelper.create_key(ag2)}
    Importers::AssignmentImporter.import_from_migration(hash, @copy_to)

    ag2_2.reload
    expect(ag2_2.assignments.count).to eq 1
    a_2 = ag2_2.assignments.first
    expect(ag2_2.rules).to eq "drop_lowest:2\ndrop_highest:5\nnever_drop:%s\n" % a_2.id
  end

  it "should import external tools" do
    tool1 = @copy_from.context_external_tools.new
    tool1.url = 'http://instructure.com'
    tool1.name = 'instructure'
    tool1.description = "description of boring"
    tool1.privacy_level = 'name_only'
    tool1.consumer_key = 'haha'
    tool1.shared_secret = "don't share me"
    tool1.tool_id = "test_tool"
    tool1.settings[:custom_fields] = {"key1" => "value1", "key2" => "value2"}
    tool1.settings[:user_navigation] = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra'}
    tool1.settings[:course_navigation] = {:text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :default => 'disabled', :visibility => 'members', :extra => 'extra', :custom_fields => {"key3" => "value3"}}
    tool1.settings[:account_navigation] = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :extra => 'extra'}
    tool1.settings[:resource_selection] = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :extra => 'extra'}
    tool1.settings[:editor_button] = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :icon_url => "http://www.example.com", :extra => 'extra'}
    tool1.settings[:homework_submission] = {:url => "http://www.example.com", :text => "hello", :labels => {'en' => 'hello', 'es' => 'hola'}, :selection_width => 100, :selection_height => 50, :extra => 'extra'}
    tool1.settings[:icon_url] = "http://www.example.com/favicon.ico"
    tool1.save!
    tool2 = @copy_from.context_external_tools.new
    tool2.domain = 'example.com'
    tool2.name = 'example'
    tool2.description = "example.com? That's the best you could come up with?"
    tool2.privacy_level = 'anonymous'
    tool2.consumer_key = 'haha'
    tool2.shared_secret = "don't share me"
    tool2.settings[:vendor_extensions] = [{:platform=>"my.lms.com", :custom_fields=>{"key"=>"value"}}]
    tool2.save!

    #export to xml
    @exporter.for_course_copy = false
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_blti_link(tool1, builder)
    builder2 = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_blti_link(tool2, builder2)

    #convert to json
    doc1 = Nokogiri::XML(builder.target!)
    lti_converter = CC::Importer::BLTIConverter.new
    tool1_hash = lti_converter.convert_blti_link(doc1)
    tool1_hash['migration_id'] = CC::CCHelper.create_key(tool1)
    doc2 = Nokogiri::XML(builder2.target!)
    tool2_hash = lti_converter.convert_blti_link(doc2)
    tool2_hash['migration_id'] = CC::CCHelper.create_key(tool2)
    #import json into new course
    Importers::ContextExternalToolImporter.process_migration({'external_tools'=>[tool1_hash, tool2_hash]}, @migration)
    @copy_to.save!

    #compare settings
    t1 = @copy_to.context_external_tools.where(migration_id: CC::CCHelper.create_key(tool1)).first
    expect(t1.url).to eq tool1.url
    expect(t1.name).to eq tool1.name
    expect(t1.description).to eq tool1.description
    expect(t1.workflow_state).to eq tool1.workflow_state
    expect(t1.domain).to eq nil
    expect(t1.consumer_key).to eq 'fake'
    expect(t1.shared_secret).to eq 'fake'
    expect(t1.tool_id).to eq 'test_tool'
    expect(t1.settings[:icon_url]).to eq 'http://www.example.com/favicon.ico'
    [:user_navigation, :course_navigation, :account_navigation].each do |type|
      expect(t1.settings[type][:text]).to eq "hello"
      expect(t1.settings[type][:labels][:en]).to eq 'hello'
      expect(t1.settings[type][:labels]['es']).to eq 'hola'
      if type == :course_navigation
        expect(t1.settings[type][:default]).to eq 'disabled'
        expect(t1.settings[type][:visibility]).to eq 'members'
        expect(t1.settings[type][:custom_fields]).to eq({"key3" => "value3"})
        expect(t1.settings[type].keys.map(&:to_s).sort).to eq ['custom_fields', 'default', 'labels', 'text', 'visibility']
      else
        expect(t1.settings[type][:url]).to eq "http://www.example.com"
        expect(t1.settings[type].keys.map(&:to_s).sort).to eq ['labels', 'text', 'url']
      end
    end
    [:resource_selection, :editor_button, :homework_submission].each do |type|
      expect(t1.settings[type][:url]).to eq "http://www.example.com"
      expect(t1.settings[type][:text]).to eq "hello"
      expect(t1.settings[type][:labels][:en]).to eq 'hello'
      expect(t1.settings[type][:labels]['es']).to eq 'hola'
      expect(t1.settings[type][:selection_width]).to eq 100
      expect(t1.settings[type][:selection_height]).to eq 50
      if type == :editor_button
        expect(t1.settings[type][:icon_url]).to eq 'http://www.example.com'
        expect(t1.settings[type].keys.map(&:to_s).sort).to eq ['icon_url', 'labels', 'selection_height', 'selection_width', 'text', 'url']
      else
        expect(t1.settings[type].keys.map(&:to_s).sort).to eq ['labels', 'selection_height', 'selection_width', 'text', 'url']
      end
    end
    expect(t1.settings[:custom_fields]).to eq({"key1"=>"value1", "key2"=>"value2"})
    expect(t1.settings[:vendor_extensions]).to eq []

    t2 = @copy_to.context_external_tools.where(migration_id: CC::CCHelper.create_key(tool2)).first
    expect(t2.domain).to eq tool2.domain
    expect(t2.url).to eq nil
    expect(t2.name).to eq tool2.name
    expect(t2.description).to eq tool2.description
    expect(t2.workflow_state).to eq tool2.workflow_state
    expect(t2.consumer_key).to eq 'fake'
    expect(t2.shared_secret).to eq 'fake'
    expect(t2.tool_id).to be_nil
    expect(t2.settings[:icon_url]).to be_nil
    expect(t2.settings[:user_navigation]).to be_nil
    expect(t2.settings[:course_navigation]).to be_nil
    expect(t2.settings[:account_navigation]).to be_nil
    expect(t2.settings[:resource_selection]).to be_nil
    expect(t2.settings[:editor_button]).to be_nil
    expect(t2.settings[:homework_submission]).to be_nil
    expect(t2.settings.keys.map(&:to_s).sort).to eq ['custom_fields', 'vendor_extensions']
    expect(t2.settings[:vendor_extensions]).to eq [{'platform'=>"my.lms.com", 'custom_fields'=>{"key"=>"value"}}]
    expect(t2.settings[:vendor_extensions][0][:platform]).to eq 'my.lms.com'
    expect(t2.settings[:vendor_extensions][0][:custom_fields]).to eq({"key"=>"value"})
    expect(t2.settings[:custom_fields]).to eq({})
  end

  it "should import multiple module links to same external tool" do
    tool_from = @copy_from.context_external_tools.create!(:url => "http://example.com.ims/lti", :name => "test", :consumer_key => "key", :shared_secret => "secret")
    tool_mig_id = CC::CCHelper.create_key(tool_from)
    tool_to = @copy_to.context_external_tools.create(:url => "http://example.com.ims/lti", :name => "test", :consumer_key => "key", :shared_secret => "secret")
    tool_to.migration_id = tool_mig_id
    tool_to.save!

    mod1 = @copy_from.context_modules.create!(:name => "some module")

    tag = mod1.add_item({:title => "test", :type => 'context_external_tool', :url => "http://example.com.ims/lti", :new_tab => true})
    tag = mod1.add_item({:title => "test2", :type => 'context_external_tool', :url => "http://example.com.ims/lti"})
    mod1.save!

    expect(mod1.content_tags.count).to eq 2

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_module_meta(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_modules(doc)
    #import json into new course
    hash[0] = hash[0].with_indifferent_access
    Importers::ContextModuleImporter.process_migration({'modules'=>hash}, @migration)
    @copy_to.save!

    mod1_2 = @copy_to.context_modules.where(migration_id: CC::CCHelper.create_key(mod1)).first
    expect(mod1_2.content_tags.count).to eq mod1.content_tags.count
    tag = mod1_2.content_tags.first
    expect(tag.content_id).to eq tool_to.id
    expect(tag.content_type).to eq 'ContextExternalTool'
    expect(tag.new_tab).to eq true
    expect(tag.url).to eq "http://example.com.ims/lti"
    tag = mod1_2.content_tags.last
    expect(tag.content_id).to eq tool_to.id
    expect(tag.new_tab).not_to eq true
    expect(tag.content_type).to eq 'ContextExternalTool'
    expect(tag.url).to eq "http://example.com.ims/lti"
  end

  it "should import external feeds" do
    ef = @copy_from.external_feeds.new
    ef.url = "http://search.twitter.com/search.atom?q=instructure"
    ef.title = "Instructure on Twitter"
    ef.feed_type = "rss/atom"
    ef.feed_purpose = 'announcements'
    ef.verbosity = 'full'
    ef.header_match = "canvas"
    ef.save!

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_external_feeds(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_external_feeds(doc)
    #import json into new course
    Importers::ExternalFeedImporter.process_migration({'external_feeds'=>hash}, @migration)
    @copy_to.save!

    ef_2 = @copy_to.external_feeds.where(migration_id: CC::CCHelper.create_key(ef)).first
    expect(ef_2.url).to eq ef.url
    expect(ef_2.title).to eq ef.title
    expect(ef_2.feed_type).to eq ef.feed_type
    expect(ef_2.feed_purpose).to eq ef.feed_purpose
    expect(ef_2.verbosity).to eq ef.verbosity
    expect(ef_2.header_match).to eq ef.header_match
  end

  it "should import grading standards" do
    gs = @copy_from.grading_standards.new
    gs.title = "Standard eh"
    gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
    gs.save!

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_grading_standards(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_grading_standards(doc)
    #import json into new course
    Importers::GradingStandardImporter.process_migration({'grading_standards'=>hash}, @migration)
    @copy_to.save!

    gs_2 = @copy_to.grading_standards.where(migration_id: CC::CCHelper.create_key(gs)).first
    expect(gs_2.title).to eq gs.title
    expect(gs_2.data).to eq gs.data
  end

  it "should import v1 grading standards" do
    doc = Nokogiri::XML(%{
<?xml version="1.0" encoding="UTF-8"?>
<gradingStandards xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://canvas.instructure.com/xsd/cccv1p0" xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 http://canvas.instructure.com/xsd/cccv1p0.xsd">
  <gradingStandard identifier="i293372c956d13a7d48d913a7d971e35d" version="1">
    <title>Standard eh</title>
    <data>[["A", 1], ["A-", 0.92], ["B+", 0.88], ["B", 0.84], ["B!-", 0.82], ["C+", 0.79], ["C", 0.76], ["C-", 0.73], ["D+", 0.69], ["D", 0.66], ["D-", 0.63], ["F", 0.6]]</data>
  </gradingStandard>
</gradingStandards>
    })
    hash = @converter.convert_grading_standards(doc)
    #import json into new course
    Importers::GradingStandardImporter.process_migration({'grading_standards'=>hash}, @migration)
    @copy_to.save!

    gs_2 = @copy_to.grading_standards.last
    expect(gs_2.title).to eq "Standard eh"
    expect(gs_2.data).to eq [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
  end

  def create_learning_outcome
    lo = @copy_from.created_learning_outcomes.new
    lo.context = @copy_from
    lo.short_description = "Lone outcome"
    lo.description = "<p>Descriptions are boring</p>"
    lo.workflow_state = 'active'
    lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
    lo.save!
    default = @copy_from.root_outcome_group
    default.add_outcome(lo)
    lo
  end

  def import_learning_outcomes
    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_learning_outcomes(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    data = @converter.convert_learning_outcomes(doc)
    data = data.map{|h| h.with_indifferent_access}

    #import json into new course
    Importers::LearningOutcomeImporter.process_migration({'learning_outcomes'=>data}, @migration)
    @copy_to.save!
  end

  it "should import learning outcomes" do
    lo = create_learning_outcome

    lo_g = @copy_from.learning_outcome_groups.new
    lo_g.context = @copy_from
    lo_g.title = "Lone outcome group"
    lo_g.description = "<p>Groupage</p>"
    lo_g.save!

    lo_g2 = @copy_from.learning_outcome_groups.new
    lo_g2.context = @copy_from
    lo_g2.title = "Empty Group"
    lo_g2.save!

    lo2 = @copy_from.created_learning_outcomes.new
    lo2.context = @copy_from
    lo2.short_description = "outcome in group"
    lo2.workflow_state = 'active'
    lo2.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
    lo2.save!
    lo_g.add_outcome(lo2)

    default = @copy_from.root_outcome_group
    default.adopt_outcome_group(lo_g)
    default.adopt_outcome_group(lo_g2)

    import_learning_outcomes

    lo_2 = @copy_to.created_learning_outcomes.where(migration_id: CC::CCHelper.create_key(lo)).first
    expect(lo_2.short_description).to eq lo.short_description
    expect(lo_2.description).to eq lo.description
    expect(lo_2.data.with_indifferent_access).to eq lo.data.with_indifferent_access

    lo2_2 = @copy_to.created_learning_outcomes.where(migration_id: CC::CCHelper.create_key(lo2)).first
    expect(lo2_2.short_description).to eq lo2.short_description
    expect(lo2_2.description).to eq lo2.description
    expect(lo2_2.data.with_indifferent_access).to eq lo2.data.with_indifferent_access

    lo_g_2 = @copy_to.learning_outcome_groups.where(migration_id: CC::CCHelper.create_key(lo_g)).first
    expect(lo_g_2.title).to eq lo_g.title
    expect(lo_g_2.description).to eq lo_g.description
    expect(lo_g_2.child_outcome_links.length).to eq 1

    lo_g2_2 = @copy_to.learning_outcome_groups.where(migration_id: CC::CCHelper.create_key(lo_g2)).first
    expect(lo_g2_2.title).to eq lo_g2.title
    expect(lo_g2_2.description).to eq lo_g2.description
    expect(lo_g2_2.child_outcome_links.length).to eq 0
  end

  it "should import rubrics" do
    # create an outcome to reference
    lo = create_learning_outcome
    import_learning_outcomes

    rubric = @copy_from.rubrics.new
    rubric.title = "Rubric"
    rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}, {:criterion_id=>"309_343", :points=>0, :description=>"Does Not Meet Expectations", :id=>"309_9962", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
    rubric.save!
    rubric.associate_with(@copy_from, @copy_from)
    rubric.associate_with(@copy_from, @copy_from)

    #create a rubric in a different course to associate with
    new_course = course_model
    rubric2 = new_course.rubrics.build
    rubric2.title = "Rubric from different course"
    rubric2.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}, {:criterion_id=>"309_343", :points=>0, :description=>"Does Not Meet Expectations", :id=>"309_9962", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
    rubric2.save!

    assoc = RubricAssociation.create!(:context => @copy_from, :rubric => rubric2, :association_object => @copy_from, :title => rubric2.title, :purpose => 'bookmark')

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_rubrics(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_rubrics(doc)
    #import json into new course
    hash[0] = hash[0].with_indifferent_access
    hash[1] = hash[1].with_indifferent_access
    Importers::RubricImporter.process_migration({'rubrics'=>hash}, @migration)
    @copy_to.save!

    expect(@copy_to.rubric_associations.count).to eq 2
    lo_2 = @copy_to.created_learning_outcomes.where(migration_id: CC::CCHelper.create_key(lo)).first
    expect(lo_2).not_to be_nil
    rubric_2 = @copy_to.rubrics.where(migration_id: CC::CCHelper.create_key(rubric)).first
    expect(rubric_2.title).to eq rubric.title
    expect(rubric_2.data[1][:learning_outcome_id]).to eq lo_2.id

    rubric2_2 = @copy_to.rubrics.where(migration_id: CC::CCHelper.create_key(rubric2)).first
    expect(rubric2_2.title).to eq rubric2.title
  end

  it "should import modules" do
    mod1 = @copy_from.context_modules.create!(:name => "some module", :unlock_at => 1.week.from_now, :require_sequential_progress => true)
    mod2 = @copy_from.context_modules.create!(:name => "next module")
    mod3 = @copy_from.context_modules.create!(:name => "url module")
    mod4 = @copy_from.context_modules.create!(:name => "attachment module")
    mod2.prerequisites = [{:type=>"context_module", :name=>mod1.name, :id=>mod1.id}]
    mod2.require_sequential_progress = true
    mod2.save!

    asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
    tag = mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
    c_reqs = []
    c_reqs << {:type => 'min_score', :min_score => 5, :id => tag.id}
    page = @copy_from.wiki.wiki_pages.create!(:title => "some page")
    tag = mod1.add_item({:id => page.id, :type => 'wiki_page'})
    c_reqs << {:type => 'must_view', :id => tag.id}
    mod1.completion_requirements = c_reqs
    mod1.save!

    #Add assignment/page to @copy_to so the module can reference them on import
    asmnt2 = @copy_to.assignments.create(:title => "some assignment")
    asmnt2.migration_id = CC::CCHelper.create_key(asmnt1)
    asmnt2.save!
    page2 = @copy_to.wiki.wiki_pages.create(:title => "some page")
    page2.migration_id = CC::CCHelper.create_key(page)
    page2.save!

    mod3.add_item({ :title => 'Example 1', :type => 'external_url', :url => 'http://a.example.com/' })
    mod3.add_item({ :title => 'Example 2', :type => 'external_url', :url => 'http://b.example.com/' })
    ct = mod3.add_item({ :title => 'Example 3', :type => 'external_url', :url => 'http://b.example.com/with%20space' })
    ContentTag.where(:id => ct).update_all(:url => "http://b.example.com/with space")

    # attachments are migrated with just their filename as display_name,
    # if a content tag has a different title the display_name should not update
    att = Attachment.create!(:filename => 'boring.txt', :display_name => "Super exciting!", :uploaded_data => StringIO.new('even more boring'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
    expect(att.display_name).to eq "Super exciting!"
    # create @copy_to attachment with normal display_name
    att_2 = Attachment.create!(:filename => 'boring.txt', :uploaded_data => StringIO.new('even more boring'), :folder => Folder.unfiled_folder(@copy_to), :context => @copy_to)
    att_2.migration_id = CC::CCHelper.create_key(att)
    att_2.save
    att_tag = mod4.add_item({:title => "A different title just because", :type => "attachment", :id => att.id})

    # create @copy_to module link with different name than attachment
    att_3 = Attachment.create!(:filename => 'filename.txt', :uploaded_data => StringIO.new('even more boring'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
    att_3.migration_id = CC::CCHelper.create_key(att_3)
    att_3.save
    mod4.add_item({:title => "test answers", :type => "attachment", :id => att_3.id})

    att_3_2 = Attachment.create!(:filename => 'filename.txt', :uploaded_data => StringIO.new('even more boring'), :folder => Folder.unfiled_folder(@copy_to), :context => @copy_to)
    att_3_2.migration_id = CC::CCHelper.create_key(att_3)
    att_3_2.save

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_module_meta(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_modules(doc)
    #import json into new course
    hash[0] = hash[0].with_indifferent_access
    hash[1] = hash[1].with_indifferent_access
    hash[2] = hash[2].with_indifferent_access
    hash[3] = hash[3].with_indifferent_access
    Importers::ContextModuleImporter.process_migration({'modules'=>hash}, @migration)
    @copy_to.save!

    mod1_2 = @copy_to.context_modules.where(migration_id: CC::CCHelper.create_key(mod1)).first
    expect(mod1_2.name).to eq mod1.name
    expect(mod1_2.unlock_at.to_i).to eq mod1.unlock_at.to_i
    expect(mod1_2.require_sequential_progress).to eq mod1.require_sequential_progress
    expect(mod1_2.content_tags.count).to eq mod1.content_tags.count
    tag = mod1_2.content_tags.first
    expect(tag.content_id).to eq asmnt2.id
    expect(tag.content_type).to eq 'Assignment'
    expect(tag.indent).to eq 1
    cr1 = mod1_2.completion_requirements.find {|cr| cr[:id] == tag.id}
    expect(cr1[:type]).to eq 'min_score'
    expect(cr1[:min_score]).to eq 5
    tag = mod1_2.content_tags.last
    expect(tag.content_id).to eq page2.id
    expect(tag.content_type).to eq 'WikiPage'
    cr2 = mod1_2.completion_requirements.find {|cr| cr[:id] == tag.id}
    expect(cr2[:type]).to eq 'must_view'

    mod2_2 = @copy_to.context_modules.where(migration_id: CC::CCHelper.create_key(mod2)).first
    expect(mod2_2.prerequisites.length).to eq 1
    expect(mod2_2.prerequisites.first).to eq({:type=>"context_module", :name=>mod1_2.name, :id=>mod1_2.id})

    mod3_2 = @copy_to.context_modules.where(migration_id: CC::CCHelper.create_key(mod3)).first
    expect(mod3_2.content_tags.length).to eq 2
    expect(mod3_2.content_tags[0].url).to eq "http://a.example.com/"
    expect(mod3_2.content_tags[1].url).to eq "http://b.example.com/"
    expect(@migration.old_warnings_format.first.first).to eq %{Import Error: Module Item - "Example 3"}

    mod4_2 = @copy_to.context_modules.where(migration_id: CC::CCHelper.create_key(mod4)).first
    expect(mod4_2.content_tags.first.title).to eq att_tag.title
    att_2.reload
    expect(att_2.display_name).to eq 'boring.txt'

    expect(mod4_2.content_tags.count).to eq 2
    tag = mod4_2.content_tags.last
    expect(tag.content_type).to eq "Attachment"
    expect(tag.content_id).to eq att_3_2.id
  end

  it "should translate attachment links on import" do
    attachment = Attachment.create!(:filename => 'ohai there.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
    attachment_import = factory_with_protected_attributes(Attachment, :filename => 'ohai there.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_to), :context => @copy_to, :migration_id => 'ohai')
    body_with_link = %{<p>Watup? <strong>eh?</strong>
      <a href="/courses/%s/files/%s/preview">Preview File</a>
      <a href="/courses/%s/files/%s/download">Download File</a>
      <a href="/courses/%s/files/%s/download?wrap=1">Download (wrap) File</a>
      <a href="/courses/%s/files/%s/bogus?someattr=1">Download (wrap) File</a>
      </p>}
    page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body_with_link % ([ @copy_from.id, attachment.id ] * 4))
    @copy_from.save!

    #export to html file
    migration_id = CC::CCHelper.create_key(page)
    exported_html = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher).html_page(page.body, page.title, :identifier => migration_id)
    #convert to json
    doc = Nokogiri::XML(exported_html)
    hash = @converter.convert_wiki(doc, 'some-page')
    hash = hash.with_indifferent_access
    #import into new course
    @copy_to.attachment_path_id_lookup = { 'unfiled/ohai there.txt' => attachment_import.migration_id }
    Importers::WikiPageImporter.import_from_migration(hash, @copy_to)

    page_2 = @copy_to.wiki.wiki_pages.where(migration_id: migration_id).first
    expect(page_2.title).to eq page.title
    expect(page_2.url).to eq page.url
    expect(page_2.body).to eq body_with_link % ([ @copy_to.id, attachment_import.id ] * 4)
  end

  it "should import wiki pages" do
    # make sure that the wiki page we're linking to in the test below exists
    @copy_from.wiki.wiki_pages.create!(:title => "assignments", :body => "ohai")
    @copy_to.wiki.wiki_pages.create!(:title => "assignments", :body => "ohai")
    mod = @copy_from.context_modules.create!(:name => "some module")
    mod2 = @copy_to.context_modules.create(:name => "some module")
    mod2.migration_id = CC::CCHelper.create_key(mod)
    mod2.save!
    # Create files for the wiki text to reference
    from_root = Folder.root_folders(@copy_from).first
    from_dir = Folder.create!(:name => "sub & folder", :parent_folder => from_root, :context => @copy_from)
    from_att = Attachment.create!(:filename => 'picture+%2B+cropped.png', :display_name => "picture + cropped.png", :uploaded_data => StringIO.new('pretend .png data'), :folder => from_dir, :context => @copy_from)

    to_root = Folder.root_folders(@copy_to).first
    to_dir = Folder.create!(:name => "sub & folder", :parent_folder => to_root, :context => @copy_to)
    to_att = Attachment.create!(:filename => 'picture+%2B+cropped.png', :display_name => "picture + cropped.png", :uploaded_data => StringIO.new('pretend .png data'), :folder => to_dir, :context => @copy_to)
    to_att.migration_id = CC::CCHelper.create_key(from_att)
    to_att.save
    path = to_att.full_display_path.gsub('course files/', '')
    @copy_to.attachment_path_id_lookup = {path => to_att.migration_id}

    body_with_link = %{<p>Watup? <strong>eh?</strong>
      <a href=\"/courses/%s/assignments\">Assignments</a>
      <a href=\"/courses/%s/file_contents/course%%20files/tbe_banner.jpg\">Some file</a>
      <a href=\"/courses/%s/wiki/assignments\">Assignments wiki link</a>
      <a href=\"/courses/%s/modules\">Modules</a>
      <a href=\"/courses/%s/modules/%s\">some module</a>
      <img src="/courses/%s/files/%s/preview" alt="picture.png" /></p>
      <div>
        <div><img src="http://www.instructure.com/images/header-logo.png"></div>
        <div><img src="http://www.instructure.com/images/header-logo.png"></div>
      </div>}
    page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body_with_link % [ @copy_from.id, @copy_from.id, @copy_from.id, @copy_from.id, @copy_from.id, mod.id, @copy_from.id, from_att.id ], :editing_roles => "teachers", :notify_of_update => true)
    page.workflow_state = 'unpublished'
    @copy_from.save!

    #export to html file
    migration_id = CC::CCHelper.create_key(page)
    meta_fields = {:identifier => migration_id}
    meta_fields[:editing_roles] = page.editing_roles
    meta_fields[:hide_from_students] = page.hide_from_students
    meta_fields[:notify_of_update] = page.notify_of_update
    exported_html = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher).html_page(page.body, page.title, meta_fields)
    #convert to json
    doc = Nokogiri::HTML(exported_html)
    hash = @converter.convert_wiki(doc, 'some-page')
    hash = hash.with_indifferent_access
    #import into new course
    Importers::WikiPageImporter.process_migration({'wikis' => [hash, nil]}, @migration)

    expect(ErrorReport.last.message).to match /nil wiki/

    page_2 = @copy_to.wiki.wiki_pages.where(migration_id: migration_id).first
    expect(page_2.title).to eq page.title
    expect(page_2.url).to eq page.url
    expect(page_2.editing_roles).to eq page.editing_roles
    expect(page_2.hide_from_students).to eq page.hide_from_students
    expect(page_2.notify_of_update).to eq page.notify_of_update
    expect(page_2.body).to eq (body_with_link % [ @copy_to.id, @copy_to.id, @copy_to.id, @copy_to.id, @copy_to.id, mod2.id, @copy_to.id, to_att.id ]).gsub(/png" \/>/, 'png">')
    expect(page_2.unpublished?).to eq true
  end

  it "should import migrate inline external tool URLs in wiki pages" do
    # make sure that the wiki page we're linking to in the test below exists
    page = @copy_from.wiki.wiki_pages.create!(:title => "blti-link", :body => "<a href='/courses/#{@copy_from.id}/external_tools/retrieve?url=#{CGI.escape('http://www.example.com')}'>link</a>")
    @copy_from.save!

    #export to html file
    migration_id = CC::CCHelper.create_key(page)
    exported_html = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher).html_page(page.body, page.title, :identifier => migration_id)
    #convert to json
    doc = Nokogiri::HTML(exported_html)
    hash = @converter.convert_wiki(doc, 'blti-link')
    hash = hash.with_indifferent_access
    #import into new course
    Importers::WikiPageImporter.import_from_migration(hash, @copy_to)

    page_2 = @copy_to.wiki.wiki_pages.where(migration_id: migration_id).first
    expect(page_2.title).to eq page.title
    expect(page_2.url).to eq page.url
    expect(page_2.body).to match(/\/courses\/#{@copy_to.id}\/external_tools\/retrieve/)
  end

  it "should import assignments" do
     PluginSetting.stubs(:settings_for_plugin).returns({"lock_at" => "yes",
                  "assignment_group" => "yes",
                  "title" => "yes",
                  "assignment_group_id" => "yes",
                  "submission_types" => "yes",
                  "points_possible" => "yes",
                  "description" => "yes",
                  "grading_type" => "yes"})

    body_with_link = %{<p>Watup? <strong>eh?</strong><a href="/courses/%s/assignments">Assignments</a></p>
<div>
  <div><img src="http://www.instructure.com/images/header-logo.png"></div>
  <div><img src="http://www.instructure.com/images/header-logo.png"></div>
</div>}
    asmnt = @copy_from.assignments.new
    asmnt.title = "Nothing Assignment"
    asmnt.description = body_with_link % @copy_from.id
    asmnt.points_possible = 9.8
    asmnt.assignment_group = @copy_from.assignment_groups.where(name: "Whatever").first_or_create
    asmnt.peer_reviews_due_at = 2.weeks.from_now
    asmnt.allowed_extensions = ["doc", "odt"]
    asmnt.unlock_at = 1.day.from_now
    asmnt.submission_types = "online_upload,online_text_entry,online_url"
    asmnt.grading_type = 'points'
    asmnt.due_at = 1.week.from_now
    asmnt.all_day_date = 1.week.from_now
    asmnt.turnitin_enabled = true
    asmnt.peer_reviews = true
    asmnt.anonymous_peer_reviews = true
    asmnt.peer_review_count = 37
    asmnt.freeze_on_copy = true
    asmnt.save!

    #export to xml/html
    migration_id = CC::CCHelper.create_key(asmnt)
    builder = Builder::XmlMarkup.new(:indent=>2)
    builder.assignment("identifier" => migration_id) {|a|CC::AssignmentResources.create_canvas_assignment(a, asmnt)}
    html = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher).html_page(asmnt.description, "Assignment: " + asmnt.title)
    #convert to json
    meta_doc = Nokogiri::XML(builder.target!)
    html_doc = Nokogiri::HTML(html)
    hash = @converter.parse_canvas_assignment_data(meta_doc, html_doc)
    hash = hash.with_indifferent_access
    #import
    Importers::AssignmentImporter.import_from_migration(hash, @copy_to)

    asmnt_2 = @copy_to.assignments.where(migration_id: migration_id).first
    expect(asmnt_2.title).to eq asmnt.title
    expect(asmnt_2.description).to eq(body_with_link % @copy_to.id)
    expect(asmnt_2.points_possible).to eq asmnt.points_possible
    expect(asmnt_2.allowed_extensions).to eq asmnt.allowed_extensions
    expect(asmnt_2.submission_types).to eq asmnt.submission_types
    expect(asmnt_2.grading_type).to eq asmnt.grading_type
    expect(asmnt_2.unlock_at.to_i).to eq asmnt.unlock_at.to_i
    expect(asmnt_2.due_at.to_i).to eq asmnt.due_at.to_i
    expect(asmnt_2.peer_reviews_due_at.to_i).to eq asmnt.peer_reviews_due_at.to_i
    expect(asmnt_2.all_day_date).to eq asmnt.all_day_date
    expect(asmnt_2.turnitin_enabled).to eq asmnt.turnitin_enabled
    expect(asmnt_2.peer_reviews).to eq asmnt.peer_reviews
    expect(asmnt_2.anonymous_peer_reviews).to eq asmnt.peer_reviews
    expect(asmnt_2.peer_review_count).to eq asmnt.peer_review_count
    expect(asmnt_2.freeze_on_copy).to eq true
    expect(asmnt_2.copied).to eq true
  end

  it "should import external tool assignments" do
    course_with_teacher_logged_in
    assignment_model(:course => @copy_from, :points_possible => 40, :submission_types => 'external_tool', :grading_type => 'points')
    tag_from = @assignment.build_external_tool_tag(:url => "http://example.com/one", :new_tab => true)
    tag_from.content_type = 'ContextExternalTool'
    tag_from.save!

    #export to xml/html
    migration_id = CC::CCHelper.create_key(@assignment)
    builder = Builder::XmlMarkup.new(:indent=>2)
    builder.assignment("identifier" => migration_id) { |a| CC::AssignmentResources.create_canvas_assignment(a, @assignment) }
    html = CC::CCHelper::HtmlContentExporter.new(@copy_from, @from_teacher).html_page(@assignment.description, "Assignment: " + @assignment.title)
    #convert to json
    meta_doc = Nokogiri::XML(builder.target!)
    html_doc = Nokogiri::HTML(html)
    hash = @converter.parse_canvas_assignment_data(meta_doc, html_doc)
    hash = hash.with_indifferent_access
    #import
    Importers::AssignmentImporter.import_from_migration(hash, @copy_to)

    asmnt_2 = @copy_to.assignments.where(migration_id: migration_id).first
    expect(asmnt_2.submission_types).to eq "external_tool"

    expect(asmnt_2.external_tool_tag).not_to be_nil
    tag_to = asmnt_2.external_tool_tag
    expect(tag_to.content_type).to eq tag_from.content_type
    expect(tag_to.url).to eq tag_from.url
    expect(tag_to.new_tab).to eq tag_from.new_tab
  end

  it "should add error for invalid external tool urls" do
    xml = <<XML
<assignment identifier="ia24c092694901d2a5529c142accdaf0b">
  <title>assignment title</title>
  <points_possible>40</points_possible>
  <grading_type>points</grading_type>
  <submission_types>external_tool</submission_types>
  <external_tool_url>/one</external_tool_url>
  <external_tool_new_tab>true</external_tool_new_tab>
</assignment>
XML
    #convert to json
    meta_doc = Nokogiri::XML(xml)
    html_doc = Nokogiri::HTML("<html><head><title>value for title</title></head><body>haha</body></html>")
    hash = @converter.parse_canvas_assignment_data(meta_doc, html_doc)
    hash = hash.with_indifferent_access
    #import
    Importers::AssignmentImporter.import_from_migration(hash, @copy_to, @migration)

    asmnt_2 = @copy_to.assignments.where(migration_id: 'ia24c092694901d2a5529c142accdaf0b').first
    expect(asmnt_2.submission_types).to eq "external_tool"

    # the url was invalid so it won't be there
    expect(asmnt_2.external_tool_tag).to be_nil
    expect(@migration.warnings).to eq ["The url for the external tool assignment \"assignment title\" wasn't valid."]
  end

  it "should import announcements (discussion topics)" do
    body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
    dt = @copy_from.announcements.new
    dt.title = "Topic"
    dt.message = body_with_link % @copy_from.id
    dt.delayed_post_at = 1.week.from_now
    orig_posted_at = 1.day.ago
    dt.posted_at = orig_posted_at
    dt.save!

    #export to xml
    migration_id = CC::CCHelper.create_key(dt)
    cc_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    cc_topic_builder.topic("identifier" => migration_id) {|t| @resource.create_cc_topic(t, dt)}
    canvas_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    canvas_topic_builder.topicMeta {|t| @resource.create_canvas_topic(t, dt)}
    #convert to json
    cc_doc = Nokogiri::XML(cc_topic_builder.target!)
    meta_doc = Nokogiri::XML(canvas_topic_builder.target!)
    hash = @converter.convert_topic(cc_doc, meta_doc)
    hash = hash.with_indifferent_access
    #import
    Importers::DiscussionTopicImporter.import_from_migration(hash, @copy_to)

    dt_2 = @copy_to.discussion_topics.where(migration_id: migration_id).first
    expect(dt_2.title).to eq dt.title
    expect(dt_2.message).to eq body_with_link % @copy_to.id
    expect(dt_2.delayed_post_at.to_i).to eq dt.delayed_post_at.to_i
    expect(dt_2.posted_at.to_i).to eq orig_posted_at.to_i
    expect(dt_2.type).to eq dt.type
  end

  it "should import assignment discussion topic" do
    body_with_link = "<p>What do you think about the <a href=\"/courses/%s/grades\">grades?</a>?</p>"
    dt = @copy_from.discussion_topics.new
    dt.title = "Topic"
    dt.message = body_with_link % @copy_from.id
    dt.posted_at = 1.day.ago
    dt.save!

    assignment = @copy_from.assignments.build
    assignment.submission_types = 'discussion_topic'
    assignment.assignment_group = @copy_from.assignment_groups.where(name: "Stupid Group").first_or_create
    assignment.title = dt.title
    assignment.points_possible = 13.37
    assignment.due_at = 1.week.from_now
    assignment.saved_by = :discussion_topic
    assignment.save

    dt.assignment = assignment
    dt.save

    #export to xml
    migration_id = CC::CCHelper.create_key(dt)
    cc_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    cc_topic_builder.topic("identifier" => migration_id) {|t| @resource.create_cc_topic(t, dt)}
    canvas_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    canvas_topic_builder.topicMeta {|t| @resource.create_canvas_topic(t, dt)}
    #convert to json
    cc_doc = Nokogiri::XML(cc_topic_builder.target!)
    meta_doc = Nokogiri::XML(canvas_topic_builder.target!)
    hash = @converter.convert_topic(cc_doc, meta_doc)
    hash = hash.with_indifferent_access
    #have assignment group ready:
    @copy_to.assignment_groups.where(name: "Distractor").first_or_create
    ag1 = @copy_to.assignment_groups.new
    ag1.name = "Stupid Group"
    ag1.migration_id = CC::CCHelper.create_key(assignment.assignment_group)
    ag1.save!
    #import
    Importers::DiscussionTopicImporter.import_from_migration(hash, @copy_to)

    dt_2 = @copy_to.discussion_topics.where(migration_id: migration_id).first
    expect(dt_2.title).to eq dt.title
    expect(dt_2.message).to eq body_with_link % @copy_to.id
    expect(dt_2.type).to eq dt.type

    a = dt_2.assignment
    expect(a.title).to eq assignment.title
    expect(a.migration_id).to eq CC::CCHelper.create_key(assignment)
    expect(a.due_at.to_i).to eq assignment.due_at.to_i
    expect(a.points_possible).to eq assignment.points_possible
    expect(a.discussion_topic).to eq dt_2
    expect(a.assignment_group.id).to eq ag1.id
  end

  it "should not fail when importing discussion topic when both group_id and assignment are specified" do
    body = "<p>What do you think about the stuff?</p>"
    group = @copy_from.groups.create!(:name => "group")
    dt = group.discussion_topics.new
    dt.title = "Topic"
    dt.message = body
    dt.posted_at = 1.day.ago
    dt.save!

    assignment = @copy_from.assignments.build
    assignment.submission_types = 'discussion_topic'
    assignment.assignment_group = @copy_from.assignment_groups.where(name: "Stupid Group").first_or_create
    assignment.title = dt.title
    assignment.points_possible = 13.37
    assignment.due_at = 1.week.from_now
    assignment.saved_by = :discussion_topic
    assignment.save

    dt.assignment = assignment
    dt.save

    #export to xml
    migration_id = CC::CCHelper.create_key(dt)
    cc_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    cc_topic_builder.topic("identifier" => migration_id) {|t| @resource.create_cc_topic(t, dt)}
    canvas_topic_builder = Builder::XmlMarkup.new(:indent=>2)
    canvas_topic_builder.topicMeta {|t| @resource.create_canvas_topic(t, dt)}
    #convert to json
    cc_doc = Nokogiri::XML(cc_topic_builder.target!)
    meta_doc = Nokogiri::XML(canvas_topic_builder.target!)
    hash = @converter.convert_topic(cc_doc, meta_doc)
    hash = hash.with_indifferent_access
    @copy_to.groups.create!(:name => "whatevs")

    group2 = @copy_to.groups.create!(:name => "group")
    group2.migration_id = CC::CCHelper.create_key(group)
    group2.save!
    hash[:group_id] = group2.migration_id

    cm = ContentMigration.new(:context => @copy_to, :copy_options => {:everything => "1"})
    Importers::DiscussionTopicImporter.process_discussion_topics_migration([hash], cm)

    dt_2 = group2.discussion_topics.where(migration_id: migration_id).first
    expect(dt_2.title).to eq dt.title
    expect(dt_2.message).to eq body
    expect(dt_2.type).to eq dt.type
  end

  it "should import quizzes into correct assignment group" do
    quiz_hash = {"lock_at"=>nil,
                 "questions"=>[],
                 "title"=>"Assignment Quiz",
                 "available"=>true,
                 "assignment"=>
                         {"position"=>2,
                          "rubric_migration_id"=>nil,
                          "title"=>"Assignment Quiz",
                          "grading_standard_migration_id"=>nil,
                          "migration_id"=>"i0c012cbae54b972138520466e557f5e4",
                          "quiz_migration_id"=>"ie3d8f8adfad423eb225229c539cdc450",
                          "points_possible"=>0,
                          "all_day_date"=>1305698400000,
                          "submission_types"=>"online_quiz",
                          "peer_review_count"=>0,
                          "assignment_group_migration_id"=>"i713e960ab2685259505efeb08cd48a1d",
                          "automatic_peer_reviews"=>false,
                          "grading_type"=>"points",
                          "due_at"=>1305805680000,
                          "peer_reviews"=>false,
                          "all_day"=>false},
                 "migration_id"=>"ie3d8f8adfad423eb225229c539cdc450",
                 "question_count"=>19,
                 "scoring_policy"=>"keep_highest",
                 "shuffle_answers"=>true,
                 "quiz_name"=>"Assignment Quiz",
                 "unlock_at"=>nil,
                 "quiz_type"=>"assignment",
                 "points_possible"=>0,
                 "description"=>"",
                 "assignment_group_migration_id"=>"i713e960ab2685259505efeb08cd48a1d",
                 "time_limit"=>nil,
                 "allowed_attempts"=>-1,
                 "due_at"=>1305805680000,
                 "could_be_locked"=>true,
                 "anonymous_submissions"=>false,
                 "show_correct_answers"=>true}

    #have assignment group ready:
    @copy_to.assignment_groups.where(name: "Distractor").first_or_create
    ag = @copy_to.assignment_groups.new
    ag.name = "Stupid Group"
    ag.migration_id = "i713e960ab2685259505efeb08cd48a1d"
    ag.save!

    Importers::QuizImporter.import_from_migration(quiz_hash, @copy_to, nil, {})
    q = @copy_to.quizzes.where(migration_id: "ie3d8f8adfad423eb225229c539cdc450").first
    a = q.assignment
    expect(a.assignment_group.id).to eq ag.id
    expect(q.assignment_group_id).to eq ag.id
  end

  it "should import quizzes' assignment from a migration id" do
    assignment = @copy_from.assignments.build
    assignment.title = "Don't care"
    assignment.points_possible = 13.37
    assignment.due_at = 1.week.from_now
    assignment.migration_id = "hurpdurp"
    assignment.save

    quiz_hash = {
      "lock_at"=>nil,
      "questions"=>[],
      "title"=>"Assignment Quiz",
      "available"=>true,
      "assignment_migration_id" => "assignmentmigrationid",
      "migration_id"=>"quizmigrationid",
      "question_count"=>19,
      "scoring_policy"=>"keep_highest",
      "shuffle_answers"=>true,
      "quiz_name"=>"Assignment Quiz",
      "unlock_at"=>nil,
      "quiz_type"=>"assignment",
      "points_possible"=>0,
      "description"=>"",
      "time_limit"=>nil,
      "allowed_attempts"=>-1,
      "due_at"=>1305805680000,
      "could_be_locked"=>true,
      "anonymous_submissions"=>false,
      "show_correct_answers"=>true
    }.with_indifferent_access

    assignment_hash = {
      "position"=>2,
      "rubric_migration_id"=>nil,
      "title"=>"Assignment Quiz",
      "grading_standard_migration_id"=>nil,
      "migration_id"=>"assignmentmigrationid",
      "points_possible"=>0,
      "all_day_date"=>1305698400000,
      "peer_review_count"=>0,
      "automatic_peer_reviews"=>false,
      "grading_type"=>"points",
      "due_at"=>1305805680000,
      "peer_reviews"=>false,
      "all_day"=>false
    }.with_indifferent_access

    data = {"assignments" => [assignment_hash], "assessments" => {"assessments" => [quiz_hash]}}

    migration = ContentMigration.create(:context => @copy_to)
    migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
    Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

    q = @copy_to.quizzes.where(migration_id: "quizmigrationid").first
    a = @copy_to.assignments.where(migration_id: "assignmentmigrationid").first

    expect(q.assignment_id).to eq a.id
    expect(a.submission_types).to eq "online_quiz"
  end

  it "should convert media tracks" do
    doc = Nokogiri::XML(<<-XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <media_tracks xmlns="http://canvas.instructure.com/xsd/cccv1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 http://canvas.instructure.com/xsd/cccv1p0.xsd">
        <media identifierref="xyz">
          <track kind="subtitles" locale="en" identifierref="abc"/>
          <track kind="subtitles" locale="tlh" identifierref="def"/>
        </media>
      </media_tracks>
    XML
    expect(@converter.convert_media_tracks(doc)).to eql({
      "xyz"=>[{"migration_id"=>"abc", "kind"=>"subtitles", "locale"=>"en"},
              {"migration_id"=>"def", "kind"=>"subtitles", "locale"=>"tlh"}]
    })
  end

  it "should import media tracks" do
    media_objects_folder = Folder.create! context: @copy_to, name: CC::CCHelper::MEDIA_OBJECTS_FOLDER, parent_folder: Folder::root_folders(@course).first
    media_file = @copy_to.attachments.create(folder: media_objects_folder, filename: 'media.flv', uploaded_data: StringIO.new('pretend this is a media file'))
    media_file.migration_id = 'xyz'
    media_file.save!
    mo = MediaObject.new
    mo.attachment = media_file
    mo.media_id = '0_deadbeef'
    mo.save!
    track_file1 = @copy_to.attachments.create(folder: media_objects_folder, filename: 'media.flv.en.subtitles', uploaded_data: StringIO.new('pretend this is a track file'))
    track_file1.migration_id = 'abc'
    track_file1.save!
    track_file2 = @copy_to.attachments.create(folder: media_objects_folder, filename: 'media.flv.tlh.subtitles', uploaded_data: StringIO.new("Qapla'"))
    track_file2.migration_id = 'def'
    track_file2.save!
    data = {
      "media_tracks"=>{
        "xyz"=>[{"migration_id"=>"abc", "kind"=>"subtitles", "locale"=>"en"},
                {"migration_id"=>"def", "kind"=>"subtitles", "locale"=>"tlh"}]
      }
    }.with_indifferent_access

    migration = ContentMigration.create(context: @copy_to)
    migration.stubs(:canvas_import?).returns(true)
    migration.migration_settings[:migration_ids_to_import] = {copy: {'everything' => 1}}
    Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

    expect(mo.media_tracks.where(locale: 'en').first.content).to eql('pretend this is a track file')
    expect(mo.media_tracks.where(locale: 'tlh').first.content).to eql("Qapla'")

    expect(@copy_to.attachments.where(migration_id: 'abc').first).to be_deleted
    expect(@copy_to.attachments.where(migration_id: 'def').first).to be_deleted
  end

  context "warnings for missing links in imported html" do
    it "should add warnings for assessment questions" do
      data = {
        "assessment_questions" => {
          "assessment_questions" =>[{
            "answers" => [],
            "correct_comments" => "",
            "incorrect_comments" => "",
            "question_text" => "<a href='/badlink/toabadplace'>mwhahaha</a>",
            "question_name" => "Question",
            "migration_id" => "i340ed54b48e0de110bda151e00a3bbfd",
            "question_bank_name" => "Imported Questions",
            "question_bank_id" => "i00cddcedde037ed59771ba680d2c00da",
            "question_type" => "essay_question"
          }]
        }
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      bank = @copy_to.assessment_question_banks.first
      question = @copy_to.assessment_questions.first

      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/question_banks/#{bank.id}#question_#{question.id}_question_text"
      expect(warning.error_message).to include("question_text")
    end

    it "should add warnings for assignments" do
      data = {
        "assignments" => [{
          "position"=>2,
          "rubric_migration_id"=>nil,
          "title"=>"Assignment Quiz",
          "grading_standard_migration_id"=>nil,
          "migration_id"=>"assignmentmigrationid",
          "points_possible"=>0,
          "all_day_date"=>1305698400000,
          "peer_review_count"=>0,
          "automatic_peer_reviews"=>false,
          "grading_type"=>"points",
          "due_at"=>1305805680000,
          "peer_reviews"=>false,
          "all_day"=>false,
          "description" => "<a href='wiki_page_migration_id=notarealid'>hooray for bad links</a>"
        }]
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      a = @copy_to.assignments.first

      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/assignments/#{a.id}"
      expect(warning.error_message).to include("description")
    end

    it "should add warnings for calendar events" do
      data = {
        "calendar_events" => [{
          "migration_id" => "id4bebe19c7b729e22543bed8a5a02dcb",
          "title" => "Start of Course",
          "start_at" => 1371189600000,
          "end_at" => 1371189600000,
          "all_day" => false,
          "description" => "<a href='discussion_topic_migration_id=stillnotreal'>hooray for bad links</a>"
        },
        {
          "migration_id" => "blahblahblah",
          "title" => "Start of Course",
          "start_at" => 1371189600000,
          "end_at" => 1371189600000,
          "all_day" => false,
          "description" => "<a href='http://thislinkshouldbeokaythough.com'>hooray for good links</a>"
        }]
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      event = @copy_to.calendar_events.where(migration_id: "id4bebe19c7b729e22543bed8a5a02dcb").first

      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/calendar_events/#{event.id}"
    end

    it "should add warnings for course syllabus" do
      data = {
        "course" => {
          "syllabus_body" => "<a href='%24CANVAS_COURSE_REFERENCE%24/modules/items/9001'>moar bad links? nooo</a>"
        }
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/assignments/syllabus"
    end

    it "should add warnings for discussion topics" do
      data = {
        "discussion_topics" => [{
          "description" => "<a href='%24WIKI_REFERENCE%24/nope'>yet another bad link</a>",
          "title" => "Two-Question Class Evaluation...",
          "migration_id" => "iaccaf448c9f5218ff2a89d1d846b5224",
          "type" => "announcement",
          "posted_at" => 1332158400000,
          "delayed_post_at" => 1361793600000,
          "position" => 41
        },
        {
          "description" => "<a href='%24CANVAS_OBJECT_REFERENCE%24/stillnope'>was there ever any doubt?</a>",
          "title" => "Two-Question Class Evaluation...",
          "migration_id" => "iaccaf448c9f5218ff2a89d1d846b52242",
          "type" => "discussion",
          "posted_at" => 1332158400000,
          "delayed_post_at" => 1361793600000,
          "position" => 41
        }]
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      topic1 = @copy_to.discussion_topics.where(migration_id: "iaccaf448c9f5218ff2a89d1d846b5224").first
      topic2 = @copy_to.discussion_topics.where(migration_id: "iaccaf448c9f5218ff2a89d1d846b52242").first

      expect(migration.migration_issues.count).to eq 2

      warnings = migration.migration_issues.sort_by{|i| i.fix_issue_html_url}
      warning1 = warnings[0]
      expect(warning1.issue_type).to eq "warning"
      expect(warning1.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning1.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/announcements/#{topic1.id}"

      warning2 = warnings[1]
      expect(warning2.issue_type).to eq "warning"
      expect(warning2.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning2.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/discussion_topics/#{topic2.id}"
    end

    it "should add warnings for quizzes" do
      data = {
        "assessments" => {
          "assessments" => [{
            "questions" => [],
            "quiz_type" => "assignment",
            "question_count" => 1,
            "title" => "Week 1 - Activity 4 Quiz",
            "quiz_name" => "Week 1 - Activity 4 Quiz",
            "migration_id" => "i18b97d4d9de02036d8b8861645c5f8ec",
            "allowed_attempts" => -1,
            "description" => "<img src='$IMS_CC_FILEBASE$/somethingthatdoesntexist'/>",
            "scoring_policy" => "keep_highest",
            "assignment_group_migration_id" => "ia517adfdd9051a85ec5cfb1c57b9b853",
            "points_possible" => 1,
            "lock_at" => 1360825140000,
            "unlock_at" => 1359615600000,
            "due_at" => 1360220340000,
            "anonymous_submissions" => false,
            "show_correct_answers" => false,
            "require_lockdown_browser" => false,
            "require_lockdown_browser_for_results" => false,
            "shuffle_answers" => false,
            "available" => true,
            "cant_go_back" => false,
            "one_question_at_a_time" => false
          }]
        }
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      quiz = @copy_to.quizzes.first

      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/quizzes/#{quiz.id}"
    end

    it "should add warnings for wiki pages" do
      data = {
        "wikis" => [{
          "title" => "Credit Options",
          "migration_id" => "i642b8969dbfa332fd96ec9029e96156a",
          "editing_roles" => "teachers",
          "hide_from_students" => false,
          "notify_of_update" => false,
          "text" => "<img src='/cantthinkofanothertypeofbadlinkohwell' />",
          "url_name" => "credit-options"
        }]
      }.with_indifferent_access

      migration = ContentMigration.create(:context => @copy_to)
      migration.migration_settings[:migration_ids_to_import] = {:copy => {"everything" => 1}}
      Importers::CourseContentImporter.import_content(@copy_to, data, nil, migration)

      wiki = @copy_to.wiki.wiki_pages.where(migration_id: "i642b8969dbfa332fd96ec9029e96156a").first
      expect(migration.migration_issues.count).to eq 1
      warning = migration.migration_issues.first
      expect(warning.issue_type).to eq "warning"
      expect(warning.description.start_with?("Missing links found in imported content")).to eq true
      expect(warning.fix_issue_html_url).to eq "/courses/#{@copy_to.id}/wiki/#{wiki.url}"
      expect(warning.error_message).to include("body")
    end
  end
end

describe "cc assignment extensions" do
  before(:all) do
    archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_assignment_extension.zip")
    unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
    @export_folder = File.join(File.dirname(archive_file_path), "cc_cc_assignment_extension")
    @converter = CC::Importer::Canvas::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    @converter.export
    @course_data = @converter.course.with_indifferent_access

    @course = course
    @migration = ContentMigration.create(:context => @course)
    @migration.migration_type = "canvas_cartridge_importer"
    @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
    enable_cache do
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end
  end

  after(:all) do
    @converter.delete_unzipped_archive
    if File.exists?(@export_folder)
      FileUtils::rm_rf(@export_folder)
    end
    truncate_all_tables
  end

  it "should parse canvas data from cc extension" do
    expect(@migration.migration_issues.count).to eq 0

    att = @course.attachments.where(migration_id: 'ieee173de6109d169c627d07bedae0595').first

    # see common_cartridge_converter_spec
    # should get all the cc assignments
    expect(@course.assignments.count).to eq 3
    assignment1 = @course.assignments.where(migration_id: "icd613a5039d9a1539e100058efe44242").first
    expect(assignment1.grading_type).to eq 'pass_fail'
    expect(assignment1.points_possible).to eq 20
    expect(assignment1.description).to include("<img src=\"/courses/#{@course.id}/files/#{att.id}/preview\" alt=\"dana_small.png\">")
    expect(assignment1.submission_types).to eq "online_text_entry,online_url,media_recording,online_upload" # overridden

    assignment2 = @course.assignments.where(migration_id: "icd613a5039d9a1539e100058efe44242copy").first
    expect(assignment2.grading_type).to eq 'points'
    expect(assignment2.points_possible).to eq 21
    expect(assignment2.description).to include('hi, the canvas meta stuff does not have submission types')
    expect(assignment2.submission_types).to eq "online_upload,online_text_entry,online_url"

    # and the canvas only one as well
    assignment3 = @course.assignments.where(migration_id: "ifb359e06083b6eb3a294a7ac2c69e451").first
    expect(assignment3.description).to include("This is left to all custom canvas stuff.")
    expect(assignment3.workflow_state).to eq 'unpublished'
  end
end

describe "matching question reordering" do
  before(:all) do
    skip unless Qti.qti_enabled?
    archive_file_path = File.join(File.dirname(__FILE__) + "/../../../fixtures/migration/canvas_matching_reorder.zip")
    unzipped_file_path = File.join(File.dirname(archive_file_path), "cc_#{File.basename(archive_file_path, '.zip')}", 'oi')
    @export_folder = File.join(File.dirname(archive_file_path), "cc_canvas_matching_reorder")
    @converter = CC::Importer::Canvas::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    @converter.export
    @course_data = @converter.course.with_indifferent_access

    @course = course
    @migration = ContentMigration.create(:context => @course)
    @migration.migration_type = "common_cartridge_importer"
    @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
    enable_cache do
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)
    end
  end

  after(:all) do
    @converter.delete_unzipped_archive
    if File.exists?(@export_folder)
      FileUtils::rm_rf(@export_folder)
    end
    truncate_all_tables
  end

  it "should reorder matching question answers with images if possible (and warn otherwise)" do
    expect(@migration.migration_issues.count).to eq 2
    expect(@course.assessment_questions.count).to eq 3

    broken1 = @course.assessment_questions.where(migration_id: "m20b544d870a086de6e59b79e6dd9186cf_quiz_question").first
    mi1 = @migration.migration_issues.detect{|mi| mi.description ==
        "Imported matching question contains images on both sides, which is unsupported"}
    expect(mi1.fix_issue_html_url.include?("question_#{broken1.id}_question_text")).to eq true

    broken2 = @course.assessment_questions.where(migration_id: "m22b544d870a086de6e59b79e6dd9186be_quiz_question").first
    mi2 = @migration.migration_issues.detect{|mi| mi.description ==
        "Imported matching question contains images inside the choices, and could not be fixed because it also contains distractors"}
    expect(mi2.fix_issue_html_url.include?("question_#{broken2.id}_question_text")).to eq true

    fixed = @course.assessment_questions.where(migration_id: "m21e0c78d05b78dc312bbc0dc77b963781_quiz_question").first
    fixed.question_data[:answers].each do |answer|
      expect(Nokogiri::HTML(answer[:left_html]).at_css("img")).to be_present
      expect(Nokogiri::HTML(answer[:right]).at_css("img")).to be_blank
    end
    fixed.question_data[:matches].each do |match|
      expect(Nokogiri::HTML(match[:text]).at_css("img")).to be_blank
    end
  end
end
