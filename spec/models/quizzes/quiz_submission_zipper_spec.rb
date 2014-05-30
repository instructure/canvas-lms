require File.expand_path File.dirname(__FILE__) + '/../../spec_helper.rb'

describe Quizzes::QuizSubmissionZipper do

  let(:attachments) do
    [
      stub(:id => 1,:display_name => "Foobar.ppt"),
      stub(:id => 2, :display_name => "Cats.docx"),
      stub(:id => 3)
    ]
  end
  let(:submissions) do
    [
      stub(:user => stub(:id => 1,:last_name_first => "Dale Tom"),
          :submission_data => [{
            :attachment_ids => ["1"],
            :question_id => 1}]),
      stub(:user => stub(:id => 2, :last_name_first => "Florence Ryan"),
           :submission_data =>[{
              :question_id => 2,
              :attachment_ids => ["2"]}]),
      stub(:user => stub,:submission_data => {})
    ]
  end

  let(:submission_stubs) do
    submissions.map { |sub| stub(:latest_submitted_attempt => sub) }
  end
  let(:zip_attachment) { stub(:id => 1, :user => nil) }

  before :each do
    @student = course_with_student
    @quiz = course_quiz !!:active
    @quiz.stubs(:quiz_submissions).returns submission_stubs
    Attachment.stubs(:where).with(:id => ["1","2"]).returns [attachments.first,attachments.second]
    @zipper = Quizzes::QuizSubmissionZipper.new(:quiz => @quiz,
                                       :zip_attachment => zip_attachment)
  end

  describe "#initialize" do

    it "finds the submissions for the given quiz" do
      @zipper.submissions.should == submissions
    end

    it "stores the passed zip attachment" do
      @zipper.zip_attachment.should == zip_attachment
    end

    it "finds and stores attachments for all the submissions" do
      @zipper.attachments.should == {
        1 => attachments.first,
        2 => attachments.second
      }
    end

    it "sets the filename" do
      @zipper.filename.should ==
        "#{@quiz.context.short_name_slug}-#{@quiz.title} submissions"
    end
  end

  describe "#attachments_with_filenames" do

    it "returns the correct attachment and file name for each attachment" do
      @zipper.attachments_with_filenames.should == [
        [attachments.first, "dale_tom1_question_1_1_Foobar.ppt"],
        [attachments.second, "florence_ryan2_question_2_2_Cats.docx"]
      ]
    end
  end

  describe "#zip!" do

    it "creates a zip file with all the necessary info" do
      Attachment.unstub(:where)
      course_with_student :active_all => true
      student = @student
      quiz = course_quiz !!:active
      question = quiz.quiz_questions.create! :question_data => {
        :name => 'q1', :points_possible => 1,
        :question_type => 'file_upload_question',
        :question_text => 'ohai mark'
      }
      quiz.generate_quiz_data
      quiz.save!
      submission = quiz.generate_submission @student
      attach = create_attachment_for_file_upload_submission!(submission)
      submission.submission_data["question_#{question.id}".to_sym] = [ attach.id.to_s ]
      submission.save!
      Quizzes::SubmissionGrader.new(submission).grade_submission
      quiz.reload
      attachment = quiz.attachments.build(:filename => 'submissions.zip',
                                  :display_name => 'submissions.zip')
      attachment.workflow_state = 'to_be_zipped'; attachment.save!
      teacher = teacher_in_course(:course => @course,:active_all => true)
      Quizzes::QuizSubmissionZipper.new(
        quiz: quiz,
        zip_attachment: attachment).zip!
      attachment.reload
      attachment.should be_zipped
      names = []
      Zip::File.foreach(attachment.full_filename) { |f| names << f.name }
      names.length.should == 1
      names.first.should == "user#{student.id}_question_#{question.id}_#{attach.id}_#{attach.display_name}"
    end
  end
end
