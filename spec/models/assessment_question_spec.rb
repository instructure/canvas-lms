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
    course
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
    @question.name.length.should == 300

    @question.question_data[:question_name] = "valid name"
    @question.save!
    @question.should be_valid
    @question.name.should == @question.question_data[:question_name]
  end

  it "should translate links to be readable when creating the assessment question" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment.reload.cloned_item.attachments.length.should == 2
    @clone = @attachment.cloned_item.attachments.last

    @question.reload.question_data['question_text'].should == "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should translate links relative path url" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment.reload.cloned_item.attachments.length.should == 2
    @clone = @attachment.cloned_item.attachments.last

    @question.reload.question_data['question_text'].should == "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should handle existing query string parameters" do
    @attachment = attachment_in_course(@course)
    data = {'name' => "Hi",
            'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg?wrap=1'>",
            'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment.reload.cloned_item.attachments.length.should == 2
    @clone = @attachment.cloned_item.attachments.last

    @question.reload.question_data['question_text'].should == "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'>"
  end

  it "should translate multiple links in same body" do
    @attachment = attachment_in_course(@course)

    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment.reload.cloned_item.attachments.length.should == 2
    @clone = @attachment.cloned_item.attachments.last

    @question.reload.question_data['question_text'].should == "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
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

    @attachments.each {|k, ary| ary.each {|a| a.reload; a.cloned_item.attachments.length.should == 2 } }
    @attachment_clones = Hash[@attachments.map{|k, ary| [k, ary.map {|a| a.cloned_item.attachments.last }]}]

    @attachment_clones.each do |key, ary|
      string = eval "@question.question_data#{key}"
      matches = string.scan %r{/assessment_questions/\d+/files/\d+/download\?verifier=\w+}
      matches.length.should == ary.length
      matches.each_with_index do |match, index|
        a = ary[index]
        match.should == "/assessment_questions/#{@question.id}/files/#{a.id}/download\?verifier=#{a.uuid}"
      end
    end
    
    # the original data hash should not have changed during the link translation
    serialized_data_after = Marshal.dump(data)
    serialized_data_before.should == serialized_data_after
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
    question.question_data[:points_possible].should == "10"
    data[:points_possible] = "50"
    question.form_question_data = data
    question.save
    question.question_data.class.should == HashWithIndifferentAccess
    question.question_data[:points_possible].should == 50
    question.question_data[:answers][0][:weight].should == 100
    question.question_data[:answers][0][:id].should_not be_nil
    question.question_data[:assessment_question_id].should == question.id
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
    question.question_data.class.should == HashWithIndifferentAccess
    
    question.question_data = data
    question.question_data.class.should == HashWithIndifferentAccess
    
    data = question.question_data
    data[:name] = "new name"
    
    question.question_data[:name].should == "new name"
    data.object_id.should == question.question_data.object_id
  end
  
end
