require File.expand_path(File.dirname(__FILE__) + '/common')

describe "collaborations" do
  it_should_behave_like "in-process server selenium tests"

  def assert_wizard_visibility(visible)
    driver.execute_script("return $('div.collaborate_data div.button-container button.button-default-action').is(':visible');").should == visible
  end

  def delete_collaboration(collaboration, collab_type)
    driver.find_element(:css, "div.collaboration_#{collaboration.id} a.delete_collaboration_link").click
    wait_for_ajaximations
    if collab_type == "google_docs"
      driver.find_element(:css, "div#delete_collaboration_dialog button.delete_document_button").click
      wait_for_ajaximations
    end
  end

  [["EtherPad", "etherpad"], ["Google Docs", "google_docs"]].each do |collab_title, collab_type|

    context collab_title do

      before(:each) do
        if collab_type == "google_docs"
          controller = CollaborationsController.new
          def controller.google_docs_verify_access_token; true; end
          CollaborationsController.stub!(:new).and_return(controller)
        end
      end

      it 'should automatically start the new collaboration wizard in the absence of collaborations' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in

        get "/courses/#{@course.id}/collaborations"
        wait_for_ajaximations
        assert_wizard_visibility true
      end

      it 'should not automatically start the new collaboration wizard in the presence of collaborations' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration.context = @course
        @collaboration.attributes = {:title => "My Collab"}
        @collaboration.save!

        get "/courses/#{@course.id}/collaborations"
        wait_for_ajaximations
        assert_wizard_visibility false
      end

      it 'should leave the collaboration wizard open when someone navigates to the add_collaboration fragment and there is no collaborations' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in

        get "/courses/#{@course.id}/collaborations/"
        get "/courses/#{@course.id}/collaborations/#add_collaboration"
        wait_for_ajaximations
        assert_wizard_visibility true
      end

      it 'should leave the collaboration wizard open when someone navigates to the add_collaboration fragment and there is some collaborations' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration.context = @course
        @collaboration.attributes = {:title => "My Collab"}
        @collaboration.save!

        get "/courses/#{@course.id}/collaborations/"
        get "/courses/#{@course.id}/collaborations/#add_collaboration"
        wait_for_ajaximations
        assert_wizard_visibility true
      end

      it 'should leave the collaboration wizard open when a script clicks the add collaboration wizard button twice' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration.context = @course
        @collaboration.attributes = {:title => "My Collab"}
        @collaboration.save!

        get "/courses/#{@course.id}/collaborations/"
        wait_for_ajaximations
        assert_wizard_visibility false
        driver.execute_script("$('.add_collaboration_link').click();")
        assert_wizard_visibility true
        driver.execute_script("$('.add_collaboration_link').click();")
        assert_wizard_visibility true
      end

      it 'should open the collaboration wizard when the last collaboration is deleted' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration.context = @course
        @collaboration.attributes = {:title => "My Collab"}
        @collaboration.save!

        get "/courses/#{@course.id}/collaborations/"
        wait_for_ajaximations
        driver.execute_script "window.confirm = function(msg) { return true; }"

        assert_wizard_visibility false
        delete_collaboration @collaboration, collab_type
        assert_wizard_visibility true
      end

      it 'should not open the collaboration wizard when the penultimate collaboration is deleted' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration1 = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration1.context = @course
        @collaboration1.attributes = {:title => "My Collab 1"}
        @collaboration1.save!
        @collaboration2 = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration2.context = @course
        @collaboration2.attributes = {:title => "My Collab 2"}
        @collaboration2.save!

        get "/courses/#{@course.id}/collaborations/"
        wait_for_ajaximations
        driver.execute_script "window.confirm = function(msg) { return true; }"

        assert_wizard_visibility false
        delete_collaboration @collaboration1, collab_type
        assert_wizard_visibility false
        delete_collaboration @collaboration2, collab_type
        assert_wizard_visibility true
      end

      it 'should leave the collaboration wizard open when the last collaboration is deleted' do
        PluginSetting.create!(:name => collab_type, :settings => {})
        course_with_teacher_logged_in
        @collaboration = Collaboration.typed_collaboration_instance(collab_title)
        @collaboration.context = @course
        @collaboration.attributes = {:title => "My Collab"}
        @collaboration.save!

        get "/courses/#{@course.id}/collaborations/"
        get "/courses/#{@course.id}/collaborations/#add_collaboration"
        wait_for_ajaximations
        driver.execute_script "window.confirm = function(msg) { return true; }"

        assert_wizard_visibility true
        delete_collaboration @collaboration, collab_type
        assert_wizard_visibility true
      end

    end
  end

end
