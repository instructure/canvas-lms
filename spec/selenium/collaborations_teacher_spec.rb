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

        if type == 'etherpad' then test_id = 158502 end
        if type == 'google_docs' then test_id = 138612 end
        it 'should be editable', :priority => "1", :test_id => test_id do
          be_editable(type, title)
        end

        if type == 'etherpad' then test_id = 138605 end
        if type == 'google_docs' then test_id = 152301 end
        it 'should be delete-able', :priority => "1", :test_id => test_id do
          be_deletable(type, title)
        end

        if type == 'etherpad' then test_id = 159851 end
        if type == 'google_docs' then test_id = 158507 end
        it 'should display available collaborators', :priority => "1", :test_id => test_id do
          display_available_collaborators(type)
        end

        if type == 'etherpad' then test_id = 159852 end
        if type == 'google_docs' then test_id = 132544 end
        it 'start collaboration with people', :priority => "1", :test_id => test_id do
          select_collaborators_and_look_for_start(type)
        end
      end
    end

    context "Google Docs collaborations with google docs not having access" do
      before(:each) do
        course_with_teacher_logged_in
        set_up_google_docs('google_docs', false)
      end

      it 'should not be editable if google drive does not have access to your account', :priority => "1", :test_id => 160259 do
        no_edit_with_no_access
      end

      it 'should not be delete-able if google drive does not have access to your account', :priority => "2", :test_id => 162364 do
        no_delete_with_no_access
      end
    end
  end
end
