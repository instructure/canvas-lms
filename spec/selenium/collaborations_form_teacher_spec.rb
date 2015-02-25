require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_specs_common')

describe "collaborations" do
  include_examples "in-process server selenium tests"

  context "a teacher's" do
    [['EtherPad', 'etherpad'], ['Google Docs', 'google_docs']].each do |title, type|
      context "#{title} collaboration" do
        before(:each) do
          course_with_teacher_logged_in
          set_up_google_docs(type)
        end

        # The if statements before each spec are to set the test id based on what tye of collaboration we are doing
        # A test_id of zero means that it does not match up to a testrails test case
        if type == 'etherpad' then test_id = 162355 end
        if type == 'google_docs' then test_id = 162302 end
        it 'should display the new collaboration form if there are no existing collaborations',
           :priority => "1", :test_id => test_id do
          new_collaborations_form(type)
        end

        if type == 'etherpad' then test_id = 162348 end
        if type == 'google_docs' then test_id = 162300 end
        it 'should not display the new collaboration form if other collaborations exist', :priority => "1", :test_id => test_id do
          not_display_new_form_if_none_exist(type,title)
        end

        if type == 'etherpad' then test_id = 162310 end
        if type == 'google_docs' then test_id = 162309 end
        it 'should open the new collaboration form if the last collaboration is deleted', :priority => "1", :test_id => test_id do
          open_form_if_last_was_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 162327 end
        if type == 'google_docs' then test_id = 162328 end
        it 'should not display the new collaboration form when the penultimate collaboration is deleted', :priority => "1", :test_id => test_id do
          not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 162336 end
        if type == 'google_docs' then test_id = 162337 end
        it 'should leave the new collaboration form open when the last collaboration is deleted', :priority => "1", :test_id => test_id do
          leave_new_form_open_when_last_is_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 159851 end
        if type == 'google_docs' then test_id = 158507 end
        it 'should display available collaborators', :priority => "1", :test_id => test_id do
          display_available_collaborators(type)
        end

        if type == 'etherpad' then test_id = 159849 end
        if type == 'google_docs' then test_id = 159848 end
        it 'should select collaborators', :priority => "1", :test_id => test_id do
          select_collaborators(type)
        end

        if type == 'etherpad' then test_id = 162351 end
        if type == 'google_docs' then test_id = 162352 end
        it 'should select from all course groups', :priority => "1", :test_id => test_id do
          select_from_all_course_groups(type,title)
        end

        if type == 'etherpad' then test_id = 159850 end
        if type == 'google_docs' then test_id = 139054 end
        it 'should deselect collaborators', :priority => "1", :test_id => test_id do
          deselect_collaborators(type)
        end

        context '#add_collaboration fragment' do
          if type == 'etherpad' then test_id = 162346 end
          if type == 'google_docs' then test_id = 162345 end
          it 'should display the new collaboration form if no collaborations exist', :priority => "2", :test_id => test_id do
            display_new_form_if_none_exist(type)
          end

          if type == 'etherpad' then test_id = 162341 end
          if type == 'google_docs' then test_id = 162342 end
          it 'should hide the new collaboration form if collaborations exist', :priority => "2", :test_id => test_id do
            hide_new_form_if_exists(type,title)
          end
        end
      end
    end
  end
end