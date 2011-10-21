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
  
  it "should create a new instance given valid attributes" do
    assessment_question_model
  end

  it "should translate links to be readable when creating the assessment question" do
    course
    @bank = @course.assessment_question_banks.create!(:title => 'Test Bank')

    @attachment = attachment_with_context(@course)
    data = {'name' => "Hi", 'question_text' => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'>", 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment.reload.cloned_item.attachments.length.should == 2
    @clone = @attachment.cloned_item.attachments.last

    @question.reload.question_data['question_text'].should == "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "should translate links to be readable w/ verifier" do
    course
    @bank = @course.assessment_question_banks.create!(:title=>'Test Bank')

    data = {'name' => 'test question', 'answers' => [{'id' => 1}, {'id' => 2}]}
    @question = @bank.assessment_questions.create!(:question_data => data)

    @attachment1 = attachment_with_context(@course)
    @attachment2 = attachment_with_context(@course)

    data['question_text'] = "This url should be translated: <img src='/courses/#{@course.id}/files/#{@attachment1.id}/download'> and so should this one: <img src='/courses/#{@course.id}/files/#{@attachment2.id}/download'>"
    @question.question_data = data
    @question.save

    @attachment1.reload
    @attachment2.reload
    @question.reload

    @attachment1.cloned_item.attachments.length.should == 2
    @attachment2.cloned_item.attachments.length.should == 2
    @clone1 = @attachment1.cloned_item.attachments.last
    @clone2 = @attachment2.cloned_item.attachments.last

    @question.question_data['question_text'].should match %r{'/assessment_questions/#{@question.id}/files/#{@clone1.id}/download\?verifier=#{@clone1.uuid}'.*'/assessment_questions/#{@question.id}/files/#{@clone2.id}/download\?verifier=#{@clone2.uuid}'}
  end
end
