require File.expand_path(File.dirname(__FILE__) + '/cc_spec_helper')

describe "Common Cartridge exporting" do
  it "should collect errors and finish running" do
    course = course_model
    user = user_model
    message = "fail"
    course.stubs(:wiki).raises(message)
    content_export = ContentExport.new
    content_export.context = course
    content_export.user = user
    content_export.save!
    
    content_export.export_without_send_later
    
    expect(content_export.error_messages.length).to eq 1
    error = content_export.error_messages.first
    expect(error.first).to eq "Failed to export wiki pages"
    expect(error.last).to match /ErrorReport id: \d*/
    expect(ErrorReport.count).to eq 1
    expect(ErrorReport.last.message).to eq message
  end

  context "creating .zip exports" do

    before do
      course_with_teacher
      @ce = @course.content_exports.build
      @ce.export_type = ContentExport::COURSE_COPY
      @ce.user = @user
    end

    after(:each) do
      if @file_handle && File.exists?(@file_handle.path)
        FileUtils::rm_rf(@file_handle.path)
      end
    end

    def run_export(opts = {})
      @ce.export_without_send_later(opts)
      expect(@ce.error_messages).to eq []
      @file_handle = @ce.attachment.open :need_local_file => true
      @zip_file = Zip::File.open(@file_handle.path)
      @manifest_body = @zip_file.read("imsmanifest.xml")
      @manifest_doc = Nokogiri::XML.parse(@manifest_body)
    end

    def mig_id(obj)
      CC::CCHelper.create_key(obj)
    end

    def check_resource_node(obj, type, selected=true)
      res = @manifest_doc.at_css("resource[identifier=#{mig_id(obj)}][type=\"#{type}\"]")
      if selected
        expect(res).not_to be_nil
      else
        expect(res).to be_nil
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
      @log = @course.root_outcome_group
      @lo = @course.created_learning_outcomes.create!(:description => "outcome 2", :short_description => "for testing 2", :context => @course)
      @lo.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
      @lo.save
      @lo2 = @course.created_learning_outcomes.create!(:description => "outcome 2", :short_description => "for testing 2", :context => @course)
      @lo2.data = {:rubric_criterion=>{:mastery_points=>3, :ratings=>[{:description=>"Exceeds Expectations", :points=>5}, {:description=>"Meets Expectations", :points=>3}, {:description=>"Does Not Meet Expectations", :points=>0}], :description=>"First outcome", :points_possible=>5}}
      @lo2.save
      @log2 = @course.learning_outcome_groups.create!(:title => 'groupage', :context => @course)
      @log2.add_outcome(@lo)
      @log2.add_outcome(@lo2)
      @log3 = @course.learning_outcome_groups.create!(:title => 'groupage2', :context => @course)
      @log.adopt_outcome_group(@log2)
      @log.adopt_outcome_group(@log3)
      @ag = @course.assignment_groups.create!(:name => 'group1')
      @ag2 = @course.assignment_groups.create!(:name => 'group2')
      @asmnt = @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => @ag)
      @asmnt2 = @course.assignments.create!(:title => 'Assignment 2', :points_possible => 10, :assignment_group => @ag)
      @rubric = @course.rubrics.new
      @rubric.title = "Rubric"
      @rubric.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>@lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
      @rubric.save!
      @rubric.associate_with(@course, @course)
      @rubric2 = @course.rubrics.new
      @rubric2.title = "Rubric"
      @rubric2.data = [{:ratings=>[{:criterion_id=>"309_6312", :points=>5, :description=>"Full Marks", :id=>"blank", :long_description=>""}], :points=>5, :description=>"Description of criterion", :id=>"309_6312", :long_description=>""}, {:ignore_for_scoring=>false, :mastery_points=>3, :learning_outcome_id=>@lo.id, :ratings=>[{:criterion_id=>"309_343", :points=>5, :description=>"Exceeds Expectations", :id=>"309_6516", :long_description=>""}], :points=>5, :description=>"Learning Outcome", :id=>"309_343", :long_description=>"<p>Outcome</p>"}]
      @rubric2.save!
      @rubric2.associate_with(@course, @course)
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
              :discussion_topics => {mig_id(@dt1) => "1"},
              :announcements => {mig_id(@dt3) => "1"},
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
      expect(doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log)}]")).to be_nil
      expect(doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log2)}]")).not_to be_nil
      expect(doc.at_css("learningOutcomeGroup[identifier=#{mig_id(@log3)}]")).to be_nil
      expect(doc.at_css("learningOutcome[identifier=#{mig_id(@lo)}]")).not_to be_nil
      expect(doc.at_css("learningOutcome[identifier=#{mig_id(@lo2)}]")).to be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/assignment_groups.xml"))
      expect(doc.at_css("assignmentGroup[identifier=#{mig_id(@ag)}]")).not_to be_nil
      expect(doc.at_css("assignmentGroup[identifier=#{mig_id(@ag2)}]")).to be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/rubrics.xml"))
      expect(doc.at_css("rubric[identifier=#{mig_id(@rubric)}]")).not_to be_nil
      expect(doc.at_css("rubric[identifier=#{mig_id(@rubric2)}]")).to be_nil

      expect(@manifest_doc.at_css("item[identifier=LearningModules] item[identifier=#{mig_id(@cm)}]")).not_to be_nil
      expect(@manifest_doc.at_css("item[identifier=LearningModules] item[identifier=#{mig_id(@cm2)}]")).to be_nil
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/module_meta.xml"))
      expect(doc.at_css("module[identifier=#{mig_id(@cm)}]")).not_to be_nil
      expect(doc.at_css("module[identifier=#{mig_id(@cm2)}]")).to be_nil

      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/events.xml"))
      expect(doc.at_css("event[identifier=#{mig_id(@event)}]")).not_to be_nil
      expect(doc.at_css("event[identifier=#{mig_id(@event2)}]")).to be_nil
    end

    it "should create a quizzes-only export" do

      @q1 = @course.quizzes.create!(:title => 'quiz1')
      @q2 = @course.quizzes.create!(:title => 'quiz2')

      @ce.export_type = ContentExport::QTI
      @ce.selected_content = {
              :all_quizzes => "1",
      }
      @ce.save!

      run_export

      check_resource_node(@q1, CC::CCHelper::QTI_ASSESSMENT_TYPE)
      check_resource_node(@q2, CC::CCHelper::QTI_ASSESSMENT_TYPE)

      alt_mig_id1 = CC::CCHelper.create_key(@q1, 'canvas_')
      expect(@manifest_doc.at_css("resource[identifier=#{alt_mig_id1}][type=\"#{CC::CCHelper::LOR}\"]")).not_to be_nil

      alt_mig_id2 = CC::CCHelper.create_key(@q2, 'canvas_')
      expect(@manifest_doc.at_css("resource[identifier=#{alt_mig_id2}][type=\"#{CC::CCHelper::LOR}\"]")).not_to be_nil
    end

    it "should export quizzes with groups that point to external banks" do
      orig_course = @course
      course_with_teacher(:user => @user)
      different_course = @course
      q1 = orig_course.quizzes.create!(:title => 'quiz1')
      bank = different_course.assessment_question_banks.create!(:title => 'bank')
      bank2 = orig_course.account.assessment_question_banks.create!(:title => 'bank2')
      group = q1.quiz_groups.create!(:name => "group", :pick_count => 3, :question_points => 5.0)
      group.assessment_question_bank = bank
      group.save
      group2 = q1.quiz_groups.create!(:name => "group2", :pick_count => 5, :question_points => 2.0)
      group2.assessment_question_bank = bank2
      group2.save

      @ce.export_type = ContentExport::QTI
      @ce.selected_content = {
              :all_quizzes => "1",
              :all_assessment_question_banks => "1",
      }
      @ce.save!

      run_export

      doc = Nokogiri::XML.parse(@zip_file.read("#{mig_id(q1)}/#{mig_id(q1)}.xml"))
      selections = doc.css('selection')
      expect(selections[0].at_css("sourcebank_ref").text.to_i).to eq bank.id
      expect(selections[0].at_css("selection_extension sourcebank_context").text).to eq bank.context.asset_string
      expect(selections[1].at_css("sourcebank_ref").text.to_i).to eq bank2.id
      expect(selections[1].at_css("selection_extension sourcebank_context").text).to eq bank2.context.asset_string
    end

    it "should selectively create a quizzes-only export" do

      @q1 = @course.quizzes.create!(:title => 'quiz1')
      @q2 = @course.quizzes.create!(:title => 'quiz2')

      @ce.export_type = ContentExport::QTI
      @ce.selected_content = {
              :quizzes => {mig_id(@q1) => "1"},
      }
      @ce.save!

      run_export

      check_resource_node(@q1, CC::CCHelper::QTI_ASSESSMENT_TYPE)
      check_resource_node(@q2, CC::CCHelper::QTI_ASSESSMENT_TYPE, false)
    end

    it "should include any files referenced in html" do
      @att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att2 = Attachment.create!(:filename => 'second.jpg', :uploaded_data => StringIO.new('ohais'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @q1 = @course.quizzes.create(:title => 'quiz1')

      qq = @q1.quiz_questions.create!
      data = {:correct_comments => "",
                          :question_type => "multiple_choice_question",
                          :question_bank_name => "Quiz",
                          :assessment_question_id => "9270",
                          :migration_id => "QUE_1014",
                          :incorrect_comments => "",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 1,
                          :question_text => "Image yo: <img src=\"/courses/#{@course.id}/files/#{@att.id}/preview\">",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :text => "True", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :text => "False", :weight => 0, :id => 2279}]}.with_indifferent_access
      qq.write_attribute(:question_data, data)
      qq.save!

      @ce.export_type = ContentExport::QTI
      @ce.selected_content = {
              :all_quizzes => "1",
      }
      @ce.save!

      run_export

      check_resource_node(@q1, CC::CCHelper::QTI_ASSESSMENT_TYPE)

      doc = Nokogiri::XML.parse(@zip_file.read("#{mig_id(@q1)}/#{mig_id(@q1)}.xml"))
      expect(doc.at_css("presentation material mattext").text).to eq "<div>Image yo: <img src=\"%24IMS-CC-FILEBASE%24/unfiled/first.png\">\n</div>"

      check_resource_node(@att, CC::CCHelper::WEBCONTENT)
      check_resource_node(@att2, CC::CCHelper::WEBCONTENT, false)

      path = @manifest_doc.at_css("resource[identifier=#{mig_id(@att)}]")['href']
      expect(@zip_file.find_entry(path)).not_to be_nil
    end

    it "should export web content files properly when display name is changed" do
      @att = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att.display_name = "not_actually_first.png"
      @att.save!

      @q1 = @course.quizzes.create(:title => 'quiz1')

      qq = @q1.quiz_questions.create!
      data = {:correct_comments => "",
              :question_type => "multiple_choice_question",
              :question_bank_name => "Quiz",
              :assessment_question_id => "9270",
              :migration_id => "QUE_1014",
              :incorrect_comments => "",
              :question_name => "test fun",
              :name => "test fun",
              :points_possible => 1,
              :question_text => "Image yo: <img src=\"/courses/#{@course.id}/files/#{@att.id}/preview\">",
              :answers =>
                  [{:migration_id => "QUE_1016_A1", :text => "True", :weight => 100, :id => 8080},
                   {:migration_id => "QUE_1017_A2", :text => "False", :weight => 0, :id => 2279}]}.with_indifferent_access
      qq.write_attribute(:question_data, data)
      qq.save!

      @ce.export_type = ContentExport::COMMON_CARTRIDGE
      @ce.selected_content = {
          :all_quizzes => "1",
      }
      @ce.save!

      run_export

      check_resource_node(@q1, CC::CCHelper::ASSESSMENT_TYPE)

      doc = Nokogiri::XML.parse(@zip_file.read("#{mig_id(@q1)}/assessment_qti.xml"))
      expect(doc.at_css("presentation material mattext").text).to eq "<div>Image yo: <img src=\"%24IMS-CC-FILEBASE%24/unfiled/not_actually_first.png\">\n</div>"

      check_resource_node(@att, CC::CCHelper::WEBCONTENT)

      path = @manifest_doc.at_css("resource[identifier=#{mig_id(@att)}]")['href']
      expect(@zip_file.find_entry(path)).not_to be_nil
    end

    it "should not fail when answers are missing for FIMB" do
      @q1 = @course.quizzes.create(:title => 'quiz1')

      qq = @q1.quiz_questions.create!
      data = {"question_text" =>
                      "<p><span>enter three things [d], [e], [f]</span></p>",
              "neutral_comments" => "",
              "incorrect_comments" => "",
              "name" => "silly question with no answers",
              "answers" =>
                      [{"id" => 4505, "weight" => 0, "text" => "", "blank_id" => "d", "comments" => ""},
                       {"id" => 7936, "weight" => 0, "text" => "", "blank_id" => "d", "comments" => ""}],
              "correct_comments" => "",
              "question_type" => "fill_in_multiple_blanks_question",
              "assessment_question_id" => nil,
              "question_name" => "personality",
              "points_possible" => 1}.with_indifferent_access
      qq.write_attribute(:question_data, data)
      qq.save!

      @ce.export_type = ContentExport::QTI
      @ce.selected_content = {
              :all_quizzes => "1",
      }
      @ce.save!

      # this checks that there are no export errors, so the test is in there
      run_export
    end

    it "should deal with file URLs in anchor bodies" do
      @att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@course), :context => @course)
      link_thing = %{<a href="/courses/#{@course.id}/files/#{@att.id}/download?wrap=1">/courses/#{@course.id}/files/#{@att.id}/download?wrap=1</a>}
      @course.syllabus_body = link_thing
      @course.save!
      @ag = @course.assignment_groups.create!(:name => 'group1')
      @asmnt = @course.assignments.create!(:title => 'Assignment 1', :points_possible => 10, :assignment_group => @ag,
                                           :description => link_thing)
      @ag2 = @course.assignment_groups.create!(:name => 'group2')
      @asmnt2 = @course.assignments.create!(:title => 'Assignment 2', :points_possible => 10, :assignment_group => @ag2)

      # verifies there were no export errors
      run_export

      # both assignments should be present, including the one with the link in the description
      check_resource_node(@asmnt, CC::CCHelper::LOR)
      check_resource_node(@asmnt2, CC::CCHelper::LOR)

      # both assignment groups should be present as well
      doc = Nokogiri::XML.parse(@zip_file.read("course_settings/assignment_groups.xml"))
      expect(doc.at_css("assignmentGroup[identifier=#{mig_id(@ag)}]")).not_to be_nil
      expect(doc.at_css("assignmentGroup[identifier=#{mig_id(@ag2)}]")).not_to be_nil
    end

    it "should not export syllabus if not selected" do
      @course.syllabus_body = "<p>Bodylicious</p>"

      @ce.selected_content = {
          :everything => "0"
      }
      @ce.save!

      run_export
      expect(@manifest_doc.at_css('resource[href="course_settings/syllabus.html"]')).to be_nil
    end

    it "should export syllabus when selected" do 
      @course.syllabus_body = "<p>Bodylicious</p>"

      @ce.selected_content = {
        :syllabus_body => "1"
      }
      @ce.save!

      run_export
      expect(@manifest_doc.at_css('resource[href="course_settings/syllabus.html"]')).not_to be_nil
    end

    it "should use canvas_export.txt as flag" do
      run_export

      expect(@manifest_doc.at_css('resource[href="course_settings/canvas_export.txt"]')).not_to be_nil
      expect(@zip_file.find_entry('course_settings/canvas_export.txt')).not_to be_nil
    end

    it "should not error if the course name is too long" do
      @course.name = "a" * Course.maximum_string_length

      run_export
    end

    it "should export media tracks" do
      stub_kaltura
      CanvasKaltura::ClientV3.any_instance.stubs(:startSession)
      CanvasKaltura::ClientV3.any_instance.stubs(:flavorAssetGetPlaylistUrl).returns('http://www.example.com/blah.flv')
      stub_request(:get, 'http://www.example.com/blah.flv').to_return(body: Tempfile.new('blah.flv'), status: 200)
      CC::CCHelper.stubs(:media_object_info).returns({asset: {id: 1, status: '2'}, filename: 'blah.flv'})
      obj = @course.media_objects.create! media_id: '0_deadbeef'
      track = obj.media_tracks.create! kind: 'subtitles', locale: 'tlh', content: "Hab SoSlI' Quch!"
      page = @course.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      page.body = %Q{<a id="media_comment_0_deadbeef" class="instructure_inline_media_comment video_comment"></a>}
      page.save!
      @ce.export_type = ContentExport::COMMON_CARTRIDGE
      @ce.save!
      run_export
      file_node = @manifest_doc.at_css("resource[identifier='id4164d7d594985594573e63f8ca15975'] file[href$='/blah.flv.tlh.subtitles']")
      expect(file_node).to be_present
      expect(@zip_file.read(file_node['href'])).to eql(track.content)
      track_doc = Nokogiri::XML(@zip_file.read('course_settings/media_tracks.xml'))
      expect(track_doc.at_css('media_tracks media track[locale=tlh][kind=subtitles][identifierref=id4164d7d594985594573e63f8ca15975]')).to be_present
    end

    it "should export CC 1.3 assignments" do
      @course.assignments.create! name: 'test assignment', description: '<em>what?</em>', points_possible: 11,
                                  submission_types: 'online_text_entry,online_upload,online_url'
      @ce.export_type = ContentExport::COMMON_CARTRIDGE
      @ce.save!
      run_export(version: '1.3')
      expect(@manifest_doc.at_css('metadata schemaversion').text).to eql('1.3.0')

      # validate assignment manifest resource
      assignment_resource = @manifest_doc.at_css("resource[type='assignment_xmlv1p0']")
      assignment_id = assignment_resource.attribute('identifier').value
      assignment_xml_file = assignment_resource.attribute('href').value
      expect(assignment_resource.at_css('file').attribute('href').value).to eq assignment_xml_file

      # validate cc1.3 assignment xml document
      assignment_xml_doc = Nokogiri::XML(@zip_file.read(assignment_xml_file))
      expect(assignment_xml_doc.at_css('text').text).to eq '<em>what?</em>'
      expect(assignment_xml_doc.at_css('text').attribute('texttype').value).to eq 'text/html'
      expect(assignment_xml_doc.at_css('gradable').text).to eq 'true'
      expect(assignment_xml_doc.at_css('gradable').attribute('points_possible').value).to eq '11'
      expect(assignment_xml_doc.css('submission_formats format').map{ |fmt| fmt.attribute('type').value }).to match_array %w(html file url)

      # validate presence of canvas extension node
      extension_node = assignment_xml_doc.at_css('extensions').elements.first
      expect(extension_node.name).to eq 'assignment'
      expect(extension_node.namespace.href).to eq 'http://canvas.instructure.com/xsd/cccv1p0'

      # validate fallback html manifest resource
      variant_tag = @manifest_doc.at_css(%Q{resource[identifier="#{assignment_id}_fallback"]}).elements.first
      expect(variant_tag.name).to eq 'variant'
      expect(variant_tag.attribute('identifierref').value).to eql assignment_id
      expect(variant_tag.next_element.name).to eq 'file'
      html_file = variant_tag.next_element.attribute('href').value
      expect(@zip_file.read("#{assignment_id}/test-assignment.html")).to be_include "<em>what?</em>"
    end

    it "should export unpublished modules and items" do
      cm1 = @course.context_modules.create!(name: "published module")
      cm1.publish
      cm2 = @course.context_modules.create!(name: "unpublished module")
      cm2.unpublish

      tag1_1 = cm1.add_item(type: 'external_url', title: 'unpub url', url: 'https://example.com')
      tag1_1.workflow_state = 'unpublished'
      tag1_1.save!
      tag1_2 = cm1.add_item(type: 'external_url', title: 'pub url', url: 'https://example.com')
      tag1_2.workflow_state = 'published'
      tag1_2.save!

      tag2_1 = cm2.add_item(type: 'external_url', title: 'unpub url 2', url: 'https://example.com')
      tag2_1.workflow_state = 'unpublished'
      tag2_1.save!

      @ce.export_type = ContentExport::COMMON_CARTRIDGE
      @ce.save!
      run_export

      expect(@manifest_doc.at_css("item[identifier=#{mig_id(tag1_1)}]")).not_to be_nil
      expect(@manifest_doc.at_css("item[identifier=#{mig_id(tag1_2)}]")).not_to be_nil
      expect(@manifest_doc.at_css("item[identifier=#{mig_id(tag2_1)}]")).not_to be_nil
    end

    it "should export file copyright information" do
      @att1 = Attachment.create!(:filename => 'first.png', :uploaded_data => StringIO.new('ohai1'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att1.usage_rights = @course.usage_rights.create! use_justification: 'fair_use', legal_copyright: '(C) 2014 Sienar Fleet Systems'
      @att1.save!

      @att2 = Attachment.create!(:filename => 'second.jpg', :uploaded_data => StringIO.new('ohai2'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att2.usage_rights = @course.usage_rights.create! use_justification: 'public_domain'
      @att2.save!

      @att3 = Attachment.create!(:filename => 'third.jpg', :uploaded_data => StringIO.new('ohai3'), :folder => Folder.unfiled_folder(@course), :context => @course)
      @att3.usage_rights = @course.usage_rights.create! use_justification: 'creative_commons', license: 'cc_by', legal_copyright: '(C) 2014 Corellian Engineering Corporation'
      @att3.save!

      @ce.export_type = ContentExport::COMMON_CARTRIDGE
      @ce.save!
      run_export

      # copyright only
      node1 = @manifest_doc.at_css('resource[href$="first.png"] lom|rights')
      expect(node1.at_css('lom|copyrightAndOtherRestrictions > lom|value').text).to eq('yes')
      expect(node1.at_css('lom|description > lom|string').text).to eq('(C) 2014 Sienar Fleet Systems')

      # license only
      node2 = @manifest_doc.at_css('resource[href$="second.jpg"] lom|rights')
      expect(node2.at_css('lom|copyrightAndOtherRestrictions > lom|value').text).to eq('no')
      expect(node2.at_css('lom|description > lom|string').text).to eq('Public Domain')

      # copyright and license
      node3 = @manifest_doc.at_css('resource[href$="third.jpg"] lom|rights')
      expect(node3.at_css('lom|copyrightAndOtherRestrictions > lom|value').text).to eq('yes')
      expect(node3.at_css('lom|description > lom|string').text).to eq('(C) 2014 Corellian Engineering Corporation\nCC Attribution')
    end
  end
end
