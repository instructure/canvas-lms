require File.dirname(__FILE__) + '/../cc_spec_helper'

describe "Common Cartridge importing" do
  before(:each) do
    @converter = get_cc_converter
    @copy_from = course_model
    @from_teacher = @user
    @copy_to = course_model
    @copy_to.name = "alt name"
    @copy_to.course_code = "alt name"

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

    body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
    @copy_from.syllabus_body = body_with_link % @copy_from.id 

    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_course_settings("1", builder)
    syllabus = StringIO.new
    @resource.create_syllabus(syllabus)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_course_settings(doc)
    syl_doc = Nokogiri::XML(syllabus.string)
    hash[:syllabus_body] = @converter.convert_syllabus(syl_doc)
    #import json into new course
    hash = hash.with_indifferent_access
    @copy_to.import_settings_from_migration({:course=>hash})
    @copy_to.save!

    #compare settings
    @copy_to.conclude_at.to_i.should == @copy_from.conclude_at.to_i
    @copy_to.start_at.to_i.should == @copy_from.start_at.to_i
    @copy_to.syllabus_body.should == body_with_link % @copy_to.id
    @copy_to.storage_quota.should_not == @copy_from.storage_quota
    @copy_to.name.should_not == @copy_from.name
    @copy_to.course_code.should_not == @copy_from.course_code
    atts = Course.clonable_attributes
    atts -= Canvas::MigratorHelper::COURSE_NO_COPY_ATTS
    atts.each do |att|
      @copy_to.send(att).should == @copy_from.send(att)
    end
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

  it "should import external tools" do
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
    ExternalFeed.process_migration({'external_feeds'=>hash}, @migration)
    @copy_to.save!
  
    ef_2 = @copy_to.external_feeds.find_by_migration_id(CC::CCHelper.create_key(ef))
    ef_2.url.should == ef.url
    ef_2.title.should == ef.title
    ef_2.feed_type.should == ef.feed_type
    ef_2.feed_purpose.should == ef.feed_purpose
    ef_2.verbosity.should == ef.verbosity
    ef_2.header_match.should == ef.header_match
  end
  
  it "should import grading standards" do
    gs = @copy_from.grading_standards.new
    gs.title = "Standard eh"
    gs.data = [["A", 1], ["A-", 0.92], ["B+", 0.88], ["B", 0.84], ["B!-", 0.82], ["C+", 0.79], ["C", 0.76], ["C-", 0.73], ["D+", 0.69], ["D", 0.66], ["D-", 0.63], ["F", 0.6]]
    gs.save!
    
    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_grading_standards(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_grading_standards(doc)
    #import json into new course
    GradingStandard.process_migration({'grading_standards'=>hash}, @migration)
    @copy_to.save!
  
    gs_2 = @copy_to.grading_standards.find_by_migration_id(CC::CCHelper.create_key(gs))
    gs_2.title.should == gs.title
    gs_2.data.should == gs.data
  end
  
  def create_learning_outcome
    lo = @copy_from.learning_outcomes.new
    lo.context = @copy_from
    lo.short_description = "Lone outcome"
    lo.description = "<p>Descriptions are boring</p>"
    lo.workflow_state = 'active'
    lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
    lo.save!
    default = LearningOutcomeGroup.default_for(@copy_from)
    default.add_item(lo)
    lo
  end
  
  def import_learning_outcomes
    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_learning_outcomes(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_learning_outcomes(doc)
    #import json into new course
    LearningOutcome.process_migration({'learning_outcomes'=>hash}, @migration)
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
    
    lo2 = @copy_from.learning_outcomes.new
    lo2.context = @copy_from
    lo2.short_description = "outcome in group"
    lo2.workflow_state = 'active'
    lo2.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
    lo2.save!
    lo_g.add_item(lo2)
    
    default = LearningOutcomeGroup.default_for(@copy_from)
    default.add_item(lo_g)
    default.add_item(lo_g2)
    
    import_learning_outcomes
    
    lo_2 = @copy_to.learning_outcomes.find_by_migration_id(CC::CCHelper.create_key(lo))
    lo_2.short_description.should == lo.short_description
    lo_2.description.should == lo.description
    lo_2.data.with_indifferent_access.should == lo.data.with_indifferent_access
    
    lo2_2 = @copy_to.learning_outcomes.find_by_migration_id(CC::CCHelper.create_key(lo2))
    lo2_2.short_description.should == lo2.short_description
    lo2_2.description.should == lo2.description
    lo2_2.data.with_indifferent_access.should == lo2.data.with_indifferent_access
    
    lo_g_2 = @copy_to.learning_outcome_groups.find_by_migration_id(CC::CCHelper.create_key(lo_g))
    lo_g_2.title.should == lo_g.title
    lo_g_2.description.should == lo_g.description
    lo_g_2.sorted_content.length.should == 1
    
    lo_g2_2 = @copy_to.learning_outcome_groups.find_by_migration_id(CC::CCHelper.create_key(lo_g2))
    lo_g2_2.title.should == lo_g2.title
    lo_g2_2.description.should == lo_g2.description
    lo_g2_2.sorted_content.length.should == 0
  end
  
  it "should import rubrics" do
    # create an outcome to reference
    lo = create_learning_outcome
    import_learning_outcomes
    
    rubric = @copy_from.rubrics.new
    rubric.title = "Rubric"
    rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}, {:criterion_id=>"309_6312", :points=>0, :description=>"No Marks", :id=>"blank_2", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}, {:criterion_id=>"309_343", :points=>0, :description=>"Does Not Meet Expectations", :id=>"309_9962", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
    rubric.save!
    
    #export to xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    @resource.create_rubrics(builder)
    #convert to json
    doc = Nokogiri::XML(builder.target!)
    hash = @converter.convert_rubrics(doc)
    #import json into new course
    hash[0] = hash[0].with_indifferent_access
    Rubric.process_migration({'rubrics'=>hash}, @migration)
    @copy_to.save!
  
    @copy_to.rubric_associations.count.should == 1
    lo_2 = @copy_to.learning_outcomes.find_by_migration_id(CC::CCHelper.create_key(lo))
    lo_2.should_not be_nil
    rubric_2 = @copy_to.rubrics.find_by_migration_id(CC::CCHelper.create_key(rubric))
    rubric_2.title.should == rubric.title
    rubric_2.data[1][:learning_outcome_id].should == lo_2.id
  end
  
  it "should import modules" do 
    mod1 = @copy_from.context_modules.create!(:name => "some module", :unlock_at => 1.week.from_now)
    mod2 = @copy_from.context_modules.create!(:name => "next module")
    mod3 = @copy_from.context_modules.create!(:name => "url module")
    mod2.prerequisites = [{:type=>"context_module", :name=>mod1.name, :id=>mod1.id}]
    mod2.require_sequential_progress = true
    mod2.save!
    
    asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
    tag = mod1.add_item({:id => asmnt1.id, :type => 'assignment'})
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
    ContextModule.process_migration({'modules'=>hash}, @migration)
    @copy_to.save!
    
    mod1_2 = @copy_to.context_modules.find_by_migration_id(CC::CCHelper.create_key(mod1))
    mod1_2.name.should == mod1.name
    mod1_2.unlock_at.to_i.should == mod1.unlock_at.to_i
    mod1_2.content_tags.count.should == mod1.content_tags.count
    tag = mod1_2.content_tags.first
    tag.content_id.should == asmnt2.id
    tag.content_type.should == 'Assignment'
    cr1 = mod1_2.completion_requirements.find {|cr| cr[:id] == tag.id}
    cr1[:type].should == 'min_score'
    cr1[:min_score].should == 5
    tag = mod1_2.content_tags.last
    tag.content_id.should == page2.id
    tag.content_type.should == 'WikiPage'
    cr2 = mod1_2.completion_requirements.find {|cr| cr[:id] == tag.id}
    cr2[:type].should == 'must_view'
    
    mod2_2 = @copy_to.context_modules.find_by_migration_id(CC::CCHelper.create_key(mod2))
    mod2_2.prerequisites.length.should == 1
    mod2_2.prerequisites.first.should == {:type=>"context_module", :name=>mod1_2.name, :id=>mod1_2.id}
    
    mod3_2 = @copy_to.context_modules.find_by_migration_id(CC::CCHelper.create_key(mod3))
    mod3_2.content_tags.length.should == 2
    mod3_2.content_tags[0].url.should == "http://a.example.com/"
    mod3_2.content_tags[1].url.should == "http://b.example.com/"
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
    exported_html = CC::CCHelper.html_page(page.body, page.title, @copy_from, @from_teacher, migration_id)
    #convert to json
    doc = Nokogiri::XML(exported_html)
    hash = @converter.convert_wiki(doc, 'some-page')
    hash = hash.with_indifferent_access
    #import into new course
    @copy_to.attachment_path_id_lookup = { 'unfiled/ohai there.txt' => attachment_import.migration_id }
    WikiPage.import_from_migration(hash, @copy_to)
    
    page_2 = @copy_to.wiki.wiki_pages.find_by_migration_id(migration_id)
    page_2.title.should == page.title
    page_2.url.should == page.url
    page_2.body.should == body_with_link % ([ @copy_to.id, attachment_import.id ] * 4)
  end

  it "should import wiki pages" do
    # make sure that the wiki page we're linking to in the test below exists
    @copy_from.wiki.wiki_pages.create!(:title => "assignments", :body => "ohai")
    @copy_to.wiki.wiki_pages.create!(:title => "assignments", :body => "ohai")
    mod = @copy_from.context_modules.create!(:name => "some module")
    mod2 = @copy_to.context_modules.create(:name => "some module")
    mod2.migration_id = CC::CCHelper.create_key(mod)
    mod2.save!
    
    body_with_link = %{<p>Watup? <strong>eh?</strong>
      <a href=\"/courses/%s/assignments\">Assignments</a>
      <a href=\"/courses/%s/file_contents/course%%20files/tbe_banner.jpg\">Some file</a>
      <a href=\"/courses/%s/wiki/assignments\">Assignments wiki link</a>
      <a href=\"/courses/%s/modules\">Modules</a>
      <a href=\"/courses/%s/modules/%s\">some module</a>
      </p>}
    page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body_with_link % [ @copy_from.id, @copy_from.id, @copy_from.id, @copy_from.id, @copy_from.id, mod.id ])
    @copy_from.save!
    
    #export to html file
    migration_id = CC::CCHelper.create_key(page)
    exported_html = CC::CCHelper.html_page(page.body, page.title, @copy_from, @from_teacher, migration_id)
    #convert to json
    doc = Nokogiri::XML(exported_html)
    hash = @converter.convert_wiki(doc, 'some-page')
    hash = hash.with_indifferent_access
    #import into new course
    WikiPage.import_from_migration(hash, @copy_to)
    
    page_2 = @copy_to.wiki.wiki_pages.find_by_migration_id(migration_id)
    page_2.title.should == page.title
    page_2.url.should == page.url
    page_2.body.should == body_with_link % [ @copy_to.id, @copy_to.id, @copy_to.id, @copy_to.id, @copy_to.id, mod2.id ]
  end
  
  it "should import assignments" do 
    body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
    asmnt = @copy_from.assignments.new
    asmnt.title = "Nothing Assignment"
    asmnt.description = body_with_link % @copy_from.id
    asmnt.points_possible = 9.8
    asmnt.assignment_group = @copy_from.assignment_groups.find_or_create_by_name("Whatever")
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
    asmnt.save!

    #export to xml/html
    migration_id = CC::CCHelper.create_key(asmnt)
    builder = Builder::XmlMarkup.new(:indent=>2)
    builder.assignment("identifier" => migration_id) {|a|CC::AssignmentResources.create_assignment(a, asmnt)}
    html = CC::CCHelper.html_page(asmnt.description, "Assignment: " + asmnt.title, @copy_from, @from_teacher)
    #convert to json
    meta_doc = Nokogiri::XML(builder.target!)
    html_doc = Nokogiri::XML(html)
    hash = @converter.convert_assignment(meta_doc, html_doc)
    hash = hash.with_indifferent_access
    #import
    Assignment.import_from_migration(hash, @copy_to)
    
    asmnt_2 = @copy_to.assignments.find_by_migration_id(migration_id)
    asmnt_2.title.should == asmnt.title
    asmnt_2.description.should == body_with_link % @copy_to.id
    asmnt_2.points_possible.should == asmnt.points_possible
    asmnt_2.allowed_extensions.should == asmnt.allowed_extensions
    asmnt_2.submission_types.should == asmnt.submission_types
    asmnt_2.grading_type.should == asmnt.grading_type
    asmnt_2.unlock_at.to_i.should == asmnt.unlock_at.to_i
    asmnt_2.due_at.to_i.should == asmnt.due_at.to_i
    asmnt_2.peer_reviews_due_at.to_i.should == asmnt.peer_reviews_due_at.to_i
    asmnt_2.all_day_date.should == asmnt.all_day_date
    asmnt_2.turnitin_enabled.should == asmnt.turnitin_enabled
    asmnt_2.peer_reviews.should == asmnt.peer_reviews
    asmnt_2.anonymous_peer_reviews.should == asmnt.peer_reviews
    asmnt_2.peer_review_count.should == asmnt.peer_review_count
    asmnt_2.mastery_score.should be_nil
    asmnt_2.max_score.should be_nil
    asmnt_2.min_score.should be_nil
  end
  
  it "should import announcements (discussion topics)" do
    body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
    dt = @copy_from.announcements.new
    dt.title = "Topic"
    dt.message = body_with_link % @copy_from.id
    dt.delayed_post_at = 1.week.from_now
    dt.posted_at = 1.day.ago
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
    DiscussionTopic.import_from_migration(hash, @copy_to)
    
    dt_2 = @copy_to.discussion_topics.find_by_migration_id(migration_id)
    dt_2.title.should == dt.title
    dt_2.message.should == body_with_link % @copy_to.id
    dt_2.delayed_post_at.to_i.should == dt.delayed_post_at.to_i
    dt_2.posted_at.to_i.should == dt.posted_at.to_i
    dt_2.type.should == dt.type
  end
  
  it "should import assignment discussion topic" do
    body_with_link = "<p>What do you think about the <a href=\"/courses/%s/grades\">grades?</a>?</p>"
    dt = @copy_from.announcements.new
    dt.title = "Topic"
    dt.message = body_with_link % @copy_from.id
    dt.posted_at = 1.day.ago
    dt.save!
    
    assignment = @copy_from.assignments.build
    assignment.submission_types = 'discussion_topic'
    assignment.assignment_group = @copy_from.assignment_groups.find_or_create_by_name("Stupid Group")
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
    #import
    DiscussionTopic.import_from_migration(hash, @copy_to)
    
    dt_2 = @copy_to.discussion_topics.find_by_migration_id(migration_id)
    dt_2.title.should == dt.title
    dt_2.message.should == body_with_link % @copy_to.id
    dt_2.type.should == dt.type
    
    a = dt_2.assignment
    a.title.should == assignment.title
    a.migration_id.should == CC::CCHelper.create_key(assignment)
    a.due_at.to_i.should == assignment.due_at.to_i
    a.points_possible.should == assignment.points_possible
    a.discussion_topic.should == dt_2
  end

end
