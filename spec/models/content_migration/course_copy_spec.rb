# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy" do
    include_examples "course copy"

    it "should show correct progress" do
      ce = @course.content_exports.build
      ce.export_type = ContentExport::COMMON_CARTRIDGE
      ce.content_migration = @cm
      @cm.content_export = ce
      ce.save!

      @cm.progress.should == nil
      @cm.workflow_state = 'exporting'

      ce.progress = 10
      @cm.progress.should == 4
      ce.progress = 50
      @cm.progress.should == 20
      ce.progress = 75
      @cm.progress.should == 30
      ce.progress = 100
      @cm.progress.should == 40

      @cm.progress = 10
      @cm.progress.should == 46
      @cm.progress = 50
      @cm.progress.should == 70
      @cm.progress = 80
      @cm.progress.should == 88
      @cm.progress = 100
      @cm.progress.should == 100
    end

    it "should migrate syllabus links on copy" do
      course_model

      topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<p>some text</p>")
      @copy_from.syllabus_body = "<a href='/courses/#{@copy_from.id}/discussion_topics/#{topic.id}'>link</a>"
      @copy_from.save!

      @cm.copy_options = {
        everything: false,
        all_syllabus_body: true,
        all_discussion_topics: true
      }
      @cm.save!
      run_course_copy

      new_topic = @copy_to.discussion_topics.find_by_migration_id(CC::CCHelper.create_key(topic))
      new_topic.should_not be_nil
      new_topic.message.should == topic.message
      @copy_to.syllabus_body.should match(/\/courses\/#{@copy_to.id}\/discussion_topics\/#{new_topic.id}/)
    end

    it "should copy course syllabus when the everything option is selected" do
      course_model

      @copy_from.syllabus_body = "What up"
      @copy_from.save!

      run_course_copy

      @copy_to.syllabus_body.should =~ /#{@copy_from.syllabus_body}/
    end

    it "should not migrate syllabus when not selected" do
      course_model
      @copy_from.syllabus_body = "<p>wassup</p>"

      @cm.copy_options = {
        :course => {'all_syllabus_body' => false}
      }
      @cm.save!

      run_course_copy

      @copy_to.syllabus_body.should == nil
    end

    it "should merge locked files and retain correct html links" do
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
      att.update_attribute(:hidden, true)
      att.reload.should be_hidden
      topic = @copy_from.discussion_topics.create!(:title => "some topic", :message => "<img src='/courses/#{@copy_from.id}/files/#{att.id}/preview'>")

      run_course_copy

      new_att = @copy_to.attachments.find_by_migration_id(CC::CCHelper.create_key(att))
      new_att.should_not be_nil

      new_topic = @copy_to.discussion_topics.find_by_migration_id(CC::CCHelper.create_key(topic))
      new_topic.should_not be_nil
      new_topic.message.should match(Regexp.new("/courses/#{@copy_to.id}/files/#{new_att.id}/preview"))
    end

    it "should keep date-locked files locked" do
      student = user
      @copy_from.enroll_student(student)
      att = Attachment.create!(:filename => 'test.txt', :display_name => "testing.txt", :uploaded_data => StringIO.new('file'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from, :lock_at => 1.month.ago, :unlock_at => 1.month.from_now)
      att.grants_right?(student, :download).should be_false

      run_course_copy

      @copy_to.enroll_student(student)
      new_att = @copy_to.attachments.find_by_migration_id(CC::CCHelper.create_key(att))
      new_att.should be_present

      new_att.grants_right?(student, :download).should be_false
    end

    it "should translate links to module items in html content" do
      mod1 = @copy_from.context_modules.create!(:name => "some module")
      asmnt1 = @copy_from.assignments.create!(:title => "some assignment")
      tag = mod1.add_item({:id => asmnt1.id, :type => 'assignment', :indent => 1})
      body = %{<p>Link to module item: <a href="/courses/%s/modules/items/%s">some assignment</a></p>}
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body % [@copy_from.id, tag.id])

      run_course_copy

      mod1_to = @copy_to.context_modules.find_by_migration_id(mig_id(mod1))
      tag_to = mod1_to.content_tags.first
      page_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page_to.body.should == body % [@copy_to.id, tag_to.id]
    end

    it "should be able to copy links to files in folders with html entities and unicode in path" do
      root_folder = Folder.root_folders(@copy_from).first
      folder1 = root_folder.sub_folders.create!(:context => @copy_from, :name => "mol&eacute;")
      att1 = Attachment.create!(:filename => "first.txt", :uploaded_data => StringIO.new('ohai'), :folder => folder1, :context => @copy_from)
      folder2 = root_folder.sub_folders.create!(:context => @copy_from, :name => "olé")
      att2 = Attachment.create!(:filename => "first.txt", :uploaded_data => StringIO.new('ohai'), :folder => folder2, :context => @copy_from)

      body = "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att1.id}/download'>link</a>"
      body += "<a class='instructure_file_link' href='/courses/#{@copy_from.id}/files/#{att2.id}/download'>link</a>"
      dt = @copy_from.discussion_topics.create!(:message => body, :title => "discussion title")
      page = @copy_from.wiki.wiki_pages.create!(:title => "some page", :body => body)

      run_course_copy

      att_to1 = @copy_to.attachments.find_by_migration_id(mig_id(att1))
      att_to2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))

      page_to = @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(page))
      page_to.body.include?("/courses/#{@copy_to.id}/files/#{att_to1.id}/download").should be_true
      page_to.body.include?("/courses/#{@copy_to.id}/files/#{att_to2.id}/download").should be_true

      dt_to = @copy_to.discussion_topics.find_by_migration_id(mig_id(dt))
      dt_to.message.include?("/courses/#{@copy_to.id}/files/#{att_to1.id}/download").should be_true
      dt_to.message.include?("/courses/#{@copy_to.id}/files/#{att_to2.id}/download").should be_true
    end

    it "should selectively copy items" do
      dt1 = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      dt2 = @copy_from.discussion_topics.create!(:message => "hey", :title => "discussion title 2")
      dt3 = @copy_from.announcements.create!(:message => "howdy", :title => "announcement title")
      cm = @copy_from.context_modules.create!(:name => "some module")
      cm2 = @copy_from.context_modules.create!(:name => "another module")
      att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      att2 = Attachment.create!(:filename => 'second.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      wiki2 = @copy_from.wiki.wiki_pages.create!(:title => "wiki2", :body => "ohais")
      data = [{:points => 3,:description => "Outcome row",:id => 1,:ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}]}]
      rub1 = @copy_from.rubrics.build(:title => "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      rub2 = @copy_from.rubrics.build(:title => "rub2")
      rub2.data = data
      rub2.save!
      rub2.associate_with(@copy_from, @copy_from)
      ef1 = @copy_from.external_feeds.create! feed_type: 'rss/atom', feed_purpose: 'announcements', url: 'https://feed1.example.org', verbosity: 'full'
      ef2 = @copy_from.external_feeds.create! feed_type: 'rss/atom', feed_purpose: 'announcements', url: 'https://feed2.example.org', verbosity: 'full'
      default = @copy_from.root_outcome_group
      log = @copy_from.learning_outcome_groups.new
      log.context = @copy_from
      log.title = "outcome group"
      log.description = "<p>Groupage</p>"
      log.save!
      default.adopt_outcome_group(log)

      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!

      log.add_outcome(lo)

      # only select one of each type
      @cm.copy_options = {
              :discussion_topics => {mig_id(dt1) => "1"},
              :announcements => {mig_id(dt3) => "1"},
              :context_modules => {mig_id(cm) => "1", mig_id(cm2) => "0"},
              :attachments => {mig_id(att) => "1", mig_id(att2) => "0"},
              :wiki_pages => {mig_id(wiki) => "1", mig_id(wiki2) => "0"},
              :rubrics => {mig_id(rub1) => "1", mig_id(rub2) => "0"},
              :external_feeds => {mig_id(ef1) => "1", mig_id(ef2) => "0"}
      }
      @cm.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).should_not be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt2)).should be_nil
      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt3)).should_not be_nil

      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).should_not be_nil
      @copy_to.context_modules.find_by_migration_id(mig_id(cm2)).should be_nil

      @copy_to.attachments.find_by_migration_id(mig_id(att)).should_not be_nil
      @copy_to.attachments.find_by_migration_id(mig_id(att2)).should be_nil

      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).should_not be_nil
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki2)).should be_nil

      @copy_to.rubrics.find_by_migration_id(mig_id(rub1)).should_not be_nil
      @copy_to.rubrics.find_by_migration_id(mig_id(rub2)).should be_nil

      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).should be_nil
      @copy_to.learning_outcome_groups.find_by_migration_id(mig_id(log)).should be_nil

      @copy_to.external_feeds.find_by_migration_id(mig_id(ef1)).should_not be_nil
      @copy_to.external_feeds.find_by_migration_id(mig_id(ef2)).should be_nil
    end

    it "should re-copy deleted items" do
      dt1 = @copy_from.discussion_topics.create!(:message => "hi", :title => "discussion title")
      cm = @copy_from.context_modules.create!(:name => "some module")
      att = Attachment.create!(:filename => 'first.txt', :uploaded_data => StringIO.new('ohai'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      wiki = @copy_from.wiki.wiki_pages.create!(:title => "wiki", :body => "ohai")
      quiz = @copy_from.quizzes.create! if Qti.qti_enabled?
      ag = @copy_from.assignment_groups.create!(:name => 'empty group')
      asmnt = @copy_from.assignments.create!(:title => "some assignment")
      cal = @copy_from.calendar_events.create!(:title => "haha", :description => "oi")
      tool = @copy_from.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
      tool.workflow_state = 'public'
      tool.save
      data = [{:points => 3,:description => "Outcome row",:id => 1,:ratings => [{:points => 3,:description => "Rockin'",:criterion_id => 1,:id => 2}]}]
      rub1 = @copy_from.rubrics.build(:title => "rub1")
      rub1.data = data
      rub1.save!
      rub1.associate_with(@copy_from, @copy_from)
      default = @copy_from.root_outcome_group
      lo = @copy_from.created_learning_outcomes.new
      lo.context = @copy_from
      lo.short_description = "outcome1"
      lo.workflow_state = 'active'
      lo.data = {:rubric_criterion=>{:mastery_points=>2, :ratings=>[{:description=>"e", :points=>50}, {:description=>"me", :points=>2}, {:description=>"Does Not Meet Expectations", :points=>0.5}], :description=>"First outcome", :points_possible=>5}}
      lo.save!
      default.add_outcome(lo)
      gs = @copy_from.grading_standards.new
      gs.title = "Standard eh"
      gs.data = [["A", 0.93], ["A-", 0.89], ["B+", 0.85], ["B", 0.83], ["B!-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0]]
      gs.save!

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).destroy
      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).destroy
      @copy_to.attachments.find_by_migration_id(mig_id(att)).destroy
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).destroy
      @copy_to.rubrics.find_by_migration_id(mig_id(rub1)).destroy
      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).destroy
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).destroy if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).destroy
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).destroy
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).destroy
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).destroy
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).destroy

      @cm = ContentMigration.create!(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )

      run_course_copy

      @copy_to.discussion_topics.find_by_migration_id(mig_id(dt1)).workflow_state.should == 'active'
      @copy_to.context_modules.find_by_migration_id(mig_id(cm)).workflow_state.should == 'active'
      @copy_to.attachments.count.should == 1
      @copy_to.attachments.find_by_migration_id(mig_id(att)).file_state.should == 'available'
      @copy_to.wiki.wiki_pages.find_by_migration_id(mig_id(wiki)).workflow_state.should == 'active'
      rub2 = @copy_to.rubrics.find_by_migration_id(mig_id(rub1))
      rub2.workflow_state.should == 'active'
      rub2.rubric_associations.first.bookmarked.should == true
      @copy_to.created_learning_outcomes.find_by_migration_id(mig_id(lo)).workflow_state.should == 'active'
      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).workflow_state.should == 'created' if Qti.qti_enabled?
      @copy_to.context_external_tools.find_by_migration_id(mig_id(tool)).workflow_state.should == 'public'
      @copy_to.assignment_groups.find_by_migration_id(mig_id(ag)).workflow_state.should == 'available'
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).workflow_state.should == asmnt.workflow_state
      @copy_to.grading_standards.find_by_migration_id(mig_id(gs)).workflow_state.should == 'active'
      @copy_to.calendar_events.find_by_migration_id(mig_id(cal)).workflow_state.should == 'active'
    end

    it "should copy course attributes" do
      #set all the possible values to non-default values
      @copy_from.start_at = 5.minutes.ago
      @copy_from.conclude_at = 1.month.from_now
      @copy_from.is_public = false
      @copy_from.name = "haha copy from test &amp;"
      @copy_from.course_code = 'something funny'
      @copy_from.allow_student_wiki_edits = true
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
      @copy_from.locale = "es"
      @copy_from.tab_configuration = [{"id"=>0}, {"id"=>14}, {"id"=>8}, {"id"=>5}, {"id"=>6}, {"id"=>2}, {"id"=>3, "hidden"=>true}]
      @copy_from.hide_final_grades = true
      gs = make_grading_standard(@copy_from)
      @copy_from.grading_standard = gs
      @copy_from.grading_standard_enabled = true
      @copy_from.save!

      run_course_copy

      #compare settings
      @copy_to.conclude_at.should == nil
      @copy_to.start_at.should == nil
      @copy_to.storage_quota.should == 444
      @copy_to.hide_final_grades.should == true
      @copy_to.grading_standard_enabled.should == true
      gs_2 = @copy_to.grading_standards.find_by_migration_id(mig_id(gs))
      gs_2.data.should == gs.data
      @copy_to.grading_standard.should == gs_2
      @copy_to.name.should == "tocourse"
      @copy_to.course_code.should == "tocourse"
      atts = Course.clonable_attributes
      atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS
      atts.each do |att|
        @copy_to.send(att).should == @copy_from.send(att)
      end
      @copy_to.tab_configuration.should == @copy_from.tab_configuration
    end

    it "should convert domains in imported urls if specified in account settings" do
      account = @copy_to.root_account
      account.settings[:default_migration_settings] = {:domain_substitution_map => {"http://derp.derp" => "https://derp.derp"}}
      account.save!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag1 = mod.add_item({ :title => 'Example 1', :type => 'external_url', :url => 'http://derp.derp/something' })
      tool = @copy_from.context_external_tools.create!(:name => "b", :url => "http://derp.derp/somethingelse", :consumer_key => '12345', :shared_secret => 'secret')
      tag2 = mod.add_item :type => 'context_external_tool', :id => tool.id, :url => "#{tool.url}?queryyyyy=something"

      @copy_from.syllabus_body = "<p><a href=\"http://derp.derp/stuff\">this is a link to an insecure domain that could cause problems</a></p>"

      run_course_copy

      tool_to = @copy_to.context_external_tools.find_by_migration_id(mig_id(tool))
      tool_to.url.should == tool.url.sub("http://derp.derp", "https://derp.derp")
      tag1_to = @copy_to.context_module_tags.find_by_migration_id(mig_id(tag1))
      tag1_to.url.should == tag1.url.sub("http://derp.derp", "https://derp.derp")
      tag2_to = @copy_to.context_module_tags.find_by_migration_id(mig_id(tag2))
      tag2_to.url.should == tag2.url.sub("http://derp.derp", "https://derp.derp")

      @copy_to.syllabus_body.should == @copy_from.syllabus_body.sub("http://derp.derp", "https://derp.derp")
    end

    it "should preserve media comment links" do
      pending unless Qti.qti_enabled?

      @copy_from.media_objects.create!(:media_id => '0_12345678')
      @copy_from.syllabus_body = <<-HTML.strip
      <p>
        Hello, students.<br>
        With associated media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
        Without associated media object: <a id="media_comment_0_12345678" class="instructure_inline_media_comment video_comment" href="/media_objects/0_12345678">this is a media comment</a>
        another type: <a id="media_comment_0_bq09qam2" class="instructure_inline_media_comment video_comment" href="/courses/#{@copy_from.id}/file_contents/course%20files/media_objects/0_bq09qam2">this is a media comment</a>
      </p>
      HTML

      run_course_copy

      @copy_to.syllabus_body.should == @copy_from.syllabus_body.gsub("/courses/#{@copy_from.id}/file_contents/course%20files",'')
    end

    it "should re-use kaltura media objects" do
      expect {
        media_id = '0_deadbeef'
        @copy_from.media_objects.create!(:media_id => media_id)
        att = Attachment.create!(:filename => 'video.mp4', :uploaded_data => StringIO.new('pixels and frames and stuff'), :folder => Folder.root_folders(@copy_from).first, :context => @copy_from)
        att.media_entry_id = media_id
        att.content_type = "video/mp4"
        att.save!

        run_course_copy

        @copy_to.attachments.find_by_migration_id(mig_id(att)).media_entry_id.should == media_id
      }.to change { Delayed::Job.jobs_count(:tag, 'MediaObject.add_media_files') }.by(0)
    end

    it "should import calendar events" do
      body_with_link = "<p>Watup? <strong>eh?</strong><a href=\"/courses/%s/assignments\">Assignments</a></p>"
      cal = @copy_from.calendar_events.new
      cal.title = "Calendar event"
      cal.description = body_with_link % @copy_from.id
      cal.start_at = 1.week.from_now
      cal.save!
      cal.all_day = true
      cal.save!
      cal2 = @copy_from.calendar_events.new
      cal2.title = "Stupid events"
      cal2.start_at = 5.minutes.from_now
      cal2.end_at = 10.minutes.from_now
      cal2.all_day = false
      cal2.save!
      cal3 = @copy_from.calendar_events.create!(:title => "deleted event")
      cal3.destroy

      run_course_copy

      @copy_to.calendar_events.count.should == 2
      cal_2 = @copy_to.calendar_events.find_by_migration_id(CC::CCHelper.create_key(cal))
      cal_2.title.should == cal.title
      cal_2.start_at.to_i.should == cal.start_at.to_i
      cal_2.end_at.to_i.should == cal.end_at.to_i
      cal_2.all_day.should == true
      cal_2.all_day_date.should == cal.all_day_date
      cal_2.description = body_with_link % @copy_to.id

      cal2_2 = @copy_to.calendar_events.find_by_migration_id(CC::CCHelper.create_key(cal2))
      cal2_2.title.should == cal2.title
      cal2_2.start_at.to_i.should == cal2.start_at.to_i
      cal2_2.end_at.to_i.should == cal2.end_at.to_i
      cal2_2.description.should == ''
    end
  end
end
