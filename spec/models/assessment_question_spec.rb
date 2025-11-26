# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AssessmentQuestion do
  before :once do
    course_factory(active_all: true)
    @bank = @course.assessment_question_banks.create!(title: "Test Bank")
  end

  def attachment_in_course(course)
    Attachment.create!(
      filename: "test.jpg",
      display_name: "test.jpg",
      uploaded_data: StringIO.new("psych!"),
      folder: Folder.unfiled_folder(course),
      context: course
    )
  end

  it "creates a new instance given valid attributes" do
    expect do
      assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))
    end.not_to raise_error
  end

  it "infer_defaults from question_data before validation" do
    @question = assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))
    @question.name = "1" * 300
    @question.save(validate: false)
    expect(@question.name.length).to eq 300

    @question.question_data[:question_name] = "valid name"
    @question.save!
    expect(@question).to be_valid
    expect(@question.name).to eq @question.question_data[:question_name]
  end

  it "translates links to be readable when creating the assessment question" do
    @attachment = attachment_in_course(@course)
    data = { "name" => "Hi", "question_text" => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "translates links relative path url" do
    @attachment = attachment_in_course(@course)
    data = { "name" => "Hi", "question_text" => "Translate this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "handles existing query string parameters" do
    @attachment = attachment_in_course(@course)
    data = { "name" => "Hi",
             "question_text" => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg?wrap=1'>",
             "answers" => [{ "id" => 1 }, { "id" => 2 }] }
    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}&wrap=1'>"
  end

  it "translates multiple links in same body" do
    @attachment = attachment_in_course(@course)

    data = { "name" => "Hi", "question_text" => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    @clone = @question.attachments.where(root_attachment: @attachment).first

    expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "translates user files" do
    user_file = @teacher.attachments.create!(uploaded_data: fixture_file_upload("docs/doc.doc", "application/msword", true))
    data = { "name" => "Hi", "question_text" => "Translate this: <img src='/users/#{@teacher.id}/files/#{user_file.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }

    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
    @clone = @question.attachments.where(root_attachment: user_file).first
    expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download?verifier=#{@clone.uuid}'>"
  end

  it "does not allow another users without proper permission to user file to clone it" do
    other_user = user_model
    user_file = @teacher.attachments.create!(uploaded_data: fixture_file_upload("docs/doc.doc", "application/msword", true))
    data = { "name" => "Hi", "question_text" => "Translate this: <img src='/users/#{@teacher.id}/files/#{user_file.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }

    @question = @bank.assessment_questions.create!(question_data: data, updating_user: other_user)
    @clone = @question.attachments.where(root_attachment: user_file).first
    expect(@clone).to be_nil
  end

  it "only creates one clone when same attachment appears multiple times" do
    @attachment = attachment_in_course(@course)
    data = { "name" => "Hi", "question_text" => "First: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> Second: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> Third: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    clones = @question.attachments.where(root_attachment: @attachment)
    expect(clones.count).to eq 1
  end

  describe "translate_link_regex" do
    it "matches course file links with query params" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/courses/#{@course.id}/files/2323?wrap=1"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:course_attachment_id]).to eq "2323"
      expect(match[:rest]).to eq "?wrap=1"
    end

    it "matches course file links with tilde in ID" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/courses/#{@course.id}/files/23~23/download?xs=1"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:course_attachment_id]).to eq "23~23"
      expect(match[:rest]).to eq "/download?xs=1"
    end

    it "matches course file_contents links" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/courses/#{@course.id}/file_contents/course%20files/Pinkman.png/preview"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:course_file_path]).to eq "Pinkman.png/preview"
      expect(match[:rest]).to be_nil
    end

    it "matches user file links" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/users/15/files/2323"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:user_id]).to eq "15"
      expect(match[:user_attachment_id]).to eq "2323"
      expect(match[:rest]).to be_nil
    end

    it "matches user file links with tilde in IDs" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/users/15~15/files/23~23?wrap=1"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:user_id]).to eq "15~15"
      expect(match[:user_attachment_id]).to eq "23~23"
      expect(match[:rest]).to eq "?wrap=1"
    end

    it "matches media_attachments_iframe links" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/media_attachments_iframe/23~23?ping=1"
      match = link.match(question.translate_link_regex)
      expect(match).not_to be_nil
      expect(match[:media_attachment_id]).to eq "23~23"
      expect(match[:rest]).to eq "?ping=1"
    end

    it "does not match course file links with different context ID" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      link = "/courses/2555/files/2323"
      match = link.match(question.translate_link_regex)
      expect(match).to be_nil # should not match because context_id is different
    end

    it "does not match invalid paths" do
      question = @bank.assessment_questions.create!(question_data: { "name" => "Test", "question_text" => "Test", "answers" => [] })
      expect("/something/15/files/2323".match(question.translate_link_regex)).to be_nil
      expect("/p".match(question.translate_link_regex)).to be_nil
      expect("/files/25".match(question.translate_link_regex)).to be_nil
    end
  end

  context "when disable_file_verifier_access feature flag is enabled" do
    it "translates multiple links in same body and would not add verifiers" do
      @attachment = attachment_in_course(@course)
      @attachment.root_account.enable_feature!(:disable_file_verifier_access)

      data = { "name" => "Hi", "question_text" => "Translate this: <img src='/courses/#{@course.id}/files/#{@attachment.id}/download'> and this: <img src='/courses/#{@course.id}/file_contents/course%20files/unfiled/test.jpg'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

      @clone = @question.attachments.where(root_attachment: @attachment).first

      expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download'> and this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download'>"
    end

    it "translates user files and would not add verifiers" do
      user_file = @teacher.attachments.create!(uploaded_data: fixture_file_upload("docs/doc.doc", "application/msword", true))
      data = { "name" => "Hi", "question_text" => "Translate this: <img src='/users/#{@teacher.id}/files/#{user_file.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
      user_file.root_account.enable_feature!(:disable_file_verifier_access)

      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
      @clone = @question.attachments.where(root_attachment: user_file).first
      expect(@question.reload.question_data["question_text"]).to eq "Translate this: <img src='/assessment_questions/#{@question.id}/files/#{@clone.id}/download'>"
    end
  end

  it "translates links to be readable w/ verifier" do
    # TODO: verifier string matching should be removed with GROW-146
    @attachments = {}
    attachment_tag = lambda do |key|
      @attachments[key] ||= []
      a = @course.attachments.build(filename: "foo-#{key}.gif")
      a.content_type = "image/gif"
      a.save!
      @attachments[key] << a
      "<img src=\"/courses/#{@course.id}/files/#{a.id}/download\">"
    end
    data = {
      name: "test question",
      question_type: "multiple_choice_question",
      question_text: "which ones are like this one? #{attachment_tag.call([:question_text])} what about: #{attachment_tag.call([:question_text])}",
      correct_comments: "yay! #{attachment_tag.call([:correct_comments])}",
      incorrect_comments: "boo! #{attachment_tag.call([:incorrect_comments])}",
      neutral_comments: "meh. #{attachment_tag.call([:neutral_comments])}",
      text_after_answers: "oh btw #{attachment_tag.call([:text_after_answers])}",
      answers: [
        { weight: 1,
          text: "A",
          html: "A #{attachment_tag.call([:answers, 0, :html])}",
          comments_html: "yeppers #{attachment_tag.call([:answers, 0, :comments_html])}" },
        { weight: 1,
          text: "B",
          html: "B #{attachment_tag.call([:answers, 1, :html])}",
          comments_html: "yeppers #{attachment_tag.call([:answers, 1, :comments_html])}" }
      ]
    }

    serialized_data_before = Marshal.dump(data)

    @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)

    @attachment_clones = @attachments.transform_values { |ary| ary.map { |a| @question.attachments.where(root_attachment_id: a).first } }

    @attachment_clones.each do |key, ary|
      string = @question.question_data.dig(*key)
      matches = string.scan %r{/assessment_questions/\d+/files/\d+/download\?verifier=\w+}
      expect(matches.length).to eq ary.length
      matches.each_with_index do |match, index|
        a = ary[index]
        expect(match).to eq "/assessment_questions/#{@question.id}/files/#{a.id}/download?verifier=#{a.uuid}"
      end
    end

    # the original data hash should not have changed during the link translation
    serialized_data_after = Marshal.dump(data)
    expect(serialized_data_before).to eq serialized_data_after
  end

  it "does not drop non-string/array/hash data types when translate links" do
    bank = @course.assessment_question_banks.create!(title: "Test Bank")

    data = {
      name: "mc question",
      question_type: "multiple_choice_question",
      question_text: "text text text",
      points_possible: "10",
      correct_comments: "",
      incorrect_comments: "",
      answers: {
        "answer_0" => { answer_weight: 100, answer_text: "1", id: "0", answer_comments: "hi there" }
      }
    }

    question = bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
    expect(question.question_data[:points_possible]).to eq "10"
    data[:points_possible] = "50"
    question.form_question_data = data
    question.save
    expect(question.question_data.class).to eq ActiveSupport::HashWithIndifferentAccess
    expect(question.question_data[:points_possible]).to eq 50
    expect(question.question_data[:answers][0][:weight]).to eq 100
    expect(question.question_data[:answers][0][:id]).not_to be_nil
    expect(question.question_data[:assessment_question_id]).to eq question.id
  end

  it "always returns a HashWithIndifferentAccess and allow editing" do
    data = {
      name: "mc question",
      question_type: "multiple_choice_question",
      question_text: "text text text",
      points_possible: "10",
      answers: {
        "answer_0" => { answer_weight: 100, answer_text: "1", id: "0", answer_comments: "hi there" }
      }
    }

    question = @bank.assessment_questions.create!(question_data: data)
    expect(question.question_data.class).to eq ActiveSupport::HashWithIndifferentAccess

    question.question_data = data
    expect(question.question_data.class).to eq ActiveSupport::HashWithIndifferentAccess

    data = question.question_data
    data[:name] = "new name"

    expect(question.question_data[:name]).to eq "new name"
    expect(data.object_id).to eq question.question_data.object_id
  end

  describe ".find_or_create_quiz_questions" do
    let(:assessment_question) { assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!)) }
    let(:quiz) { quiz_model }

    it "creates a quiz_question when one does not exist" do
      expect do
        AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil)
      end.to change { Quizzes::QuizQuestion.count }.by(1)
    end

    it "finds an existing quiz_question" do
      qq = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first

      expect do
        qq2 = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first
        expect(qq2.id).to eql(qq.id)
      end.to_not change { AssessmentQuestion.count }
    end

    it "finds and update an out of date quiz_question" do
      aq = assessment_question
      qq = AssessmentQuestion.find_or_create_quiz_questions([aq], quiz.id, nil).first

      aq = AssessmentQuestion.find(aq.id)
      aq.name = "changed"
      aq.with_versioning(&:save!)

      expect(qq.assessment_question_version).to_not eql(aq.version_number)

      qq2 = AssessmentQuestion.find_or_create_quiz_questions([aq], quiz.id, nil).first
      aq = AssessmentQuestion.find(aq.id)
      expect(qq.assessment_question_version).to_not eql(qq2.assessment_question_version)
      expect(qq2.assessment_question_version).to eql(aq.version_number)
    end

    it "grabs the first match by ID order" do
      # consistent ordering is good for preventing deadlocks
      questions = []
      3.times { questions << assessment_question.create_quiz_question(quiz.id) }
      smallest_id_question = questions.min_by(&:id)
      qq = AssessmentQuestion.find_or_create_quiz_questions([assessment_question], quiz.id, nil).first
      expect(qq.id).to eq(smallest_id_question.id)
    end
  end

  describe "media_attachments_iframe link translation" do
    def media_attachment_in_course(course)
      attachment = Attachment.create!(
        filename: "video.mp4",
        display_name: "video.mp4",
        uploaded_data: StringIO.new("fake video content"),
        folder: Folder.unfiled_folder(course),
        context: course,
        content_type: "video/mp4"
      )

      media_object = MediaObject.create!(
        media_id: "test_media_id_#{attachment.id}",
        media_type: "video",
        context: course,
        attachment_id: attachment.id
      )

      attachment.update!(media_entry_id: media_object.media_id)
      attachment
    end

    it "translates media_attachments_iframe links to use original iframe format" do
      @media_attachment = media_attachment_in_course(@course)

      data = {
        "name" => "Media Question",
        "question_text" => "Watch this video: <iframe src='/media_attachments_iframe/#{@media_attachment.id}?embedded=true&type=video'></iframe>",
        "answers" => [{ "id" => 1 }, { "id" => 2 }]
      }

      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
      @clone = @question.attachments.where(root_attachment: @media_attachment).first

      expected_url = "/media_attachments_iframe/#{@clone.id}?verifier=#{@clone.uuid}&embedded=true&type=video"
      expect(@question.reload.question_data["question_text"]).to eq "Watch this video: <iframe src='#{expected_url}'></iframe>"
    end

    it "handles multiple media iframe links in the same content" do
      @media_attachment1 = media_attachment_in_course(@course)
      @media_attachment2 = media_attachment_in_course(@course)

      data = {
        "name" => "Multiple Media Question",
        "question_text" => "First video: <iframe src='/media_attachments_iframe/#{@media_attachment1.id}?embedded=true'></iframe> Second video: <iframe src='/media_attachments_iframe/#{@media_attachment2.id}?type=video'></iframe>",
        "answers" => [{ "id" => 1 }, { "id" => 2 }]
      }

      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
      @clone1 = @question.attachments.where(root_attachment: @media_attachment1).first
      @clone2 = @question.attachments.where(root_attachment: @media_attachment2).first

      result = @question.reload.question_data["question_text"]
      expect(result).to include("<iframe src='/media_attachments_iframe/#{@clone1.id}")
      expect(result).to include("<iframe src='/media_attachments_iframe/#{@clone2.id}")
    end

    it "handles mixed regular file and media iframe links" do
      @attachment = attachment_in_course(@course)
      @media_attachment = media_attachment_in_course(@course)

      data = {
        "name" => "Mixed Content Question",
        "question_text" => "Download this: <a href='/courses/#{@course.id}/files/#{@attachment.id}/download'>file</a> and watch this: <iframe src='/media_attachments_iframe/#{@media_attachment.id}?embedded=true'></iframe>",
        "answers" => [{ "id" => 1 }, { "id" => 2 }]
      }

      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
      @file_clone = @question.attachments.where(root_attachment: @attachment).first
      @media_clone = @question.attachments.where(root_attachment: @media_attachment).first

      result = @question.reload.question_data["question_text"]
      expect(result).to include("<a href='/assessment_questions/#{@question.id}/files/#{@file_clone.id}/download")
      expect(result).to include("<iframe src='/media_attachments_iframe/#{@media_clone.id}")
    end

    # TODO: should be removed with GROW-146
    context "when disable_file_verifier_access feature flag is enabled" do
      it "translates media iframe links without adding verifiers" do
        @media_attachment = media_attachment_in_course(@course)
        @media_attachment.root_account.enable_feature!(:disable_file_verifier_access)

        data = {
          "name" => "Media Question",
          "question_text" => "Media: <iframe src='/media_attachments_iframe/#{@media_attachment.id}?embedded=true'></iframe>",
          "answers" => [{ "id" => 1 }, { "id" => 2 }]
        }

        @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
        @clone = @question.attachments.where(root_attachment: @media_attachment).first

        expected_url = "/media_attachments_iframe/#{@clone.id}?embedded=true"
        expect(@question.reload.question_data["question_text"]).to eq "Media: <iframe src='#{expected_url}'></iframe>"
      end
    end

    it "handles media iframe links in answer choices" do
      @media_attachment = media_attachment_in_course(@course)

      data = {
        "name" => "Media Answer Question",
        "question_text" => "Which video shows the correct technique?",
        "question_type" => "multiple_choice_question",
        "answers" => [
          {
            "id" => 1,
            "weight" => 1,
            "text" => "Option A",
            "html" => "Watch this: <iframe src='/media_attachments_iframe/#{@media_attachment.id}?embedded=true'></iframe>",
            "comments_html" => "Good choice! <iframe src='/media_attachments_iframe/#{@media_attachment.id}?type=video'></iframe>"
          },
          {
            "id" => 2,
            "weight" => 0,
            "text" => "Option B",
            "html" => "B"
          }
        ]
      }

      @question = @bank.assessment_questions.create!(question_data: data, updating_user: @teacher)
      @clone = @question.attachments.where(root_attachment: @media_attachment).first

      answer_html = @question.reload.question_data["answers"][0]["html"]
      comments_html = @question.reload.question_data["answers"][0]["comments_html"]

      expect(answer_html).to include("<iframe src='/media_attachments_iframe/#{@clone.id}")
      expect(comments_html).to include("<iframe src='/media_attachments_iframe/#{@clone.id}")
    end

    it "preserves media iframe URLs when attachment cloning fails" do
      @media_attachment = media_attachment_in_course(@course)

      allow_any_instance_of(Attachment).to receive(:clone_for).and_return(nil)

      data = {
        "name" => "Media Question",
        "question_text" => "Media: <iframe src='/media_attachments_iframe/#{@media_attachment.id}?embedded=true'></iframe>",
        "answers" => [{ "id" => 1 }, { "id" => 2 }]
      }

      @question = @bank.assessment_questions.create!(question_data: data)

      original_url = "/media_attachments_iframe/#{@media_attachment.id}?embedded=true"
      expect(@question.reload.question_data["question_text"]).to eq "Media: <iframe src='#{original_url}'></iframe>"
    end
  end

  context "root_account_id" do
    it "uses root_account value from account" do
      question = assessment_question_model(bank: AssessmentQuestionBank.create!(context: Course.create!))

      expect(question.root_account_id).to eq Account.default.id
    end
  end
end
