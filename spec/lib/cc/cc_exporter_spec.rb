require File.dirname(__FILE__) + '/cc_spec_helper'

describe "Common Cartridge exporting" do
  it "should collect errors and finish running" do
    course = course_model
    user = user_model
    message = "fail"
    course.stubs(:wiki).raises(message)
    content_export = ContentExport.new
    content_export.course = course
    content_export.user = user
    content_export.save!
    
    content_export.export_course_without_send_later
    
    content_export.error_messages.length.should == 1
    error = content_export.error_messages.first
    error.first.should == "Failed to export wiki pages"
    error.last.should =~ /ErrorReport id: \d*/
    ErrorReport.count.should == 1
    ErrorReport.last.message.should == message 
  end

  context "selective export" do

    before do
      course_with_teacher
      @ce = ContentExport.new
      @ce.settings[:for_course_copy] = true
      @ce.course = @course
      @ce.user = @user
    end

    after(:each) do
      if @file_handle && File.exists?(@file_handle.path)
        FileUtils::rm_rf(@file_handle.path)
      end
    end

    def run_export
      @ce.export_course_without_send_later
      @ce.error_messages.should == []
      @file_handle = @ce.attachment.open :need_local_file => true
      @zip_file = Zip::ZipFile.open(@file_handle.path)
      @manifest_body = @zip_file.read("imsmanifest.xml")
      @manifest_doc = Nokogiri::XML.parse(@manifest_body)
    end

    def mig_id(obj)
      CC::CCHelper.create_key(obj)
    end

    def check_resource_node(obj, type, selected=true)
      res = @manifest_doc.at_css("resource[identifier=#{mig_id(obj)}][type=\"#{type}\"]")
      if selected
        res.should_not be_nil
      else
        res.should be_nil
      end
    end

    it "should selectively export all object types" do
      # create 2 of everything
      @dt1 = @course.discussion_topics.create!(:message => "hi", :title => "discussion title")
      @dt2 = @course.discussion_topics.create!(:message => "hey", :title => "discussion title 2")
      @dt3 = @course.announcements.create!(:message => "howdy", :title => "announcement title")
      @et = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com')
      @et2 = @course.context_external_tools.create!(:name => "new tool2", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com')
      @q1 = @course.quizzes.create!(:title => 'quiz1')
      @q2 = @course.quizzes.create!(:title => 'quiz2')
      @log = LearningOutcomeGroup.default_for(@course)
      @lo = @course.learning_outcomes.create!(:description => "outcome 2", :short_description => "for testing 2", :context => @course)
      @lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
      @lo.save
      @lo2 = @course.learning_outcomes.create!(:description => "outcome 2", :short_description => "for testing 2", :context => @course)
      @lo2.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
      @lo2.save
      @log2 = @course.learning_outcome_groups.create!(:title => 'groupage', :context => @course)
      @log2.add_item(@lo)
      @log2.add_item(@lo2)
      @log3 = @course.learning_outcome_groups.create!(:title => 'groupage2', :context => @course)
      @log.add_item(@log2)
      @log.add_item(@log3)
      @ag = @course.assignment_groups.create!(:name => 'group1')
      @ag2 = @course.assignment_groups.create!(:name => 'group2')
      @asmnt = @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => @ag)
      @asmnt2 = @course.assignments.create!(:title => 'Assignment 2', :points_possible => 10, :assignment_group => @ag)
      @rubric = @course.rubrics.new
      @rubric.title = "Rubric"
      @rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>@lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
      @rubric.save!
      @rubric2 = @course.rubrics.new
      @rubric2.title = "Rubric"
      @rubric2.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>@lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
      @rubric2.save!
      @cm = @course.context_modules.create!(:name => "some module")
      @cm1 = @course.context_modules.create!(:name => "another module")
      @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att2 = Attachment.create!(:filename => 'second.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      @wiki2 = @course.wiki.wiki_pages.create!(:title => "wiki2", :body => "ohais")
      @event = @course.calendar_events.create!(:title => "event", :start_at =>1.week.from_now)
      @event1 = @course.calendar_events.create!(:title => "event2", :start_at =>2.weeks.from_now)
      @bank = @course.assessment_question_banks.create!(:title => 'bank')
      @bank2 = @course.assessment_question_banks.create!(:title => 'bank2')

      # only select one of each type
      @ce.selected_content = {
              :discussion_topics => {mig_id(@dt1) => "1", mig_id(@dt3) => "1"},
              :context_external_tools => {mig_id(@et) => "1"},
              :quizzes => {mig_id(@q1) => "1"},
              :learning_outcomes => {mig_id(@lo) => "1"},
              :learning_outcome_groups => {mig_id(@log2) => "1"},
              :assignment_groups => {mig_id(@ag) => "1"},
              :assignments => {mig_id(@asmnt) => "1", mig_id(@asmnt2) => "0"},
              :rubrics => {mig_id(@rubric) => "1", mig_id(@rubric2) => "0"},
              :context_modules => {mig_id(@cm) => "1", mig_id(@cm2) => "0"},
              :attachments => {mig_id(@att) => "1", mig_id(@att2) => "0"},
              :wiki_pages => {mig_id(@wiki) => "1", mig_id(@wiki2) => "0"},
              :calendar_events => {mig_id(@event) => "1", mig_id(@event2) => "0"},
              :assessment_question_banks => {mig_id(@bank) => "1", mig_id(@bank2) => "0"},
      }
      @ce.save!

      run_export

      # make sure only the selected one is exported by looking at export data
      check_resource_node(@dt1, CC::CCHelper::DISCUSSION_TOPIC)
      check_resource_node(@dt2, CC::CCHelper::DISCUSSION_TOPIC, false)
      check_resource_node(@dt3, CC::CCHelper::DISCUSSION_TOPIC)
      check_resource_node(@et, CC::CCHelper::BASIC_LTI)
      check_resource_node(@et2, CC::CCHelper::BASIC_LTI, false)
      check_resource_node(@q1, CC::CCHelper::ASSESSMENT_TYPE)
      check_resource_node(@q2, CC::CCHelper::ASSESSMENT_TYPE, false)
      check_resource_node(@asmnt, CC::CCHelper::LOR)
      check_resource_node(@asmnt2, CC::CCHelper::LOR, false)
      check_resource_node(@att, CC::CCHelper::WEBCONTENT, false)
      check_resource_node(@att2, CC::CCHelper::WEBCONTENT, false)
      check_resource_node(@wiki, CC::CCHelper::WEBCONTENT, true)
      check_resource_node(@wiki2, CC::CCHelper::WEBCONTENT, false)
      check_resource_node(@bank, CC::CCHelper::LOR)
      check_resource_node(@bank2, CC::CCHelper::LOR, false)

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/learning_outcomes.xml"))
      doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log)}]").should be_nil
      doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log2)}]").should_not be_nil
      doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log3)}]").should be_nil
      doc.at_css("learningOutcome[identifier=#{mig_id(@lo)}]").should_not be_nil
      doc.at_css("learningOutcome[identifier=#{mig_id(@lo2)}]").should be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/assignment_groups.xml"))
      doc.at_css("assignmentGroup[identifier=#{mig_id(@ag)}]").should_not be_nil
      doc.at_css("assignmentGroup[identifier=#{mig_id(@ag2)}]").should be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/rubrics.xml"))
      doc.at_css("rubric[identifier=#{mig_id(@rubric)}]").should_not be_nil
      doc.at_css("rubric[identifier=#{mig_id(@rubric2)}]").should be_nil

      @manifest_doc.at_css("item[identifier=LearningModules] item[identifier=#{mig_id(@cm)}]").should_not be_nil
      @manifest_doc.at_css("item[identifier=LearningModules] item[identifier=#{mig_id(@cm2)}]").should be_nil
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/module_meta.xml"))
      doc.at_css("module[identifier=#{mig_id(@cm)}]").should_not be_nil
      doc.at_css("module[identifier=#{mig_id(@cm2)}]").should be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/events.xml"))
      doc.at_css("event[identifier=#{mig_id(@event)}]").should_not be_nil
      doc.at_css("event[identifier=#{mig_id(@event2)}]").should be_nil
    end

  end
end
