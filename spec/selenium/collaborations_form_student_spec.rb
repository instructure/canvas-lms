require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/collaborations_specs_common')

describe "collaborations" do
  include_examples "in-process server selenium tests"

  context "a student's" do
    [['EtherPad', 'etherpad'], ['Google Docs', 'google_docs']].each do |title, type|
      context "#{title} collaboration" do
        before(:each) do
          course_with_student_logged_in
          set_up_google_docs(type)
        end

        # The if statements before each spec are to set the test id based on what tye of collaboration we are doing
        # A test_id of zero means that it does not match up to a testrails test case
        if type == 'etherpad' then test_id = 162353 end
        if type == 'google_docs' then test_id = 162354 end
        it 'should display the new collaboration form if there are no existing collaborations',
           :priority => "1", :test_id => test_id do
          new_collaborations_form(type)
        end

        if type == 'etherpad' then test_id = 138617 end
        if type == 'google_docs' then test_id = 162347 end
        it 'should not display the new collaboration form if other collaborations exist', :priority => "1", :test_id => test_id do
          not_display_new_form_if_none_exist(type,title)
        end

        if type == 'etherpad' then test_id = 138619 end
        if type == 'google_docs' then test_id = 162320 end
        it 'should open the new collaboration form if the last collaboration is deleted', :priority => "1", :test_id => test_id do
          open_form_if_last_was_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 138620 end
        if type == 'google_docs' then test_id = 162326 end
        it 'should not display the new collaboration form when the penultimate collaboration is deleted', :priority => "1", :test_id => test_id do
          not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 138621 end
        if type == 'google_docs' then test_id = 162335 end
        it 'should leave the new collaboration form open when the last collaboration is deleted', :priority => "1", :test_id => test_id do
          leave_new_form_open_when_last_is_deleted(type, title)
        end

        if type == 'etherpad' then test_id = 159851 end
        if type == 'google_docs' then test_id = 158507 end
        it 'should display available collaborators', :priority => "1", :test_id => test_id do
          display_available_collaborators(type)
        end

        if type == 'etherpad' then test_id = 138614 end
        if type == 'google_docs' then test_id = 162359 end
        it 'should select collaborators', :priority => "1", :test_id => test_id do
          select_collaborators(type)
        end

        if type == 'etherpad' then test_id = 138615 end
        if type == 'google_docs' then test_id = 162360 end
        it 'should deselect collaborators', :priority => "1", :test_id => test_id do
          deselect_collaborators(type)
        end

        context '#add_collaboration fragment' do
          if type == 'etherpad' then test_id = 162343 end
          if type == 'google_docs' then test_id = 162344 end
          it 'should display the new collaboration form if no collaborations exist', :priority => "2", :test_id => test_id do
            display_new_form_if_none_exist(type)
          end

          if type == 'etherpad' then test_id = 138618 end
          if type == 'google_docs' then test_id = 162340 end
          it 'should hide the new collaboration form if collaborations exist', :priority => "2", :test_id => test_id do
            hide_new_form_if_exists(type,title)
          end
        end
      end
    end

    context "a students's etherpad collaboration" do
      before(:each) do
        course_with_teacher(:active_all => true, :name => 'teacher@example.com')
        student_in_course(:course => @course, :name => 'Don Draper')
      end

      it 'should not show groups the student does not belong to', :priority => "1", :test_id => 162368 do
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
