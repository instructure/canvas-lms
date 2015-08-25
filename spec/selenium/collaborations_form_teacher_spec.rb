require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_specs_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/google_drive_common')

describe "collaborations" do
  include_context "in-process server selenium tests"

  context "a teacher's" do
    title = 'Google Docs'
    type = 'google_docs'

    context "#{title} collaboration" do
      before(:each) do
        course_with_teacher_logged_in
        set_up_google_docs
      end

      it 'should display the new collaboration form if there are no existing collaborations', priority: "1", test_id: 132521 do
        # was tied to test_id: 162302 - this seems incorrect.
        new_collaborations_form(type)
      end

      it 'should not display the new collaboration form if other collaborations exist', priority: "1", test_id: 162300 do
        not_display_new_form_if_none_exist(type, title)
      end

      it 'should open the new collaboration form if the last collaboration is deleted', priority: "1", test_id: 162309 do
        open_form_if_last_was_deleted(type, title)
      end

      it 'should not display the new collaboration form when the penultimate collaboration is deleted', priority: "1", test_id: 162328 do
        not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
      end

      it 'should leave the new collaboration form open when the last collaboration is deleted', priority: "1", test_id: 162337 do
        leave_new_form_open_when_last_is_deleted(type, title)
      end

      it 'should select collaborators', priority: "1", test_id: 159848 do
        select_collaborators(type)
      end

      it 'should select from all course groups', priority: "1", test_id: 162352 do
        select_from_all_course_groups(type,title)
      end

      it 'should deselect collaborators', priority: "1", test_id: 139054 do
        deselect_collaborators(type)
      end

      context '#add_collaboration fragment' do
        it 'should display the new collaboration form if no collaborations exist', priority: "2", test_id: 162345 do
          display_new_form_if_none_exist(type)
        end

        it 'should hide the new collaboration form if collaborations exist', priority: "2", test_id: 162342 do
          hide_new_form_if_exists(type, title)
        end
      end
    end
  end
end