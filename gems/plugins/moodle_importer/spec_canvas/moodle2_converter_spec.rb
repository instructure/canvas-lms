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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Moodle::Converter do

  before(:once) do
    fixture_dir = File.dirname(__FILE__) + '/fixtures'
    archive_file_path = File.join(fixture_dir, 'moodle_backup_2.zip')
    unzipped_file_path = create_temp_dir!
    converter = Moodle::Converter.new(:export_archive_path=>archive_file_path, :course_name=>'oi', :base_download_dir=>unzipped_file_path)
    converter.export
    @base_course_data = converter.course.with_indifferent_access

    @course_data = Marshal.load(Marshal.dump(@base_course_data))
    @course = Course.create(:name => "test course")
    @cm = ContentMigration.create(:context => @course)
    Importers::CourseContentImporter.import_content(@course, @course_data, nil, @cm)
  end

  it "should successfully import the course" do
    allowed_warnings = [
      "Multiple Dropdowns question may have been imported incorrectly",
      "There are 3 Formula questions in this bank that will need to have their possible answers regenerated",
      "Missing links found in imported content",
      "The announcement \"News forum\" could not be linked to the module"
    ]
    expect(@cm.old_warnings_format.all?{|w| allowed_warnings.find{|aw| w[0].start_with?(aw)}}).to eq true
  end

  context "discussion topics" do
    it "should convert discussion topics and announcements" do
      expect(@course.discussion_topics.count).to eq 2

      dt = @course.discussion_topics.first
      expect(dt.title).to eq "Hidden Forum"
      expect(dt.message).to eq "<p>Description of hidden forum</p>"
      expect(dt.unpublished?).to eq true

      ann = @course.announcements.first
      expect(ann.title).to eq "News forum"
      expect(ann.message).to eq "<p>General news and announcements</p>"
    end
  end

  context "assignments" do
    it "should convert assignments" do
      expect(@course.assignments.count).to eq 2

      assignment2 = @course.assignments.where(title: 'Hidden Assignmnet').first
      expect(assignment2.description).to eq "<p>This is a hidden assignment</p>"
      expect(assignment2.unpublished?).to eq true
    end
  end

  context "wiki pages" do
    it "should convert wikis" do
      wiki = @course.wiki
      expect(wiki).not_to be_nil
      expect(wiki.wiki_pages.count).to eq 12

      page1 = wiki.wiki_pages.where(title: 'Hidden Section').first
      expect(page1.body).to eq '<p>This is a Hidden Section, with hidden items</p>'
      expect(page1.unpublished?).to eq true
    end
  end

  context "quizzes" do
    before(:each) do
      skip if !Qti.qti_enabled?
    end

    it "should convert quizzes" do
      expect(@course.quizzes.count).to eq 2
    end

    it "should convert Moodle Quiz module to a quiz" do
      quiz = @course.quizzes.where(title: "Quiz Name").first
      expect(quiz.description).to match /Quiz Description/
      expect(quiz.quiz_questions.count).to eq 11
    end

    it "should convert Moodle Questionnaire module to a quiz" do
      quiz = @course.quizzes.where(title: "Questionnaire Name").first
      expect(quiz.description).to match /Sumary/
      expect(quiz.quiz_type).to eq 'survey'
      expect(quiz.quiz_questions.count).to eq 10
    end
  end

  context "modules" do
    it "should convert modules and module items" do
      expect(@course.context_modules.count).to eq 8
      expect(@course.context_module_tags.where(:content_type => "Assignment", :title => "Assignment Name")).to be_exists
      expect(@course.context_module_tags.where(:content_type => "WikiPage", :title => "My Sample Page")).to be_exists
      expect(@course.context_module_tags.where(:content_type => "ContextModuleSubHeader", :title => "This is some label text")).to be_exists
      expect(@course.context_module_tags.where(:content_type => "DiscussionTopic", :title => "Hidden Forum")).to be_exists
      expect(@course.context_module_tags.where(:content_type => "Quizzes::Quiz", :title => "Quiz Name")).to be_exists
      expect(@course.context_module_tags.where(:content_type => "ExternalUrl", :title => "my sample url")).to be_exists
    end
  end
end
