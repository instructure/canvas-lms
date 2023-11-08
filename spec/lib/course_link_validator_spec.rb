# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe CourseLinkValidator do
  it "validates all the links" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs

    course_factory
    attachment_model
    @ua = assignment_model(workflow_state: "unpublished", name: "Unpublished assignment eh")

    bad_url = "http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com"
    bad_url2 = "/courses/#{@course.id}/file_contents/baaaad"
    bad_media_object_url = "/media_objects_iframe/junk"
    html = <<~HTML
      <a href="#{bad_url}">Bad absolute link</a>
      <img src="#{bad_url2}">Bad file link</a>
      <img src="/courses/#{@course.id}/file_contents/#{CGI.escape(@attachment.full_display_path)}">Ok file link</a>
      <a href="/courses/#{@course.id}/quizzes">Ok other link</a>
      <a href="/courses/#{@course.id}/assignments/#{@ua.id}">Unpublished thing</a>
      <iframe src="#{bad_media_object_url}">
    HTML
    @course.image_url = bad_url
    @course.syllabus_body = html
    @course.save!

    bank = @course.assessment_question_banks.create!(title: "bank")
    aq = bank.assessment_questions.create!(question_data: { "name" => "test question",
                                                            "question_text" => html,
                                                            "answers" => [{ "id" => 1 }, { "id" => 2 }] })

    assmnt = @course.assignments.create!(title: "assignment", description: html)
    event = @course.calendar_events.create!(title: "event", description: html)
    topic = @course.discussion_topics.create!(title: "discussion title", message: html)
    mod = @course.context_modules.create!(name: "some module")
    mod.add_item(type: "external_url", url: bad_url, title: "pls view")
    page = @course.wiki_pages.create!(title: "wiki", body: html)
    quiz = @course.quizzes.create!(title: "quiz1", description: html)

    qq = quiz.quiz_questions.create!(question_data: aq.question_data)

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    issues.each do |issue|
      case issue[:type]
      when :course_card_image
        expect(issue[:content_url]).to eq "/courses/#{@course.id}/settings"
        expect(issue[:invalid_links]).to include({ reason: :unreachable, url: bad_url, image: true })
      when :module
        expect(issue[:content_url]).to eq "/courses/#{@course.id}/modules#module_#{mod.id}"
        expect(issue[:invalid_links]).to include({ reason: :unreachable, link_text: "pls view", url: bad_url })
      else
        expect(issue[:invalid_links]).to include({ reason: :unreachable, url: bad_url, link_text: "Bad absolute link" })
        expect(issue[:invalid_links]).to include({ reason: :unpublished_item, url: "/courses/#{@course.id}/assignments/#{@ua.id}", link_text: "Unpublished thing" })
        expect(issue[:invalid_links]).to include({ reason: :missing_item, url: bad_url2, image: true })
        expect(issue[:invalid_links]).to include({ reason: :missing_item, url: bad_media_object_url })
      end
    end

    type_names = {
      syllabus: "Course Syllabus",
      course_card_image: "Course Card Image",
      assessment_question: aq.question_data[:question_name],
      quiz_question: qq.question_data[:question_name],
      assignment: assmnt.title,
      calendar_event: event.title,
      discussion_topic: topic.title,
      module: mod.name,
      quiz: quiz.title,
      wiki_page: page.title
    }
    type_names.each do |type, name|
      expect(issues.count { |issue| issue[:type] == type }).to eq(1)
      expect(issues.detect { |issue| issue[:type] == type }[:name]).to eq(name)
    end
  end

  it "does not run on assessment questions in deleted banks" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs
    html = %(<a href='http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com'>linky</a>)

    course_factory
    bank = @course.assessment_question_banks.create!(title: "bank")
    bank.assessment_questions.create!(question_data: { "name" => "test question",
                                                       "question_text" => html,
                                                       "answers" => [{ "id" => 1 }, { "id" => 2 }] })

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues.count).to eq 1

    bank.destroy

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  it "does not run on deleted quiz questions" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs
    html = %(<a href='http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com'>linky</a>)

    course_factory
    quiz = @course.quizzes.create!(title: "quiz1", description: "desc")
    qq = quiz.quiz_questions.create!(question_data: { "name" => "test question",
                                                      "question_text" => html,
                                                      "answers" => [{ "id" => 1 }, { "id" => 2 }] })
    qq.destroy!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues.count).to eq 0
  end

  it "does not care if it can reach it" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(true)

    course_factory
    @course.discussion_topics.create!(message: %(<a href="http://www.www.www">pretend this is real</a>), title: "title")

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  describe "whitelisted?" do
    before :once do
      course_factory
    end

    it "returns false when Setting is absent" do
      link_validator = CourseLinkValidator.new(@course)
      expect(link_validator.whitelisted?("https://example.com/")).to be false
    end

    it "accepts a comma-separated Setting" do
      Setting.set("link_validator_whitelisted_hosts", "foo.com,bar.com")
      link_validator = CourseLinkValidator.new(@course)
      expect(link_validator.whitelisted?("http://foo.com/foo")).to be true
      expect(link_validator.whitelisted?("http://bar.com/bar")).to be true
      expect(link_validator.whitelisted?("http://baz.com/baz")).to be false
    end
  end

  it "checks for deleted/unpublished objects" do
    course_factory
    active = @course.assignments.create!(title: "blah")
    unpublished = @course.assignments.create!(title: "blah")
    unpublished.unpublish!
    deleted = @course.assignments.create!(title: "blah")
    deleted.destroy

    active_link = "/courses/#{@course.id}/assignments/#{active.id}"
    unpublished_link = "/courses/#{@course.id}/assignments/#{unpublished.id}"
    deleted_link = "/courses/#{@course.id}/assignments/#{deleted.id}"

    message = <<~HTML
      <a href='#{active_link}'>link</a>
      <a href='#{unpublished_link}'>link</a>
      <a href='#{deleted_link}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to match_array [unpublished_link, deleted_link]
  end

  it "works more betterer with external_tools/retrieve" do
    course_factory

    tool_1_1 = @course.context_external_tools.create!(name: "blah1",
                                                      url: "https://blah1.example.com",
                                                      shared_secret: "123",
                                                      consumer_key: "456")
    tool_1_3 = @course.context_external_tools.create!(name: "blah2",
                                                      url: "https://blah1.example.com",
                                                      shared_secret: "123",
                                                      consumer_key: "456",
                                                      lti_version: "1.3")
    resource_link = Lti::ResourceLink.create!(
      context: @course,
      lookup_uuid: "90abc684-0f4f-11ed-861d-0242ac120002",
      context_external_tool: tool_1_3
    )

    active_link_1_1 = "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape(tool_1_1.url)}"
    active_link_1_3 = "/courses/#{@course.id}/external_tools/retrieve?display=borderless&resource_link_lookup_uuid=#{resource_link.lookup_uuid}"
    nonsense_link = "/courses/#{@course.id}/external_tools/retrieve?url=#{CGI.escape("https://lolwut.beep")}"

    message = <<~HTML
      <a href='#{active_link_1_1}'>link</a>
      <a href='#{active_link_1_3}'>link</a>
      <a href='#{nonsense_link}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs
    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to eq([nonsense_link])
  end

  it "works with absolute links to local objects" do
    course_factory
    deleted = @course.assignments.create!(title: "blah")
    deleted.destroy

    deleted_link = "http://#{HostUrl.default_host}/courses/#{@course.id}/assignments/#{deleted.id}"

    message = "<a href='#{deleted_link}'>link</a>"
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to match_array [deleted_link]
  end

  it "finds links to other courses" do
    other_course = course_factory
    course_factory

    link = "http://#{HostUrl.default_host}/courses/#{other_course.id}/assignments"

    message = "<a href='#{link}'>link</a>"
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links]
    expect(links.count).to eq 1
    expect(links.first[:url]).to eq link
    expect(links.first[:reason]).to eq :course_mismatch
  end

  it "finds links to wiki pages" do
    course_factory
    active = @course.wiki_pages.create!(title: "active and stuff")
    unpublished = @course.wiki_pages.create!(title: "unpub")
    unpublished.unpublish!
    deleted = @course.wiki_pages.create!(title: "baleeted")
    deleted.destroy

    active_link = "/courses/#{@course.id}/pages/#{active.url}"
    unpublished_link = "/courses/#{@course.id}/pages/#{unpublished.url}"
    deleted_link = "/courses/#{@course.id}/pages/#{deleted.url}"

    message = <<~HTML
      <a href='#{active_link}'>link</a>
      <a href='#{active_link}#achor'>link</a>
      <a href='#{active_link}?query_param'>link</a>
      <a href='#{unpublished_link}'>link</a>
      <a href='#{deleted_link}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to match_array [unpublished_link, deleted_link]
  end

  it "ignores links to replaced wiki pages" do
    course_factory
    deleted = @course.wiki_pages.create!(title: "baleeted")
    deleted.destroy
    not_really_deleted = @course.wiki_pages.create!(title: "baleeted")
    not_really_deleted_link = "/courses/#{@course.id}/pages/#{not_really_deleted.url}"

    message = <<~HTML
      <a href='#{not_really_deleted_link}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  it "identifies typo'd canvas links" do
    course_factory
    invalid_link1 = "/cupbopourses"
    invalid_link2 = "http://#{HostUrl.default_host}/courses/#{@course.id}/pon3s"

    message = <<~HTML
      <a href='/courses'>link</a>
      <a href='/courses/#{@course.id}/assignments/'>link</a>
      <a href='#{invalid_link1}'>link</a>
      <a href='#{invalid_link2}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to match_array [invalid_link1, invalid_link2]
  end

  it "does not flag valid replaced attachments" do
    course_factory
    att1 = attachment_with_context(@course, display_name: "name")
    att2 = attachment_with_context(@course)

    att2.display_name = "name"
    att2.handle_duplicates(:overwrite)
    att1.reload
    expect(att1.replacement_attachment).to eq att2

    link = "/courses/#{@course.id}/files/#{att1.id}/download" # should still work because it uses att2 as a fallback
    message = <<~HTML
      <a href='#{link}'>link</a>
    HTML
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty

    att2.destroy # shouldn't work anymore

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].pluck(:url)
    expect(links).to match_array [link]
  end

  it "does not flag links to public paths" do
    course_factory
    @course.syllabus_body = %(<a href='/images/avatar-50.png'>link</a>)
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  it "flags sneaky links" do
    course_factory
    @course.syllabus_body = %(<a href='/../app/models/user.rb'>link</a>)
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues.count).to eq 1
  end

  it "does not flag wiki pages with url encoding" do
    course_factory
    page = @course.wiki_pages.create!(title: "semi;colon", body: "sutff")

    @course.syllabus_body = %(<a href='/courses/#{@course.id}/pages/#{CGI.escape(page.title)}'>link</a>)
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  context "#check_object_status" do
    before :once do
      course_model
      @course_link_validator = CourseLinkValidator.new(@course)
      assignment_model(course: @course)
    end

    it "returns :missing_item if the link doesn't point to course content" do
      expect(@course_link_validator.check_object_status("/test_error")).to eq :missing_item
    end

    it "returns :missing_item if the referenced media_object doesn't exist" do
      expect(@course_link_validator.check_object_status("/media_objects_iframe/junk")).to eq :missing_item
    end

    it "returns :unpublished_item for unpublished content" do
      @assignment.unpublish!
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/assignments/#{@assignment.id}")).to eq :unpublished_item

      quiz_model(course: @course).update(workflow_state: "created")
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq :unpublished_item

      quiz_model(course: @course).unpublish!
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq :unpublished_item

      attachment_model(context: @course).update(locked: true)
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/files/#{@attachment.id}/download")).to eq :unpublished_item
    end

    it "returns :deleted for deleted content" do
      @assignment.destroy
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/assignments/#{@assignment.id}")).to eq :deleted

      quiz_model(course: @course).destroy
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/quizzes/#{@quiz.id}")).to eq :deleted

      attachment_model(context: @course).destroy
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/files/#{@attachment.id}/download")).to eq :deleted
    end

    it "returns nil for syllabus links with query params and fragments" do
      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/assignments/syllabus?foo=bar")).to be_nil

      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/assignments/syllabus#grading")).to be_nil

      expect(@course_link_validator.check_object_status("/courses/#{@course.id}/assignments/syllabus?foo=bar#grading")).to be_nil
    end
  end

  describe "#valid_route?" do
    before :once do
      course_model
      @course_link_validator = CourseLinkValidator.new(@course)
    end

    it "returns true for valid routes" do
      expect(@course_link_validator.valid_route?("/")).to be_truthy
      expect(@course_link_validator.valid_route?("/courses/")).to be_truthy
    end

    it "returns true for a valid public file" do
      expect(@course_link_validator.valid_route?("/favicon.ico")).to be_truthy
    end
  end
end
