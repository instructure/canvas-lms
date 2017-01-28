#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AssessmentQuestion do
  before :once do
    course_factory
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
  end

  def attachment_in_course(course)
    Attachment.create!(
      :filename => 'test.jpg',
      :display_name => "test.jpg",
      :uploaded_data => StringIO.new('psych!'),
      :folder => Folder.unfiled_folder(course),
      :context => course
    )
  end
  
  it "should create a new instance given valid attributes" do
    assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))
  end

  it "should infer_defaults from question_data before validation" do
    @question = assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))
    @question.name = "1" * 300
    @question.save(validate: false)
    expect(@question.name.length).to eq 300

    @question.question_data[:question_name] = "valid name"
    @question.save!
    expect(@question).to be_valid
    expect(@question.name).to eq @question.question_data[:question_name]
  end

  it "should translate links to be readable when creating the assessment question" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data['question_text']).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should translate links relative path url" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data['question_text']).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should handle existing query string parameters" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi",
            'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg?wrap=1'>",
            'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data['question_text']).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'>"
  end

  it "should translate multiple links in same body" do
    @attachment = attachment_in_course(@course)

    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data['question_text']).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should translate links to be readable w/ verifier" do
    @attachments = {}
    attachment_tag = lambda {|key|
      @attachments[key] ||= []
      a = @course.attachments.build(:filename => "foo-#{key}.gif")
      a.content_type = 'image/gif'
      a.save!
      @attachments[key] << a
      "<img src=\"/courses/#{@course.id}/files/#{a.id}/download\">"
    }
    data = {
      :name => 'test question',
      :question_type => 'multiple_choice_question',
      :question_text => "which ones are like this one? #{attachment_tag.call("[:question_text]")} what about: #{attachment_tag.call("[:question_text]")}",
      :correct_comments => "yay! #{attachment_tag.call("[:correct_comments]")}",
      :incorrect_comments => "boo! #{attachment_tag.call("[:incorrect_comments]")}",
      :neutral_comments => "meh. #{attachment_tag.call("[:neutral_comments]")}",
      :text_after_answers => "oh btw #{attachment_tag.call("[:text_after_answers]")}",
      :answers => [
        { :weight => 1, :text => "A",
          :html => "A #{attachment_tag.call("[:answers][0][:html]")}",
          :comments_html => "yeppers #{attachment_tag.call("[:answers][0][:comments_html]")}" },
        { :weight => 1, :text => "B",
          :html => "B #{attachment_tag.call("[:answers][1][:html]")}",
          :comments_html => "yeppers #{attachment_tag.call("[:answers][1][:comments_html]")}" }
      ]
    }

    serialized_data_before = Marshal.dump(data)

    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment_clones = Hash[@attachments.map{|k, ary| [k, ary.map {|a| @question.attachments.where(root_attachment_id: a).first}]}]

    @attachment_clones.each do |key, ary|
      string = eval "@question.question_data#{key}"
      matches = string.scan %r{/assessment_questions/\d+/files/\d+/download\?verifier=\w+}
      expect(matches.length).to eq ary.length
      matches.each_with_index do |match, index|
        a = ary[index]
        expect(match).to eq "/assessment_questions/#{@question.id}/files/#{a.id}/download\?verifier=#{a.uuid}"
      end
    end
    
    # the original data hash should not have changed during the link translation
    serialized_data_after = Marshal.dump(data)
    expect(serialized_data_before).to eq serialized_data_after
  end
  
  it "should not modify the question_data hash in place when translating links" do
    
  end
  
  it "should not drop non-string/array/hash data types when translate links" do
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    
    data = {
            :name => 'mc question',
            :question_type => 'multiple_choice_question',
            :question_text => "text text text",
            :points_possible => "10",
            :correct_comments => "",
            :incorrect_comments => "",
            :answers => {
                    "answer_0" => {:answer_weight => 100, :answer_text => "1", :id => "0", :answer_comments => "hi there"}
            }
    }

    question = bank.assessment_questions.create!(:question_data => data)
    expect(question.question_data[:points_possible]).to eq "10"
    data[:points_possible] = "50"
    question.form_question_data = data
    question.save
    expect(question.question_data.class).to eq HashWithIndifferentAccess
    expect(question.question_data[:points_possible]).to eq 50
    expect(question.question_data[:answers][0][:weight]).to eq 100
    expect(question.question_data[:answers][0][:id]).not_to be_nil
    expect(question.question_data[:assessment_question_id]).to eq question.id
  end
  
  it "should always return a HashWithIndifferentAccess and allow editing" do
    data = {
            :name => 'mc question',
            :question_type => 'multiple_choice_question',
            :question_text => "text text text",
            :points_possible => "10",
            :answers => {
                    "answer_0" => {:answer_weight => 100, :answer_text => "1", :id => "0", :answer_comments => "hi there"}
            }
    }

    question = @bank.assessment_questions.create!(:question_data => data)
    expect(question.question_data.class).to eq HashWithIndifferentAccess
    
    question.question_data = data
    expect(question.question_data.class).to eq HashWithIndifferentAccess
    
    data = question.question_data
    data[:name] = "new name"
    
    expect(question.question_data[:name]).to eq "new name"
    expect(data.object_id).to eq question.question_data.object_id
  end

  describe '.find_or_create_quiz_questions' do
    let(:assessment_question){assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))}
    let(:quiz){quiz_model}

    it 'should create a quiz_question when one does not exist' do
      expect do
        AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil)
      end.to change{Quizzes::QuizQuestion.count}.by(1)
    end

    it 'should find an existing quiz_question' do
      qq = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first

      expect do
        qq2 = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first
        expect(qq2.id).to eql(qq.id)
      end.to_not change{AssessmentQuestion.count}
    end

    it 'should find and update an out of date quiz_question' do
      aq = assessment_question
      qq = AssessmentQuestion.find_or_create_quiz_questions([aq], quiz.id, nil).first

      aq = AssessmentQuestion.find(aq)
      aq.name = 'changed'
      aq.with_versioning(&:save!)

      expect(qq.assessment_question_version).to_not eql(aq.version_number)

      qq2 = AssessmentQuestion.find_or_create_quiz_questions([aq], quiz.id, nil).first
      aq = AssessmentQuestion.find(aq)
      expect(qq.assessment_question_version).to_not eql(qq2.assessment_question_version)
      expect(qq2.assessment_question_version).to eql(aq.version_number)
    end

    it "grabs the first match by ID order" do
      # consistent ordering is good for preventing deadlocks
      questions = []
      3.times { questions << assessment_question.create_quiz_question(quiz.id) }
      smallest_id_question = questions.sort_by(&:id).first
      qq = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first
      expect(qq.id).to eq(smallest_id_question.id)
    end
  end
end
