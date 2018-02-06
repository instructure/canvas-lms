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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe CourseLinkValidator do

  it "should validate all the links" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs

    course_factory
    attachment_model

    bad_url = "http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com"
    bad_url2 = "/courses/#{@course.id}/file_contents/baaaad"
    html = %{
      <a href="#{bad_url}">Bad absolute link</a>
      <img src="#{bad_url2}">Bad file link</a>
      <img src="/courses/#{@course.id}/file_contents/#{CGI.escape(@attachment.full_display_path)}">Ok file link</a>
      <a href="/courses/#{@course.id}/quizzes">Ok other link</a>
    }

    @course.syllabus_body = html
    @course.save!

    bank = @course.assessment_question_banks.create!(:title => 'bank')
    aq = bank.assessment_questions.create!(:question_data => {'name' => 'test question',
      'question_text' => html, 'answers' => [{'id' => 1}, {'id' => 2}]})

    assmnt = @course.assignments.create!(:title => 'assignment', :description => html)
    event = @course.calendar_events.create!(:title => "event", :description => html)
    topic = @course.discussion_topics.create!(:title => "discussion title", :message => html)
    mod = @course.context_modules.create!(:name => "some module")
    tag = mod.add_item(:type => 'external_url', :url => bad_url, :title => 'pls view')
    page = @course.wiki_pages.create!(:title => "wiki", :body => html)
    quiz = @course.quizzes.create!(:title => 'quiz1', :description => html)

    qq = quiz.quiz_questions.create!(:question_data => aq.question_data)

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    issues.each do |issue|
      expect(issue[:invalid_links]).to include({:reason => :unreachable, :url => bad_url})
      next if issue[:type] == :module_item
      expect(issue[:invalid_links]).to include({:reason => :missing_file, :url => bad_url2})
    end

    type_names = {
      :syllabus => 'Course Syllabus',
      :assessment_question => aq.question_data[:question_name],
      :quiz_question => qq.question_data[:question_name],
      :assignment => assmnt.title,
      :calendar_event => event.title,
      :discussion_topic => topic.title,
      :module_item => tag.title,
      :quiz => quiz.title,
      :wiki_page => page.title
    }
    type_names.each do |type, name|
      expect(issues.select{|issue| issue[:type] == type}.count).to eq(1)
      expect(issues.detect{|issue| issue[:type] == type}[:name]).to eq(name)
    end

  end

  it "should not run on assessment questions in deleted banks" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs
    html = %{<a href='http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com'>linky</a>}

    course_factory
    bank = @course.assessment_question_banks.create!(:title => 'bank')
    aq = bank.assessment_questions.create!(:question_data => {'name' => 'test question',
      'question_text' => html, 'answers' => [{'id' => 1}, {'id' => 2}]})

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

  it "should not run on deleted quiz questions" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(false) # don't actually ping the links for the specs
    html = %{<a href='http://www.notarealsitebutitdoesntmattercauseimstubbingitanwyay.com'>linky</a>}

    course_factory
    quiz = @course.quizzes.create!(:title => 'quiz1', :description => "desc")
    qq = quiz.quiz_questions.create!(:question_data => {'name' => 'test question',
      'question_text' => html, 'answers' => [{'id' => 1}, {'id' => 2}]})
    qq.destroy!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues.count).to eq 0
  end

  it "should not care if it can reach it" do
    allow_any_instance_of(CourseLinkValidator).to receive(:reachable_url?).and_return(true)

    course_factory
    topic = @course.discussion_topics.create!(:message => %{<a href="http://www.www.www">pretend this is real</a>}, :title => "title")

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  describe "insecure hosts" do
    def test_url(url)
      course_factory
      topic = @course.discussion_topics.create!(:message => %{<a href="#{url}">kekeke</a>}, :title => "title")

      expect(CanvasHttp).to_not receive(:connection_for_uri) # don't try to continue after failing validation
      CourseLinkValidator.queue_course(@course)
      run_jobs

      issues = CourseLinkValidator.current_progress(@course).results[:issues]
      expect(issues.first[:invalid_links].first[:reason]).to eq :unreachable
    end

    it "should not try to access local ips" do
      test_url("http://localhost:3000/haxxed")
      test_url("http://127.0.0.1/haxxedagain")
    end

    it "should be able to set the ip filter" do
      Setting.set('http_blocked_ip_ranges', '42.42.42.42/8,24.24.24.24')
      test_url("http://42.42.0.1/haxxedtheplanet")
      test_url("http://24.24.24.24/haxxedforever")
    end
  end

  it "should check for deleted/unpublished objects" do
    course_factory
    active = @course.assignments.create!(:title => "blah")
    unpublished = @course.assignments.create!(:title => "blah")
    unpublished.unpublish!
    deleted = @course.assignments.create!(:title => "blah")
    deleted.destroy

    active_link = "/courses/#{@course.id}/assignments/#{active.id}"
    unpublished_link = "/courses/#{@course.id}/assignments/#{unpublished.id}"
    deleted_link = "/courses/#{@course.id}/assignments/#{deleted.id}"

    message = %{
      <a href='#{active_link}'>link</a>
      <a href='#{unpublished_link}'>link</a>
      <a href='#{deleted_link}'>link</a>
    }
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].map{|l| l[:url]}
    expect(links).to match_array [unpublished_link, deleted_link]
  end

  it "should work with absolute links to local objects" do
    course_factory
    deleted = @course.assignments.create!(:title => "blah")
    deleted.destroy

    deleted_link = "http://#{HostUrl.default_host}/courses/#{@course.id}/assignments/#{deleted.id}"

    message = "<a href='#{deleted_link}'>link</a>"
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].map{|l| l[:url]}
    expect(links).to match_array [deleted_link]
  end

  it "should find links to other courses" do
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

  it "should find links to wiki pages" do
    course_factory
    active = @course.wiki_pages.create!(:title => "active and stuff")
    unpublished = @course.wiki_pages.create!(:title => "unpub")
    unpublished.unpublish!
    deleted = @course.wiki_pages.create!(:title => "baleeted")
    deleted.destroy

    active_link = "/courses/#{@course.id}/pages/#{active.url}"
    unpublished_link = "/courses/#{@course.id}/pages/#{unpublished.url}"
    deleted_link = "/courses/#{@course.id}/pages/#{deleted.url}"

    message = %{
      <a href='#{active_link}'>link</a>
      <a href='#{active_link}#achor'>link</a>
      <a href='#{active_link}?query_param'>link</a>
      <a href='#{unpublished_link}'>link</a>
      <a href='#{deleted_link}'>link</a>
    }
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].map{|l| l[:url]}
    expect(links).to match_array [unpublished_link, deleted_link]
  end

  it "should identify typo'd canvas links" do
    course_factory
    invalid_link1 = "/cupbopourses"
    invalid_link2 = "http://#{HostUrl.default_host}/courses/#{@course.id}/pon3s"

    message = %{
      <a href='/courses'>link</a>
      <a href='/courses/#{@course.id}/assignments/'>link</a>
      <a href='#{invalid_link1}'>link</a>
      <a href='#{invalid_link2}'>link</a>
    }
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].map{|l| l[:url]}
    expect(links).to match_array [invalid_link1, invalid_link2]
  end

  it "should not flag valid replaced attachments" do
    course_factory
    att1 = attachment_with_context(@course, :display_name => "name")
    att2 = attachment_with_context(@course)

    att2.display_name = "name"
    att2.handle_duplicates(:overwrite)
    att1.reload
    expect(att1.replacement_attachment).to eq att2

    link = "/courses/#{@course.id}/files/#{att1.id}/download" # should still work because it uses att2 as a fallback
    message = %{
      <a href='#{link}'>link</a>
    }
    @course.syllabus_body = message
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty

    att2.destroy # shouldn't work anymore

    CourseLinkValidator.queue_course(@course)
    run_jobs

    links = CourseLinkValidator.current_progress(@course).results[:issues].first[:invalid_links].map{|l| l[:url]}
    expect(links).to match_array [link]
  end

  it "should not flag links to public paths" do
    course_factory
    @course.syllabus_body = %{<a href='/images/avatar-50.png'>link</a>}
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end

  it "should flag sneaky links" do
    course_factory
    @course.syllabus_body = %{<a href='/../app/models/user.rb'>link</a>}
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues.count).to eq 1
  end

  it "should not flag wiki pages with url encoding" do
    course_factory
    page = @course.wiki_pages.create!(:title => "semi;colon", :body => 'sutff')

    @course.syllabus_body = %{<a href='/courses/#{@course.id}/pages/#{CGI.escape(page.title)}'>link</a>}
    @course.save!

    CourseLinkValidator.queue_course(@course)
    run_jobs

    issues = CourseLinkValidator.current_progress(@course).results[:issues]
    expect(issues).to be_empty
  end
end
