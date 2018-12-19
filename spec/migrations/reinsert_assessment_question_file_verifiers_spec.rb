#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe 'DataFixup::ReinsertAssessmentQuestionFileVerifiers' do
  it "should work" do
    course_factory
    @att1 = attachment_with_context(@course)
    @att2 = attachment_with_context(@course)
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    aq = bank.assessment_questions.create!(:question_data => {
      :question_type => 'essay_question',
      :question_text =>
        "File refs:
        <img src=\"/courses/#{@course.id}/files/#{@att1.id}/download\">
        <img src=\"/courses/#{@course.id}/files/#{@att2.id}/download\">"})

    aq_atts = aq.attachments.to_a
    expect(aq_atts.count).to eq 2

    original_text = aq.reload.question_data['question_text']
    expect(original_text).to include("verifier=")

    stripped_text = original_text.dup
    aq_atts.each do |aq_att|
      stripped_text.gsub!("verifier=#{aq_att.uuid}", "")
    end
    expect(stripped_text).to_not include("verifier=")
    expect(stripped_text).to include("assessment_questions/#{aq.id}/files")
    aq.question_data["question_text"] = stripped_text
    aq.save!

    @quiz = @course.quizzes.create!
    linked_question = @quiz.quiz_questions.create!(:question_data => aq.question_data, :assessment_question_id => aq.id)
    @quiz.reload.publish!
    expect(@quiz.reload.quiz_data.first["question_text"]).to eq stripped_text

    DataFixup::ReinsertAssessmentQuestionFileVerifiers.run

    expect(@quiz.reload.quiz_data.first["question_text"]).to eq original_text
    expect(linked_question.reload.question_data["question_text"]).to eq original_text
  end

  it "should be able to fix the broken yaml with another fixup" do
    course_factory
    @att1 = attachment_with_context(@course)
    bank = @course.assessment_question_banks.create!(:title=>'Test Bank')
    aq = bank.assessment_questions.create!(:question_data => {
      :question_type => 'essay_question',
      :question_text =>
        "File refs:
        <img src=\"/courses/#{@course.id}/files/#{@att1.id}/download\">
        <img src=\"/courses/#{@course.id}/files/#{@att1.id}/download?some_query=1\">
        Here's a whole lot of weird ol' yaml with a whole lot of text\n
        that for some reason causes it to do something different but i can't figure\n
        out what exactly about it does that but it somehow involves unicode\n
        hey look here's some random unicode there 𝐶𝐶=3.5𝑝𝑝\n
        i hope it doesn't ruin everything
        "})

    aq_att = aq.attachments.first

    original_text = aq.reload.question_data['question_text']
    # the fixup will append the verifier so just rearrange them now
    original_text.sub!("verifier=#{aq_att.uuid}&some_query=1", "some_query=1&verifier=#{aq_att.uuid}")

    stripped_text = original_text.dup
    stripped_text.gsub!("&verifier=#{aq_att.uuid}", "").gsub!("verifier=#{aq_att.uuid}", "")

    expect(stripped_text).to_not include("verifier=")
    expect(stripped_text).to include("assessment_questions/#{aq.id}/files")
    aq.question_data["question_text"] = stripped_text
    aq.save!

    @quiz = @course.quizzes.create!
    linked_question = @quiz.quiz_questions.create!(:question_data => aq.question_data, :assessment_question_id => aq.id)
    @quiz.reload.publish!
    expect(@quiz.reload.quiz_data.first["question_text"]).to eq stripped_text

    DataFixup::ReinsertAssessmentQuestionFileVerifiers.run

    expect { @quiz.reload.quiz_data }.to raise_error(Psych::SyntaxError)
    expect { linked_question.reload.question_data }.to raise_error(Psych::SyntaxError)

    DataFixup::FixReinsertedVerifierQuestionYaml.run # fix the broken yaml
    expect(@quiz.reload.quiz_data.first["question_text"]).to eq original_text
    expect(linked_question.reload.question_data["question_text"]).to eq original_text
  end
end
