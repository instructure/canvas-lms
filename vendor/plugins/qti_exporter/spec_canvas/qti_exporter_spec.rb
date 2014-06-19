# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../../../spec/spec_helper')
require 'zip/filesystem'

if Qti.migration_executable

describe Qti::Converter do
  before do
    course_with_teacher(:active_all => true)
  end

  it "should import duplicate files once, without munging" do
    setup_migration
    do_migration

    @course.attachments.count.should == 2
    @course.attachments.map(&:filename).sort.should == ['header-logo.png', 'smiley.jpg']
    attachment = @course.attachments.detect { |a| a.filename == 'header-logo.png' }
    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.quiz_questions.count.should == 2
    quiz.quiz_questions.each do |q|
      text = Nokogiri::HTML::DocumentFragment.parse(q.question_data['question_text'])
      text.css('img').first['src'].should == "/courses/#{@course.id}/files/#{attachment.id}/preview"

      # verify that the associated assessment_question got links translated
      aq = q.assessment_question
      text = Nokogiri::HTML::DocumentFragment.parse(aq.question_data['question_text'])
      text.css('img').first['src'].should =~ %r{/assessment_questions/#{aq.id}/files/\d+/download\?verifier=\w+}

      if aq.question_data['answers'][1]["comments_html"] =~ /\<img/
        text = Nokogiri::HTML::DocumentFragment.parse(aq.question_data['answers'][1]["comments_html"])
        text.css('img').first['src'].should =~ %r{/assessment_questions/#{aq.id}/files/\d+/download\?verifier=\w+}
      end
    end
    quiz.assignment.should be_nil
  end

  it "should bring in canvas meta data" do
    setup_migration(File.expand_path("../fixtures/qti/canvas_qti.zip", __FILE__))
    do_migration
    @course.quizzes.count.should == 1
    @course.quizzes.first.description.should == "<p>Quiz Description</p>"
  end

  describe "applying respondus settings" do
    before do
      @copy = Tempfile.new(['spec-canvas', '.zip'])
      FileUtils.cp(fname, @copy.path)
      Zip::File.open(@copy.path) do |zf|
        zf.file.open("settings.xml", 'w') do |f|
          f.write <<-XML
          <settings>
            <setting name='hasSettings'>true</setting>
            <setting name='publishNow'>true</setting>
          </settings>
          XML
        end
      end
      setup_migration(@copy.path)
      @migration.update_migration_settings(:apply_respondus_settings_file => true)
      @migration.save!
    end

    it "should publish as assignment on import if specified" do
      do_migration

      quiz = @course.quizzes.last
      quiz.should be_present
      quiz.assignment.should_not be_nil
      quiz.assignment.title.should == quiz.title
      quiz.assignment.should be_published
    end

    it "should re-use the same assignment on update" do
      do_migration

      setup_migration(@copy.path)
      @migration.update_migration_settings(:apply_respondus_settings_file => true, :quiz_id_to_update => @course.quizzes.last.id)
      @migration.save!
      do_migration

      @course.quizzes.size.should == 1
      @course.assignments.size.should == 1
      quiz = @course.quizzes.last
      quiz.should be_present
      quiz.assignment.should_not be_nil
      quiz.assignment.title.should == quiz.title
      quiz.assignment.should be_published
    end

    it "should correctly set the assignment submission_type" do
      do_migration
      assign = @course.assignments.last
      assign.submission_types.should == 'online_quiz'
      assign.quiz.for_assignment?.should be_true
    end
  end

  it "should publish spec-canvas-1 correctly" do
    setup_migration
    do_migration

    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.quiz_questions.size.should == 2
    # various checks on the data
    qq = quiz.quiz_questions.first
    d = qq.question_data
    d['correct_comments'].should == "I can't believe you got that right. Awesome!"
    d['correct_comments_html'].should == "I can't <i>believe </i>you got that right. <b>Awesome!</b>"
    d['incorrect_comments_html'].should == "<b>Wrong. </b>That's a bummer."
    d['points_possible'].should == 3
    d['question_name'].should == 'q1'
    d['answers'].map { |a| a['weight'] }.should == [0,100,0]
    d['answers'].map { |a| a['comments'] }.should == ['nope', 'yes!', nil]
    attachment = @course.attachments.detect { |a| a.filename == 'smiley.jpg' }
    d['answers'].map { |a| a['comments_html'] }.should == [nil, %{yes! <img src="/courses/#{@course.id}/files/#{attachment.id}/preview" alt="">}, nil]
  end

  it "should import respondus question types" do
    setup_migration(File.expand_path("../fixtures/canvas_respondus_question_types.zip", __FILE__))
    do_migration

    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.should_not be_available
    quiz.quiz_questions.size.should == 9
    match_ignoring(quiz.quiz_questions.map(&:question_data), RESPONDUS_QUESTIONS, %w[id assessment_question_id match_id prepped_for_import question_bank_migration_id quiz_question_id])
  end

  it "should apply respondus settings" do
    setup_migration(File.expand_path("../fixtures/canvas_respondus_question_types.zip", __FILE__))
    @migration.update_migration_settings(:apply_respondus_settings_file => true)
    @migration.save!
    do_migration

    quiz = @course.quizzes.last
    quiz.should be_present
    quiz.should be_available
  end

  it "should be able to import directly into an assessment question bank" do
    setup_migration(File.expand_path("../fixtures/canvas_respondus_question_types.zip", __FILE__))
    @migration.update_migration_settings(:migration_ids_to_import =>
                                             { :copy => { :all_quizzes => false, :all_assessment_question_banks => true} })
    @migration.save!
    do_migration

    @course.quizzes.count.should == 0
    qb = @course.assessment_question_banks.last
    qb.should be_present
    qb.assessment_questions.size.should == 9
    data = qb.assessment_questions.map(&:question_data).sort_by!{|q| q["migration_id"]}
    match_ignoring(data, RESPONDUS_QUESTIONS, %w[id assessment_question_id match_id missing_links position prepped_for_import question_bank_migration_id quiz_question_id])
  end

  def match_ignoring(a, b, ignoring = [])
    case a
    when Hash
      a_ = a.reject { |k,v| ignoring.include?(k) }
      b_ = b.reject { |k,v| ignoring.include?(k) }
      a_.keys.sort.should == b_.keys.sort
      a_.each { |k,v| match_ignoring(v, b[k], ignoring) }
    when Array
      a.size.should == b.size
      a.each_with_index do |e,i|
        match_ignoring(e.to_hash, b[i], ignoring)
      end
    when Quizzes::QuizQuestion::QuestionData
      a.to_hash.should == b
    else
      a.should == b
    end
  end

  def fname
    File.expand_path("../fixtures/spec-canvas-1.zip", __FILE__)
  end

  def setup_migration(zip_path = fname)
    @migration = ContentMigration.new(:context => @course,
                                     :user => @user)
    @migration.update_migration_settings({
      :migration_type => 'qti_converter',
      :flavor => Qti::Flavors::RESPONDUS
    })
    @migration.save!

    @attachment = Attachment.new
    @attachment.context = @migration
    @attachment.uploaded_data = File.open(zip_path, 'rb')
    @attachment.filename = 'qti_import_test1.zip'
    @attachment.save!

    @migration.attachment = @attachment
    @migration.save!
  end

  def do_migration
    Canvas::Migration::Worker::QtiWorker.new(@migration.id).perform
    @migration.reload
    @migration.should be_imported
  end

  RESPONDUS_QUESTIONS =
    [{"position"=>1,
      "correct_comments"=>"This is the correct answer feedback",
      "question_type"=>"multiple_choice_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"18",
      "neutral_comments"=>"This is some general feedback.",
      "incorrect_comments"=>"This is the incorrect answer feedback",
      "migration_id"=>"QUE_1006",
      "points_possible"=>1.5,
      "question_name"=>"MC Question 1",
      "answers"=>
       [{"comments"=>"choice 1 feedback",
         "migration_id"=>"QUE_1008_A1",
         "text"=>"Answer choice 1",
         "weight"=>100,
         "id"=>304},
        {"comments"=>"choice 2 feedback",
         "migration_id"=>"QUE_1009_A2",
         "text"=>"Answer choice 2",
         "weight"=>0,
         "id"=>6301},
        {"comments"=>"choice 3 feedback",
         "migration_id"=>"QUE_1010_A3",
         "text"=>"Answer choice 3",
         "weight"=>0,
         "id"=>6546},
        {"comments"=>"choice 4 feedback",
         "migration_id"=>"QUE_1011_A4",
         "text"=>"Answer choice 4",
         "weight"=>0,
         "id"=>9001}],
      "question_text"=>
       "This is the question text.<br>\nThese are some symbol font characters: <span style=\"font-size: 12pt;\">∂♥∃Δƒ</span>"},
     {"position"=>2,
      "correct_comments"=>"correct answer feedback",
      "question_type"=>"true_false_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"19",
      "neutral_comments"=>"general feedback",
      "incorrect_comments"=>"incorrect answer feedback",
      "migration_id"=>"QUE_1019",
      "points_possible"=>1,
      "question_name"=>"TF Question 1",
      "answers"=>
       [{"comments"=>"true answer feedback",
         "migration_id"=>"QUE_1021_A1",
         "text"=>"True",
         "weight"=>100,
         "id"=>55},
        {"comments"=>"false answer feedback",
         "migration_id"=>"QUE_1022_A2",
         "text"=>"False",
         "weight"=>0,
         "id"=>3501}],
      "question_text"=>"This is the question wording."},
     {"position"=>3,
      "correct_comments"=>"correct feed",
      "question_type"=>"short_answer_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"20",
      "neutral_comments"=>"general feed",
      "incorrect_comments"=>"incorrect feed",
      "migration_id"=>"QUE_1028",
      "points_possible"=>1,
      "question_name"=>"FIB Question 1",
      "answers"=>
       [{"comments"=>"", "text"=>"correct answer 1", "weight"=>100, "id"=>4954},
        {"comments"=>"", "text"=>"correct answer 2", "weight"=>100, "id"=>6688}],
      "question_text"=>"This is the question text."},
     {"position"=>4,
      "correct_comments"=>"correct feed",
      "question_type"=>"fill_in_multiple_blanks_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"21",
      "neutral_comments"=>"general feed",
      "incorrect_comments"=>"incorrect feed",
      "migration_id"=>"QUE_1034",
      "points_possible"=>2,
      "question_name"=>"FIMB Question 1",
      "answers"=>
       [{"text"=>"question", "weight"=>100, "id"=>346, "blank_id"=>"a"},
        {"text"=>"interrogative", "weight"=>100, "id"=>7169, "blank_id"=>"a"},
        {"text"=>"Fill in Multiple Blanks",
         "weight"=>100,
         "id"=>1578,
         "blank_id"=>"b"}],
      "question_text"=>"This is the [a] wording for a [b] question."},
     {"position"=>5,
      "correct_comments"=>"correct feed",
      "question_type"=>"multiple_answers_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"22",
      "neutral_comments"=>"general feed",
      "incorrect_comments"=>"incorrect feed",
      "migration_id"=>"QUE_1038",
      "points_possible"=>2,
      "question_name"=>"MA Question 1",
      "answers"=>
       [{"comments"=>"choice feed 1",
         "migration_id"=>"QUE_1040_A1",
         "text"=>"This is incorrect answer 1",
         "weight"=>0,
         "id"=>1897},
        {"comments"=>"choice feed 2",
         "migration_id"=>"QUE_1041_A2",
         "text"=>"This is correct answer 1",
         "weight"=>100,
         "id"=>1865},
        {"comments"=>"choice feed 3",
         "migration_id"=>"QUE_1042_A3",
         "text"=>"This is incorrect answer 2",
         "weight"=>0,
         "id"=>8381},
        {"comments"=>"choice feed 4",
         "migration_id"=>"QUE_1043_A4",
         "text"=>"This is correct answer 2",
         "weight"=>100,
         "id"=>9111}],
      "question_text"=>"This is the question text."},
     {"position"=>6,
      "correct_comments"=>"correct feed",
      "question_type"=>"numerical_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"23",
      "neutral_comments"=>"general feed",
      "incorrect_comments"=>"incorrect feed",
      "migration_id"=>"QUE_1051",
      "points_possible"=>1,
      "question_name"=>"NA Question 1",
      "answers"=>
       [{"comments"=>"",
         "numerical_answer_type"=>"range_answer",
         "exact"=>1.25,
         "weight"=>100,
         "end"=>1.3,
         "id"=>9082,
         "start"=>1.2}],
      "question_text"=>"This is the question wording."},
     {"position"=>7,
      "correct_comments"=>"",
      "question_type"=>"text_only_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"24",
      "incorrect_comments"=>"",
      "migration_id"=>"QUE_1053",
      "points_possible"=>1,
      "question_name"=>"TX Question 1",
      "answers"=>[],
      "question_text"=>"This is the question wording."},
     {"position"=>8,
      "correct_comments"=>"",
      "question_type"=>"essay_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"25",
      "neutral_comments"=>"correct answer feedback",
      "incorrect_comments"=>"",
      "migration_id"=>"QUE_1054",
      "points_possible"=>1,
      "question_name"=>"ES Question 1",
      "answers"=>[],
      "question_text"=>"This is the question text."},
     {"position"=>9,
      "correct_comments"=>"correct feed",
      "question_type"=>"matching_question",
      "question_bank_name"=>"Instructure Question Types",
      "assessment_question_id"=>"26",
      "neutral_comments"=>"general feed",
      "incorrect_comments"=>"incorrect feed",
      "migration_id"=>"QUE_1061",
      "points_possible"=>1,
      "question_name"=>"MT Question 1",
      "answers"=>
       [{"comments"=>"",
         "match_id"=>342,
         "text"=>"Matching left side 1",
         "left"=>"Matching left side 1",
         "id"=>2740,
         "right"=>"Matching right side 1"},
        {"comments"=>"",
         "match_id"=>8808,
         "text"=>"Matching L2",
         "left"=>"Matching L2",
         "id"=>6479,
         "right"=>"Matching right side 2"},
        {"comments"=>"",
         "match_id"=>9565,
         "text"=>"Matching left side 3",
         "left"=>"Matching left side 3",
         "id"=>3074,
         "right"=>"Matching right side 3"},
        {"comments"=>"",
         "match_id"=>1142,
         "text"=>"Matching left side 4",
         "left"=>"Matching left side 4",
         "id"=>7696,
         "right"=>"Matching right side 4"}],
      "matches"=>
       [{"match_id"=>342, "text"=>"Matching right side 1"},
        {"match_id"=>8808, "text"=>"Matching right side 2"},
        {"match_id"=>9565, "text"=>"Matching right side 3"},
        {"match_id"=>1142, "text"=>"Matching right side 4"},
        {"match_id"=>5875, "text"=>"Distractor 1"},
        {"match_id"=>2330, "text"=>"Distractor 2"}],
      "question_text"=>"This is the question text."}]
end

end
