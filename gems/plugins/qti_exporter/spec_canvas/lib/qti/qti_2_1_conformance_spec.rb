require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable

  # QTI conformancec packages from http://www.imsglobal.org/developers/apipalliance/conformance/QTIconformanceresources.cfm
  describe "QTI 2.1 zip" do
    def import_fixture(filename)
      archive_file_path = File.join(BASE_FIXTURE_DIR, 'qti2_conformance', filename)
      unzipped_file_path = File.join(File.dirname(archive_file_path), "qti_#{File.basename(archive_file_path, '.zip')}", 'oi')
      @export_folder = File.join(File.dirname(archive_file_path), "qti_#{filename}".gsub('.zip', ''))
      @course = Course.create!(:name => filename)
      @migration = ContentMigration.create(:context => @course)

      @converter = Qti::Converter.new(:export_archive_path => archive_file_path, :base_download_dir => unzipped_file_path, :content_migration => @migration)
      @converter.export
      @course_data = @converter.course.with_indifferent_access
      @course_data['all_files_export'] ||= {}
      @course_data['all_files_export']['file_path'] = @course_data['all_files_zip']

      @migration.migration_settings[:migration_ids_to_import] = {:copy => {}}
      @migration.migration_settings[:files_import_root_path] = @course_data[:files_import_root_path]
      Importers::CourseContentImporter.import_content(@course, @course_data, nil, @migration)

      expect(@migration.migration_issues).to be_empty
    end

    after :each do
      if @export_folder && File.exist?(@export_folder)
        FileUtils::rm_rf(@export_folder)
      end
    end

    it "should import VE_IP_01" do
      import_fixture('VE_IP_01.zip')
      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first
      expect(q.name).to eq "QTI v2.1 Entry Profile Single T/F Item Test Instance"

      expect(q.question_data['question_text']).to include("Answer the following question.")
      expect(q.question_data['question_text']).to include("Sigmund Freud and Carl Jung both belong to the psychoanalytic school of psychology.")

      expect(q.question_data['question_type']).to eq 'multiple_choice_question'
      expect(q.question_data['answers'].count).to eq 2
      answers = q.question_data['answers'].sort_by{|h| h['migration_id']}
      expect(answers.map{|a| a['text']}.sort).to eq ['False', 'True']
      expect(answers.map{|a| a['weight']}.sort).to eq [0, 100]
    end

    it "should import VE_IP_02" do
      import_fixture('VE_IP_02.zip')

      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first
      expect(q.attachments.count).to eq 1
      att = q.attachments.first

      expect(q.name).to eq "QTI v2.1 Entry Profile Single MC/SR Item Test Instance"

      ["<img id=\"figure1\" height=\"165\" width=\"250\" src=\"/assessment_questions/#{q.id}/files/#{att.id}/download?verifier=#{att.uuid}\" alt=\"Figure showing Rectangle ABCD divided into 12 equal boxes. 4 of the boxes are shaded.\">",
        "<span id=\"labelA\">A</span>", "<span id=\"labelB\">B</span>", "<span id=\"labelC\">C</span>", "<span id=\"labelD\">D</span>",
        "In the figure above, what fraction of the rectangle <em>ABCD</em> is", "shaded?"
      ].each do |text|
        expect(q.question_data['question_text']).to include(text)
      end

      expect(q.question_data['question_type']).to eq 'multiple_choice_question'
      answers = q.question_data['answers'].sort_by{|h| h['migration_id']}
      expect(answers.count).to eq 5
      expect(answers.map{|h| h['weight']}).to eq [0, 0, 0, 100, 0]
    end

    it "should import VE_IP_03" do
      import_fixture('VE_IP_03.zip')
      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first

      expect(q.name).to eq "QTI v2.1 Entry Profile Single MC/MR Item Test Instance"
      expect(q.question_data['question_text'].split("\n").map(&:strip)).to eq [
        "<span id=\"a\">Ms. Smith's class contains 24 students. </span>",
        "<span id=\"b\">Each student voted for his or her favorite color. </span>",
        "<span id=\"c\">The result of the class vote is shown </span>",
        "<span id=\"z\">in the table below.</span>", "<br>",
        "Indicate which of the following statements are accurate."
      ]


      expect(q.question_data['question_type']).to eq 'multiple_answers_question'
      answers = q.question_data['answers'].sort_by{|h| h['migration_id']}
      expect(answers.count).to eq 5
      expect(answers.map{|h| h['weight']}).to eq [100, 100, 0, 100, 0]
      expect(answers.map{|h| h['text']}).to eq [
        "The majority of students voted for Red.",
        "Twice as many students voted for Red a voted for Blue.",
        "Two percent of students voted for Yellow.",
        "Red received more votes than any other color.",
        "Twenty-five percent of students voted for Green."
      ]
    end

    it "should import VE_IP_04" do
      import_fixture('VE_IP_04.zip')
      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first

      expect(q.name).to eq "QTI v2.1 Entry Profile Single FIB Item Test Instance"
      expect(q.question_data['question_text']).to include("Canada and the United States share 4 out of the 5 Great Lakes in central North America.")
      expect(q.question_data['question_text']).to include("Which lake is entirely within the boundaries of the United States?")
      expect(q.question_data['question_text']).to include("Type your answer here: [RESPONSE]")

      expect(q.question_data['question_type']).to eq 'fill_in_multiple_blanks_question'
      expect(q.question_data['answers'].count).to eq 1
      answer = q.question_data['answers'].first
      expect(answer['weight']).to eq 100
      expect(answer['text']).to eq 'Lake Michigan'
      expect(answer['blank_id']).to eq 'RESPONSE'
    end

    it "should import VE_IP_05" do
      import_fixture('VE_IP_05.zip')
      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first

      expect(q.name).to eq "QTI v2.1 Entry Profile Single Essay Item Test Instance"

      expect(q.attachments.count).to eq 3
      q.attachments.each do |att|
        expect(q.question_data['question_text']).to include("src=\"/assessment_questions/#{q.id}/files/#{att.id}/download?verifier=#{att.uuid}\"")
      end

      expect(q.question_data['question_type']).to eq 'essay_question'
      expect(q.question_data['answers'].count).to eq 0
    end

    it "should import VE_IP_06" do
      skip('hotspot questions')
      import_fixture('VE_IP_06.zip')
    end

    it "should import VE_IP_07" do
      import_fixture('VE_IP_07.zip')
      expect(@course.quizzes.count).to eq 0
      expect(@course.assessment_questions.count).to eq 1
      q = @course.assessment_questions.first

      expect(q.name).to eq "QTI v2.1 Core Profile Single Pattern Match Item Test Instance"
      expect(q.question_data['question_text'].split("\n").map(&:strip).select{|s| s.length > 0}).to eq [
        "Match the following characters to the Shakespeare play they appeared in:",
        "Capulet", "Demetrius", "Lysander", "Prospero",
        "A Midsummer-Night's Dream", "Romeo and Juliet", "The Tempest"
      ]

      expect(q.question_data['question_type']).to eq 'matching_question'
      answers = q.question_data['answers'].sort_by{|h| h['text']}
      expect(answers.count).to eq 4
      matches = q.question_data['matches']
      expect(matches.count).to eq 3

      expect(answers.map{|h| h['text']}).to eq ["Capulet", "Demetrius", "Lysander", "Prospero"]
      expect(answers.map{|h| h['right']}).to eq [
        "Romeo and Juliet",
        "A Midsummer-Night's Dream",
        "A Midsummer-Night's Dream",
        "The Tempest"
      ]

      answers.each do |h|
        match = matches.detect{|m| m['match_id'] == h['match_id']}
        expect(match['text']).to eq h['right']
      end
    end

    it "should import VE_IP_11" do
      import_fixture('VE_IP_11.zip')
      expect(@course.assessment_questions.count).to eq 5
      expect(@course.assessment_questions.map{|q| q.question_data['question_type']}.sort).to eq [
        "essay_question",
        "fill_in_multiple_blanks_question",
        "multiple_answers_question",
        "multiple_choice_question",
        "multiple_choice_question"
      ]
    end

    it "should import VE_TP_01" do
      import_fixture('VE_TP_01.zip')
      expect(@course.assessment_questions.count).to eq 1
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 2

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_type']).to eq 'text_only_question'
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance"

      question = quiz.quiz_questions.detect{|q| q.position == 2}
      expect(question.question_data['question_type']).to eq 'multiple_choice_question'
      expect(question.assessment_question_id).to eq @course.assessment_questions.first.id
    end

    it "should import VE_TP_02" do
      import_fixture('VE_TP_02.zip')
      expect(@course.assessment_questions.count).to eq 1
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 2

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_type']).to eq 'text_only_question'
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance"

      question = quiz.quiz_questions.detect{|q| q.position == 2}
      expect(question.question_data['question_type']).to eq 'multiple_choice_question'
      expect(question.assessment_question_id).to eq @course.assessment_questions.first.id
    end

    it "should import VE_TP_03" do
      import_fixture('VE_TP_03.zip')
      expect(@course.assessment_questions.count).to eq 1
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 2

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_type']).to eq 'text_only_question'
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance"

      question = quiz.quiz_questions.detect{|q| q.position == 2}
      expect(question.question_data['question_type']).to eq 'multiple_answers_question'
      expect(question.assessment_question_id).to eq @course.assessment_questions.first.id
    end

    it "should import VE_TP_04" do
      import_fixture('VE_TP_04.zip')
      expect(@course.assessment_questions.count).to eq 1
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 2

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_type']).to eq 'text_only_question'
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance"

      question = quiz.quiz_questions.detect{|q| q.position == 2}
      expect(question.question_data['question_type']).to eq 'fill_in_multiple_blanks_question'
      expect(question.assessment_question_id).to eq @course.assessment_questions.first.id
    end

    it "should import VE_TP_05" do
      import_fixture('VE_TP_05.zip')
      expect(@course.assessment_questions.count).to eq 1
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 2

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_type']).to eq 'text_only_question'
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance"

      question = quiz.quiz_questions.detect{|q| q.position == 2}
      expect(question.question_data['question_type']).to eq 'essay_question'
      expect(question.assessment_question_id).to eq @course.assessment_questions.first.id
    end

    it "should import VE_TP_06" do
      import_fixture('VE_TP_06.zip')
      expect(@course.assessment_questions.count).to eq 5
      expect(@course.quizzes.count).to eq 1
      quiz = @course.quizzes.first
      expect(quiz.quiz_questions.count).to eq 6

      header = quiz.quiz_questions.detect{|q| q.position == 1}
      expect(header.question_data['question_text']).to eq "QTI v2.1 Entry Profile Single Section Instance with Multiple Items"

      questions = quiz.quiz_questions.sort_by(&:position)
      expect(questions.map{|q| q.question_data['question_type']}).to eq [
        "text_only_question", "multiple_choice_question", "multiple_choice_question",
        "multiple_answers_question", "fill_in_multiple_blanks_question", "essay_question"
      ]
      expect(questions.select{|q| q.position > 1}.map(&:assessment_question_id).sort).to eq @course.assessment_questions.map(&:id).sort
    end

  end
end
