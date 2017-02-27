require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_specs_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/google_drive_common')

describe "collaborations" do
  include_context "in-process server selenium tests"
  include CollaborationsCommon
  include CollaborationsSpecsCommon
  include GoogleDriveCommon

  context "a Student's" do
    title = 'Google Docs'
    type = 'google_docs'

    context "#{title} collaboration" do
      before(:each) do
        course_with_student_logged_in
        setup_google_drive
      end

      it 'should be editable', priority: "1", test_id: 158504 do
        be_editable(type, title)
      end

      it 'should be delete-able', priority: "1", test_id: 158505 do
        be_deletable(type, title)
      end

      it 'should display available collaborators', priority: "1", test_id: 162356 do
        display_available_collaborators(type)
      end

      it 'start collaboration with people', priority: "1", test_id: 162362 do
        select_collaborators_and_look_for_start(type)
      end
    end

    context "Google Docs collaborations with google docs not having access" do
      before(:each) do
        course_with_teacher_logged_in
        setup_google_drive(false, false)
      end

      it 'should not be editable if google drive does not have access to your account', priority: "1", test_id: 162363 do
        no_edit_with_no_access
      end

      it 'should not be delete-able if google drive does not have access to your account', priority: "2", test_id: 162365 do
        no_delete_with_no_access
      end
    end
  end

  context "a student's etherpad collaboration" do
    before(:each) do
      course_with_teacher(:active_all => true, :name => 'teacher@example.com')
      student_in_course(:course => @course, :name => 'Don Draper')
    end

    it 'should be visible to the student', priority: "1", test_id: 138616 do
      PluginSetting.create!(:name => 'etherpad', :settings => {})

      @collaboration = Collaboration.typed_collaboration_instance('EtherPad')
      @collaboration.context = @course
      @collaboration.attributes = { :title => 'My collaboration',
                                    :user  => @teacher }
      @collaboration.update_members([@student])
      @collaboration.save!

      user_session(@student)
      get "/courses/#{@course.id}/collaborations"

      expect(ff('#collaborations .collaboration')).to have_size(1)
    end
  end
end

