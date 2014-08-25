require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy quizzes" do
    include_examples "course copy"

    it "should copy a quiz when assignment is selected" do
      pending unless Qti.qti_enabled?
      @quiz = @copy_from.quizzes.create!
      @quiz.did_edit
      @quiz.offer!
      @quiz.assignment.should_not be_nil

      @cm.copy_options = {
        :assignments => {mig_id(@quiz.assignment) => "1"},
        :quizzes => {mig_id(@quiz) => "0"},
      }
      @cm.save!

      run_course_copy

      @copy_to.quizzes.find_by_migration_id(mig_id(@quiz)).should_not be_nil
    end

    it "should create a new assignment and module item if copying a new quiz (even if the assignment migration_id matches)" do
      pending unless Qti.qti_enabled?
      quiz = @copy_from.quizzes.create!(:title => "new quiz")
      quiz2 = @copy_to.quizzes.create!(:title => "already existing quiz")

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})

      [quiz, quiz2].each do |q|
        q.did_edit
        q.offer!
      end

      a = quiz2.assignment
      a.migration_id = mig_id(quiz.assignment)
      a.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["already existing quiz", "new quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["already existing quiz", "new quiz"]
      @copy_to.context_module_tags.map(&:title).should == ["new quiz"]
    end

    it "should not duplicate quizzes and associated items if overwrite_quizzes is true" do
      pending unless Qti.qti_enabled?
      # overwrite_quizzes should now default to true for course copy and canvas import

      quiz = @copy_from.quizzes.create!(:title => "published quiz")
      quiz2 = @copy_from.quizzes.create!(:title => "unpublished quiz")
      quiz.did_edit
      quiz.offer!
      quiz2.unpublish!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})
      tag2 = mod.add_item({:id => quiz2.id, :type => 'quiz'})

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["published quiz", "unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["published quiz", "unpublished quiz"]

      @copy_to.quizzes.find_by_title("published quiz").should_not be_unpublished
      @copy_to.quizzes.find_by_title("unpublished quiz").should be_unpublished

      quiz.title = "edited published quiz"
      quiz.save!
      quiz2.title = "edited unpublished quiz"
      quiz2.save!

      # run again
      @cm = ContentMigration.new(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["edited published quiz", "edited unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["edited published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["edited published quiz", "edited unpublished quiz"]

      @copy_to.quizzes.find_by_title("edited published quiz").should_not be_unpublished
      @copy_to.quizzes.find_by_title("edited unpublished quiz").should be_unpublished
    end

    it "should duplicate quizzes and associated items if overwrite_quizzes is false" do
      pending unless Qti.qti_enabled?
      quiz = @copy_from.quizzes.create!(:title => "published quiz")
      quiz2 = @copy_from.quizzes.create!(:title => "unpublished quiz")
      quiz.did_edit
      quiz2.did_edit
      quiz.offer!

      mod = @copy_from.context_modules.create!(:name => "some module")
      tag = mod.add_item({:id => quiz.id, :type => 'quiz'})
      tag2 = mod.add_item({:id => quiz2.id, :type => 'quiz'})

      run_course_copy

      # run again
      @cm = ContentMigration.new(
        :context => @copy_to,
        :user => @user,
        :source_course => @copy_from,
        :migration_type => 'course_copy_importer',
        :copy_options => {:everything => "1"}
      )
      @cm.user = @user
      @cm.migration_settings[:import_immediately] = true
      @cm.migration_settings[:overwrite_quizzes] = false
      @cm.save!

      run_course_copy

      @copy_to.quizzes.map(&:title).sort.should == ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
      @copy_to.assignments.map(&:title).sort.should == ["published quiz", "published quiz"]
      @copy_to.context_module_tags.map(&:title).sort.should == ["published quiz", "published quiz", "unpublished quiz", "unpublished quiz"]
    end

    it "should have correct question count on copied surveys and practive quizzes" do
      pending unless Qti.qti_enabled?
      sp = @copy_from.quizzes.create!(:title => "survey pub", :quiz_type => "survey")
      data = {
                          :question_type => "multiple_choice_question",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :text => "<br />", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :text => "<pre>", :weight => 0, :id => 2279}]}.with_indifferent_access
      qq = sp.quiz_questions.create!
      qq.write_attribute(:question_data, data)
      qq.save!
      sp.generate_quiz_data
      sp.published_at = Time.now
      sp.workflow_state = 'available'
      sp.save!

      sp.question_count.should == 1

      run_course_copy

      q = @copy_to.quizzes.find_by_migration_id(mig_id(sp))
      q.should_not be_nil
      q.question_count.should == 1
    end

    it "should not mix up quiz questions and assessment questions with the same ids" do
      pending unless Qti.qti_enabled?
      quiz1 = @copy_from.quizzes.create!(:title => "quiz 1")
      quiz2 = @copy_from.quizzes.create!(:title => "quiz 1")

      qq1 = quiz1.quiz_questions.create!(:question_data => {'question_name' => 'test question 1', 'answers' => [{'id' => 1}, {'id' => 2}]})
      qq2 = quiz2.quiz_questions.create!(:question_data => {'question_name' => 'test question 2', 'answers' => [{'id' => 1}, {'id' => 2}]})
      Quizzes::QuizQuestion.where(:id => qq1).update_all(:assessment_question_id => qq2.id)

      run_course_copy

      newquiz2 = @copy_to.quizzes.find_by_migration_id(mig_id(quiz2))
      newquiz2.quiz_questions.first.question_data['question_name'].should == 'test question 2'
    end

    it "should generate numeric ids for answers" do
      pending unless Qti.qti_enabled?

      q = @copy_from.quizzes.create!(:title => "test quiz")
      mc = q.quiz_questions.create!
      mc.write_attribute(:question_data, {
          points_possible: 1,
          question_type: "multiple_choice_question",
          question_name: "mc",
          name: "mc",
          question_text: "what is your favorite color?",
          answers: [{ text: 'blue', weight: 0, id: 123 },
                    { text: 'yellow', weight: 100, id: 456 }]
      }.with_indifferent_access)
      mc.save!
      tf = q.quiz_questions.create!
      tf.write_attribute(:question_data, {
          points_possible: 1,
          question_type: "true_false_question",
          question_name: "tf",
          name: "tf",
          question_text: "this statement is false.",
          answers: [{ text: "True", weight: 100, id: 9608 },
                    { text: "False", weight: 0, id: 9093 }]
      }.with_indifferent_access)
      tf.save!
      q.generate_quiz_data
      q.workflow_state = 'available'
      q.save!

      run_course_copy

      q2 = @copy_to.quizzes.find_by_migration_id(mig_id(q))
      q2.quiz_data.size.should eql(2)
      ans_count = 0
      q2.quiz_data.each do |qd|
        qd["answers"].each do |ans|
          ans["id"].should be_a(Integer)
          ans_count += 1
        end
      end
      ans_count.should eql(4)
    end

    it "should copy quizzes as published if they were published before" do
      pending unless Qti.qti_enabled?
      g = @copy_from.assignment_groups.create!(:name => "new group")
      asmnt_unpub = @copy_from.quizzes.create!(:title => "asmnt unpub", :quiz_type => "assignment", :assignment_group_id => g.id)
      asmnt_pub = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => g.id)
      asmnt_pub.workflow_state = 'available'
      asmnt_pub.save!
      graded_survey_unpub = @copy_from.quizzes.create!(:title => "graded survey unpub", :quiz_type => "graded_survey", :assignment_group_id => g.id)
      graded_survey_pub = @copy_from.quizzes.create(:title => "grade survey pub", :quiz_type => "graded_survey", :assignment_group_id => g.id)
      graded_survey_pub.workflow_state = 'available'
      graded_survey_pub.save!
      survey_unpub = @copy_from.quizzes.create!(:title => "survey unpub", :quiz_type => "survey")
      survey_pub = @copy_from.quizzes.create(:title => "survey pub", :quiz_type => "survey")
      survey_pub.workflow_state = 'available'
      survey_pub.save!
      practice_unpub = @copy_from.quizzes.create!(:title => "practice unpub", :quiz_type => "practice_quiz")
      practice_pub = @copy_from.quizzes.create(:title => "practice pub", :quiz_type => "practice_quiz")
      practice_pub.workflow_state = 'available'
      practice_pub.save!

      run_course_copy

      [asmnt_unpub, asmnt_pub, graded_survey_unpub, graded_survey_pub, survey_pub, survey_unpub, practice_unpub, practice_pub].each do |orig|
        q = @copy_to.quizzes.find_by_migration_id(mig_id(orig))
        "#{q.title} - #{q.workflow_state}".should == "#{orig.title} - #{orig.workflow_state}" # titles in there to help identify what type failed
        q.quiz_type.should == orig.quiz_type
      end
    end

    it "should export quizzes with groups that point to external banks" do
      pending unless Qti.qti_enabled?
      course_with_teacher(:user => @user)
      different_course = @course
      different_account = Account.create!

      q1 = @copy_from.quizzes.create!(:title => 'quiz1')
      bank = different_course.assessment_question_banks.create!(:title => 'bank')
      bank2 = @copy_from.account.assessment_question_banks.create!(:title => 'bank2')
      bank2.assessment_question_bank_users.create!(:user => @user)
      bank3 = different_account.assessment_question_banks.create!(:title => 'bank3')
      group = q1.quiz_groups.create!(:name => "group", :pick_count => 3, :question_points => 5.0)
      group.assessment_question_bank = bank
      group.save
      group2 = q1.quiz_groups.create!(:name => "group2", :pick_count => 5, :question_points => 2.0)
      group2.assessment_question_bank = bank2
      group2.save
      group3 = q1.quiz_groups.create!(:name => "group3", :pick_count => 5, :question_points => 2.0)
      group3.assessment_question_bank = bank3
      group3.save

      run_course_copy(["User didn't have permission to reference question bank in quiz group Question Group"])

      q = @copy_to.quizzes.find_by_migration_id(mig_id(q1))
      q.should_not be_nil
      q.quiz_groups.count.should == 3
      g = q.quiz_groups[0]
      g.assessment_question_bank_id.should == bank.id
      g = q.quiz_groups[1]
      g.assessment_question_bank_id.should == bank2.id
      g = q.quiz_groups[2]
      g.assessment_question_bank_id.should == nil
    end

    it "should omit deleted questions in banks" do
      pending unless Qti.qti_enabled?
      bank1 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      q1 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]})
      q2 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question 2', 'answers' => [{'id' => 3}, {'id' => 4}]})
      q3 = bank1.assessment_questions.create!(:question_data => {'name' => 'test question 3', 'answers' => [{'id' => 5}, {'id' => 6}]})
      q2.destroy

      run_course_copy

      bank2 = @copy_to.assessment_question_banks.first
      bank2.should be_present
      # we don't copy over deleted questions at all, not even marked as deleted
      bank2.assessment_questions.active.size.should == 2
      bank2.assessment_questions.size.should == 2
    end

    it "should not copy plain text question comments as html" do
      pending unless Qti.qti_enabled?
      bank1 = @copy_from.assessment_question_banks.create!(:title => 'bank')
      q = bank1.assessment_questions.create!(:question_data => {
          "question_type" => "multiple_choice_question", 'name' => 'test question',
          'answers' => [{'id' => 1, "text" => "Correct", "weight" => 100, "comments" => "another comment"},
                        {'id' => 2, "text" => "inorrect", "weight" => 0}],
          "correct_comments" => "Correct answer comment", "incorrect_comments" => "Incorrect answer comment",
          "neutral_comments" => "General Comment", "more_comments" => "even more comments"
      })

      run_course_copy

      q2 = @copy_to.assessment_questions.first
      ["correct_comments_html", "incorrect_comments_html", "neutral_comments_html", "more_comments_html"].each do |k|
        q2.question_data.keys.should_not include(k)
      end
      q2.question_data["answers"].each do |a|
        a.keys.should_not include("comments_html")
      end
    end

    it "should not copy deleted assignment attached to quizzes" do
      pending unless Qti.qti_enabled?
      g = @copy_from.assignment_groups.create!(:name => "new group")
      quiz = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => g.id)
      quiz.workflow_state = 'available'
      quiz.save!

      asmnt = quiz.assignment

      quiz.quiz_type = 'practice_quiz'
      quiz.save!

      asmnt.workflow_state = 'deleted'
      asmnt.save!

      run_course_copy

      @copy_to.quizzes.find_by_migration_id(mig_id(quiz)).should_not be_nil
      @copy_to.assignments.find_by_migration_id(mig_id(asmnt)).should be_nil
    end

    it "should copy all quiz attributes" do
      pending unless Qti.qti_enabled?
      q = @copy_from.quizzes.create!(
              :title => 'quiz',
              :description => "<p>description eh</p>",
              :shuffle_answers => true,
              :show_correct_answers => true,
              :time_limit => 20,
              :allowed_attempts => 4,
              :scoring_policy => 'keep_highest',
              :quiz_type => 'survey',
              :access_code => 'code',
              :anonymous_submissions => true,
              :hide_results => 'until_after_last_attempt',
              :ip_filter => '192.168.1.1',
              :require_lockdown_browser => true,
              :require_lockdown_browser_for_results => true,
              :notify_of_update => true,
              :one_question_at_a_time => true,
              :cant_go_back => true,
              :require_lockdown_browser_monitor => true,
              :lockdown_browser_monitor_data => 'VGVzdCBEYXRhCg==',
      )

      run_course_copy

      new_quiz = @copy_to.quizzes.first

      [:title, :description, :points_possible, :shuffle_answers,
       :show_correct_answers, :time_limit, :allowed_attempts, :scoring_policy, :quiz_type,
       :access_code, :anonymous_submissions,
       :hide_results, :ip_filter, :require_lockdown_browser,
       :require_lockdown_browser_for_results, :require_lockdown_browser_monitor,
       :lockdown_browser_monitor_data].each do |prop|
        new_quiz.send(prop).should == q.send(prop)
      end

    end

    it "should leave file references in AQ context as-is on copy" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      @attachment = attachment_with_context(@copy_from)
      @attachment2 = @attachment = Attachment.create!(:filename => 'test.jpg', :display_name => "test.jpg", :uploaded_data => StringIO.new('psych!'), :folder => Folder.unfiled_folder(@copy_from), :context => @copy_from)
      data = {"name" => "Hi", "question_text" => <<-HTML.strip, "answers" => [{"id" => 1}, {"id" => 2}]}
      File ref:<img src="/courses/#{@copy_from.id}/files/#{@attachment.id}/download">
      different file ref: <img src="/courses/#{@copy_from.id}/file_contents/course%20files/unfiled/test.jpg">
      media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
      equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
      link to some other course: <a href="/courses/#{@copy_from.id + @copy_to.id}">Cool Course</a>
      canvas image: <img style="max-width: 723px;" src="/images/preview.png" alt="">
      HTML
      @question = @bank.assessment_questions.create!(:question_data => data)
      @question.reload.question_data['question_text'].should =~ %r{/assessment_questions/}

      run_course_copy

      bank = @copy_to.assessment_question_banks.first
      bank.assessment_questions.count.should == 1
      aq = bank.assessment_questions.first

      aq.question_data['question_text'].should match_ignoring_whitespace(@question.question_data['question_text'])
    end

    it "should correctly copy quiz question html file references" do
      pending unless Qti.qti_enabled?
      root = Folder.root_folders(@copy_from).first
      folder = root.sub_folders.create!(:context => @copy_from, :name => 'folder 1')
      att = Attachment.create!(:filename => 'first.jpg', :display_name => "first.jpg", :uploaded_data => StringIO.new('first'), :folder => root, :context => @copy_from)
      att2 = Attachment.create!(:filename => 'test.jpg', :display_name => "test.jpg", :uploaded_data => StringIO.new('second'), :folder => root, :context => @copy_from)
      att3 = Attachment.create!(:filename => 'testing.jpg', :display_name => "testing.jpg", :uploaded_data => StringIO.new('test this'), :folder => root, :context => @copy_from)
      att4 = Attachment.create!(:filename => 'sub_test.jpg', :display_name => "sub_test.jpg", :uploaded_data => StringIO.new('sub_folder'), :folder => folder, :context => @copy_from)
      qtext = <<-HTML.strip
