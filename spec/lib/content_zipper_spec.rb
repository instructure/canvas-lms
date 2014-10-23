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

describe ContentZipper do
  describe "zip_assignment" do
    it "sanitizes user names" do
      s1, s2, s3 = n_students_in_course(3)
      s1.update_attribute :sortable_name, 'some_999_, _1234_guy'
      s2.update_attribute :sortable_name, 'other 567, guy 8'
      s3.update_attribute :sortable_name, '45'
      [s1, s2, s3].each { |s|
        submission_model user: s, assignment: @assignment, body: "blah"
      }
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment, @teacher)
      expected_file_patterns = [
        /other-567--guy-8/,
        /some-999----1234-guy/,
        /-45-/,
      ]
      Zip::File.foreach(attachment.reload.full_filename) { |f|
        expect {
          expected_file_patterns.delete_if { |expected_pattern| f.name =~ expected_pattern }
        }.to change { expected_file_patterns.size }.by(-1)
      }
      expected_file_patterns.should be_empty
    end

    it "should zip up online_url submissions" do
      course_with_student(:active_all => true)
      @user.update_attributes!(:sortable_name => 'some_999_, _1234_guy')
      submission_model :user => @user
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment, @teacher)
      attachment.reload
      attachment.workflow_state.should == 'zipped'
      Zip::File.foreach(attachment.full_filename) do |f|
        if f.file?
          f.name.should =~ /some-999----1234-guy/
          f.get_input_stream.read.should match(%r{This submission was a url, we&#x27;re taking you to the url link now.})
          f.get_input_stream.read.should be_include("http://www.instructure.com/")
        end
      end
    end

    it "should zip up online_text_entry submissions" do
      course_with_student(:active_all => true)
      submission_model(:body => "hai this is my answer")
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment, @teacher)
      attachment.reload
      attachment.workflow_state.should == 'zipped'
      Zip::File.foreach(attachment.full_filename) do |f|
        if f.file?
          f.get_input_stream.read.should be_include("hai this is my answer")
        end
      end
    end

    it "should only include submissions in the correct section " do
      course_with_student(:active_all => true)
      submission_model(:body => "hai this is my answer")
      @section = @course.course_sections.create!
      @ta = user_with_pseudonym(:active_all => 1)
      @course.enroll_user(@ta, "TaEnrollment", :limit_privileges_to_course_section => true, :section => @section)
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @ta
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment, @ta)
      attachment.reload
      # no submissions
      attachment.workflow_state.should == 'errored'
    end

    it "only includes one submission per group" do
      teacher_in_course active_all: true
      gc = @course.group_categories.create! name: "Homework Groups"
      groups = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
      students = 4.times.map { student_in_course(active_all: true); @student }
      students.each_with_index { |s, i| groups[i % groups.size].add_user(s) }
      a = @course.assignments.create! group_category_id: gc.id,
                                      grade_group_students_individually: false,
                                      submission_types: %w(text_entry)
      a.submit_homework(students.first, body: "group 1 submission")
      a.submit_homework(students.second, body: "group 2 submission")

      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = a
      attachment.save!

      ContentZipper.process_attachment(attachment, @teacher)
      sub_count = 0
      expected_file_names = [/group-0/, /group-1/]
      Zip::File.foreach(attachment.full_filename) do |f|
        expect {
          expected_file_names.delete_if { |expected_name| f.name =~ expected_name }
        }.to change { expected_file_names.size }.by(-1)
      end
    end
  end

  describe "assignment_zip_filename" do
    it "should use use course and title slugs to keep filename length down" do
      course(:active_all => true)
      @course.short_name = "a" * 31
      @course.save!
      assignment_model(:course => @course, :title => "b" * 31)

      zipper = ContentZipper.new
      filename = zipper.assignment_zip_filename(@assignment)
      filename.should match /#{@course.short_name_slug}/
      filename.should match /#{@assignment.title_slug}/
      filename.should_not match /#{@course.short_name}/
      filename.should_not match /#{@assignment.title}/
    end
  end

  describe "zip_folder" do
    context "checking permissions" do
      before(:each) do
        course_with_student(:active_all => true)
        folder = Folder.root_folders(@course).first
        attachment_model(:uploaded_data => stub_png_data('hidden.png'), :content_type => 'image/png', :hidden => true, :folder => folder)
        attachment_model(:uploaded_data => stub_png_data('visible.png'), :content_type => 'image/png', :folder => folder)
        attachment_model(:uploaded_data => stub_png_data('locked.png'), :content_type => 'image/png', :folder => folder, :locked => true)
        hidden_folder = folder.sub_folders.create!(:context => @course, :name => 'hidden', :hidden => true)
        visible_folder = folder.sub_folders.create!(:context => @course, :name => 'visible')
        locked_folder = folder.sub_folders.create!(:context => @course, :name => 'locked', :locked => true)
        attachment_model(:uploaded_data => stub_png_data('sub-hidden.png'), :content_type => 'image/png', :folder => hidden_folder)
        attachment_model(:uploaded_data => stub_png_data('sub-vis.png'), :content_type => 'image/png', :folder => visible_folder)
        attachment_model(:uploaded_data => stub_png_data('sub-locked.png'), :content_type => 'image/png', :folder => visible_folder, :locked => true)
        attachment_model(:uploaded_data => stub_png_data('sub-locked-vis.png'), :content_type => 'image/png', :folder => locked_folder)

        @attachment = Attachment.new(:display_name => 'my_download.zip')
        @attachment.workflow_state = 'to_be_zipped'
        @attachment.context = folder
      end

      def zipped_files_for_user(user=nil, check_user=true)
        @attachment.user_id = user.id if user
        @attachment.save!
        ContentZipper.process_attachment(@attachment, user, :check_user => check_user)
        names = []
        @attachment.reload
        Zip::File.foreach(@attachment.full_filename) {|f| names << f.name if f.file? }
        names.sort
      end

      context "in a private course" do
        it "should give logged in students some files" do
          zipped_files_for_user(@user).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give logged in teachers all files" do
          zipped_files_for_user(@teacher).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end

        it "should give logged out people no files" do
          zipped_files_for_user(nil).should == []
        end

        it "should give all files if check_user=false" do
          zipped_files_for_user(nil, false).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end
      end

      context "in a public course" do
        before(:each) do
          @course.is_public = true
          @course.save!
        end

        it "should give logged in students some files" do
          zipped_files_for_user(@user).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give logged in teachers all files" do
          zipped_files_for_user(@teacher).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end

        it "should give logged out people the same thing as students" do
          zipped_files_for_user(nil).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give all files if check_user=false" do
          zipped_files_for_user(nil, false).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end
      end
    end

    it "should not error on empty folders" do
      course_with_student(:active_all => true)
      folder = Folder.root_folders(@course).first
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user_id = @user.id
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = folder
      attachment.save!
      ContentZipper.process_attachment(attachment, @user)
      attachment.workflow_state.should == 'zipped'
    end

    it "should use the display name" do
      course_with_student(:active_all => true)
      folder = Folder.root_folders(@course).first
      attachment_model(:uploaded_data => stub_png_data('hidden.png'), :content_type => 'image/png', :folder => folder, :display_name => 'otherfile.png')
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user_id = @user.id
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = folder
      attachment.save!
      ContentZipper.process_attachment(attachment, @user)
      attachment.reload
      names = []
      Zip::File.foreach(attachment.full_filename) {|f| names << f.name if f.file? }
      names.should == ['otherfile.png']
    end
  end

  describe "mark_successful!" do
    it "sets an instance variable representing a successful zipping" do
      zipper = ContentZipper.new
      zipper.should_not be_zipped_successfully
      zipper.mark_successful!
      zipper.should be_zipped_successfully
    end
  end

  describe "zip_eportfolio" do
    it "should sanitize the zip file name" do
      user = User.create!
      eportfolio = user.eportfolios.create!(:name => '/../../etc/passwd')

      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = user
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = eportfolio
      attachment.save!
      Dir.expects(:mktmpdir).once.yields('/tmp')
      Zip::File.expects(:open).once.with('/tmp/etcpasswd.zip', Zip::File::CREATE)
      ContentZipper.process_attachment(attachment, user)
    end
  end

  describe "render_eportfolio_page_content" do
    it "should return the text of the file contents" do
      user = User.create!
      eportfolio = user.eportfolios.create!(:name => 'bestest_eportfolio_eva')
      eportfolio.ensure_defaults

      contents = ContentZipper.new.render_eportfolio_page_content(eportfolio.eportfolio_entries.first, eportfolio, nil, {})
      contents.should match("bestest_eportfolio_eva") #really just testing that this method doesn't throw an error
    end
  end

  describe "mark_attachment_as_zipping!" do

    it "marks the workflow state as zipping" do
      attachment = Attachment.new display_name: 'jenkins.ppt'
      attachment.expects(:save!).once
      ContentZipper.new.mark_attachment_as_zipping!(attachment)
      attachment.should be_zipping
    end
  end

  describe "update_progress" do

    it "updates the zip attachment's state to a percentage and save!s it" do
      attachment = Attachment.new display_name: "donuts.jpg"
      attachment.expects(:save!).once
      ContentZipper.new.update_progress(attachment,5,10)
      attachment.file_state.should == 60 # accounts for zero-indexed arrays
    end
  end

  describe "complete_attachment" do

    before { @attachment = Attachment.new :display_name => "I <3 testing.png" }
    context "when attachment wasn't zipped successfully" do
      it "moves the zip attachment into an error state and save!s it" do
        @attachment.expects(:save!).once
        ContentZipper.new.complete_attachment!(@attachment,"hello")
        @attachment.workflow_state.should == 'errored'
      end
    end

    context "attachment was zipped successfully" do
      it "creates uploaded data for the assignment and marks it as available" do
        @attachment.expects(:save!).once
        zip_name = "submissions.zip"
        zip_path = File.join(ActionController::TestCase.fixture_path, zip_name)
        data = "just some stub data"
        Rack::Test::UploadedFile.expects(:new).with(zip_path, 'application/zip').returns data
        @attachment.expects(:uploaded_data=).with data
        zipper = ContentZipper.new
        zipper.mark_successful!
        zipper.complete_attachment!(@attachment,zip_path)
        @attachment.should be_zipped
        @attachment.file_state.should == 'available'
      end
    end
  end

  describe "zip_quiz" do
    it "delegates to a QuizSubmissionZipper" do
      course_with_teacher_logged_in(active_all: true)
      attachment = Attachment.new(:display_name => 'download.zip')
      quiz = Quizzes::Quiz.new(:context => @course)
      zipper_stub = stub
      zipper_stub.expects(:zip!).once
      attachment.context = quiz
      Quizzes::QuizSubmissionZipper.expects(:new).with(
        quiz: quiz,
        zip_attachment: attachment
      ).returns zipper_stub
      ContentZipper.process_attachment(attachment,quiz)
    end
  end
end
