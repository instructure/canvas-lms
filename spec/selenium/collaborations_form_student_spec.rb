require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_specs_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/google_drive_common')

describe "collaborations" do
  include_context "in-process server selenium tests"

  context "a student's" do
    title = 'Google Docs'
    type = 'google_docs'

    context "#{title} collaboration" do
      before(:each) do
        course_with_student_logged_in
        set_up_google_docs
      end

      it 'should display the new collaboration form if there are no existing collaborations', priority: "1", test_id: 162354 do
        new_collaborations_form(type)
      end

      it 'should not display the new collaboration form if other collaborations exist', priority: "1", test_id: 162347 do
        not_display_new_form_if_none_exist(type, title)
      end

      it 'should open the new collaboration form if the last collaboration is deleted', priority: "1", test_id: 162320 do
        open_form_if_last_was_deleted(type, title)
      end

      it 'should not display the new collaboration form when the penultimate collaboration is deleted', priority: "1", test_id: 162326 do
        not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
      end

      it 'should leave the new collaboration form open when the last collaboration is deleted', priority: "1", test_id: 162335 do
        leave_new_form_open_when_last_is_deleted(type, title)
      end

      it 'should select collaborators', priority: "1", test_id: 162359 do
        select_collaborators(type)
      end

      it 'should deselect collaborators', priority: "1", test_id: 162360 do
        deselect_collaborators(type)
      end

      context '#add_collaboration fragment' do
        it 'should display the new collaboration form if no collaborations exist', priority: "2", test_id: 162344 do
          display_new_form_if_none_exist(type)
        end

        it 'should hide the new collaboration form if collaborations exist', priority: "2", test_id: 162340 do
          hide_new_form_if_exists(type, title)
        end
      end
    end


    context "a students's etherpad collaboration" do
      before(:each) do
        course_with_teacher(:active_all => true, :name => 'teacher@example.com')
        student_in_course(:course => @course, :name => 'Don Draper')
      end

      it 'should not show groups the student does not belong to', priority: "1", test_id: 162368 do
        PluginSetting.create!(:name => 'etherpad', :settings => {})
        group1 = "grup grup"

        group_model(:context => @course, :name => group1)
        @group.add_user(@student)
        group_model(:context => @course, :name => "other grup")

        user_session(@student)
        get "/courses/#{@course.id}/collaborations"

        fj("#groups-filter-btn-new:visible").click
        wait_for_ajaximations

        expect(ffj('.available-groups:visible a').count).to eq 1
        expect(fj('.available-groups:visible a')).to include_text(group1)
      end
    end
  end
end