File ref:<img src="/courses/%s/files/%s/download">
different file ref: <img src="/courses/%s/%s">
subfolder file ref: <img src="/courses/%s/%s">
media object: <a id="media_comment_0_l4l5n0wt" class="instructure_inline_media_comment video_comment" href="/media_objects/0_l4l5n0wt">this is a media comment</a>
equation: <img class="equation_image" title="Log_216" src="/equation_images/Log_216" alt="Log_216">
        HTML

      data = {:correct_comments_html => "<strong>correct</strong>",
                    :question_type => "multiple_choice_question",
                    :question_name => "test fun",
                    :name => "test fun",
                    :points_possible => 10,
                    :question_text => qtext % [@copy_from.id, att.id, @copy_from.id, "file_contents/course%20files/test.jpg", @copy_from.id, "file_contents/course%20files/folder%201/sub_test.jpg"],
                    :answers =>
                            [{:migration_id => "QUE_1016_A1", :html => %{File ref:<img src="/courses/#{@copy_from.id}/files/#{att3.id}/download">}, :comments_html =>'<i>comment</i>', :text => "", :weight => 100, :id => 8080},
                             {:migration_id => "QUE_1017_A2", :html => "<strong>html answer 2</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access

      q1 = @copy_from.quizzes.create!(:title => 'quiz1')
      qq = q1.quiz_questions.create!
      qq.write_attribute(:question_data, data)
      qq.save!

      run_course_copy

      @copy_to.attachments.count.should == 4
      att_2 = @copy_to.attachments.find_by_migration_id(mig_id(att))
      att2_2 = @copy_to.attachments.find_by_migration_id(mig_id(att2))
      att3_2 = @copy_to.attachments.find_by_migration_id(mig_id(att3))
      att4_2 = @copy_to.attachments.find_by_migration_id(mig_id(att4))

      q_to = @copy_to.quizzes.first
      qq_to = q_to.active_quiz_questions.first
      qq_to.question_data[:question_text].should match_ignoring_whitespace(qtext % [@copy_to.id, att_2.id, @copy_to.id, "files/#{att2_2.id}/preview", @copy_to.id, "files/#{att4_2.id}/preview"])
      qq_to.question_data[:answers][0][:html].should match_ignoring_whitespace(%{File ref:<img src="/courses/#{@copy_to.id}/files/#{att3_2.id}/download">})
    end

    it "should copy all html fields in assessment questions" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {:correct_comments_html => "<strong>correct</strong>",
                          :question_type => "multiple_choice_question",
                          :incorrect_comments_html => "<strong>incorrect</strong>",
                          :neutral_comments_html => "<strong>meh</strong>",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :html => "<strong>html answer 1</strong>", :comments_html =>'<i>comment</i>', :text => "", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :html => "<span style=\"color: #808000;\">html answer 2</span>", :comments_html =>'<i>comment</i>', :text => "", :weight => 0, :id => 2279}]}.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(:question_data => data)
      data2 = data.clone
      data2[:question_text] = "<i>matching yo</i>"
      data2[:question_type] = 'matching_question'
      data2[:matches] = [{:match_id=>4835, :text=>"a", :html => '<i>a</i>'},
                        {:match_id=>6247, :text=>"b", :html => '<i>a</i>'}]
      data2[:answers][0][:match_id] = 4835
      data2[:answers][0][:left_html] = data2[:answers][0][:html]
      data2[:answers][0][:right] = "a"
      data2[:answers][1][:match_id] = 6247
      data2[:answers][1][:right] = "b"
      data2[:answers][1][:left_html] = data2[:answers][1][:html]
      aq_from2 = @bank.assessment_questions.create!(:question_data => data2)

      run_course_copy

      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from1))

      aq.question_data[:question_text].should == data[:question_text]
      aq.question_data[:answers][0][:html].should == data[:answers][0][:html]
      aq.question_data[:answers][0][:comments_html].should == data[:answers][0][:comments_html]
      aq.question_data[:answers][1][:html].should == data[:answers][1][:html]
      aq.question_data[:answers][1][:comments_html].should == data[:answers][1][:comments_html]
      aq.question_data[:correct_comments_html].should == data[:correct_comments_html]
      aq.question_data[:incorrect_comments_html].should == data[:incorrect_comments_html]
      aq.question_data[:neutral_comments_html].should == data[:neutral_comments_html]

      # and the matching question
      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from2))
      aq.question_data[:answers][0][:html].should == data2[:answers][0][:html]
      aq.question_data[:answers][0][:left_html].should == data2[:answers][0][:left_html]
      aq.question_data[:answers][1][:html].should == data2[:answers][1][:html]
      aq.question_data[:answers][1][:left_html].should == data2[:answers][1][:left_html]
    end

    it "should copy file_upload_questions" do
      pending unless Qti.qti_enabled?
      bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {:question_type => "file_upload_question",
              :points_possible => 10,
              :question_text => "<strong>html for fun</strong>"
              }.with_indifferent_access
      bank.assessment_questions.create!(:question_data => data)

      q = @copy_from.quizzes.create!(:title => "survey pub", :quiz_type => "survey")
      q.quiz_questions.create!(:question_data => data)
      q.generate_quiz_data
      q.published_at = Time.now
      q.workflow_state = 'available'
      q.save!

      run_course_copy

      @copy_to.assessment_questions.count.should == 2
      @copy_to.assessment_questions.each do |aq|
        aq.question_data['question_type'].should == data[:question_type]
        aq.question_data['question_text'].should == data[:question_text]
      end

      @copy_to.quizzes.count.should == 1
      quiz = @copy_to.quizzes.first
      quiz.active_quiz_questions.size.should == 1

      qq = quiz.active_quiz_questions.first
      qq.question_data['question_type'].should == data[:question_type]
      qq.question_data['question_text'].should == data[:question_text]
    end

    it "should leave text answers as text" do
      pending unless Qti.qti_enabled?
      @bank = @copy_from.assessment_question_banks.create!(:title => 'Test Bank')
      data = {
                          :question_type => "multiple_choice_question",
                          :question_name => "test fun",
                          :name => "test fun",
                          :points_possible => 10,
                          :question_text => "<strong>html for fun</strong>",
                          :answers =>
                                  [{:migration_id => "QUE_1016_A1", :text => "<br />", :weight => 100, :id => 8080},
                                   {:migration_id => "QUE_1017_A2", :text => "<pre>", :weight => 0, :id => 2279}]}.with_indifferent_access
      aq_from1 = @bank.assessment_questions.create!(:question_data => data)

      run_course_copy

      aq = @copy_to.assessment_questions.find_by_migration_id(mig_id(aq_from1))

      aq.question_data[:answers][0][:text].should == data[:answers][0][:text]
      aq.question_data[:answers][1][:text].should == data[:answers][1][:text]
      aq.question_data[:answers][0][:html].should be_nil
      aq.question_data[:answers][1][:html].should be_nil
      aq.question_data[:question_text].should == data[:question_text]
    end

    it "should retain imported quiz questions in their original assessment question banks" do
      pending unless Qti.qti_enabled?

      data = {'question_name' => 'test question 1', 'question_type' => 'essay_question', 'question_text' => 'blah'}

      aqb = @copy_from.assessment_question_banks.create!(:title => "oh noes")
      aq = aqb.assessment_questions.create!(:question_data => data)

      data['points_possible'] = 2
      quiz = @copy_from.quizzes.create!(:title => "ruhroh")
      qq = quiz.quiz_questions.create!(:question_data => data, :assessment_question => aq)

      run_course_copy

      aqb2 = @copy_to.assessment_question_banks.find_by_migration_id(mig_id(aqb))
      aqb2.assessment_questions.count.should == 1

      quiz2 = @copy_to.quizzes.find_by_migration_id(mig_id(quiz))
      quiz2.quiz_questions.count.should == 1
      qq2 = quiz2.quiz_questions.first
      qq2.assessment_question_id.should == aqb2.assessment_questions.first.id
      qq2.question_data['points_possible'].should == qq.question_data['points_possible']
    end

    it "should copy the assignment group in selective copy" do
      pending unless Qti.qti_enabled?

      group = @copy_from.assignment_groups.create!(:name => "new group")
      quiz = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => group.id)
      quiz.publish!
      @cm.copy_options = { 'everything' => '0', 'quizzes' => { mig_id(quiz) => "1" } }
      run_course_copy
      dest_quiz = @copy_to.quizzes.find_by_migration_id mig_id(quiz)
      dest_quiz.assignment_group.migration_id.should eql mig_id(group)
    end

    it "should not copy the assignment group in selective export" do
      pending unless Qti.qti_enabled?

      group = @copy_from.assignment_groups.create!(:name => "new group")
      quiz = @copy_from.quizzes.create(:title => "asmnt", :quiz_type => "assignment", :assignment_group_id => group.id)
      quiz.publish!
      # test that we neither export nor reference the assignment group
      decoy_assignment_group = @copy_to.assignment_groups.create!(:name => "decoy")
      decoy_assignment_group.update_attribute(:migration_id, mig_id(group))
      run_export_and_import do |export|
        export.selected_content = { 'quizzes' => { mig_id(quiz) => "1" } }
      end
      dest_quiz = @copy_to.quizzes.find_by_migration_id mig_id(quiz)
      dest_quiz.assignment_group.migration_id.should_not eql decoy_assignment_group
      decoy_assignment_group.reload.name.should_not eql group.name
    end
  end
end
