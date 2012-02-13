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

  def test_checkbox(css_context, user, checked)
    is_checked("#{css_context} ul.collaborator_list input#user_#{user.id}").should == checked
  end

  context "collaborations as a teacher" do

    [["EtherPad", "etherpad"], ["Google Docs", "google_docs"]].each do |collab_title, collab_type|

      context collab_title do

        before (:each) do
          course_with_teacher_logged_in
          if collab_type == "google_docs"
            CollaborationsController.any_instance.stubs(:google_docs_verify_access_token).returns(true)
          end
        end

        it 'should automatically start the new collaboration wizard in the absence of collaborations' do
          PluginSetting.create!(:name => collab_type, :settings => {})

          get "/courses/#{@course.id}/collaborations"
          wait_for_ajaximations
          assert_wizard_visibility true
        end

        it 'should not automatically start the new collaboration wizard in the presence of collaborations' do
          PluginSetting.create!(:name => collab_type, :settings => {})
          @collaboration = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration.context = @course
          @collaboration.attributes = {:title => "My Collab"}
          @collaboration.save!

          get "/courses/#{@course.id}/collaborations"
          wait_for_ajaximations
          assert_wizard_visibility false
        end

        it 'should leave the collaboration wizard open when someone navigates to the add_collaboration fragment and there is no collaborations' do
          skip_if_ie('Java crashes')
          PluginSetting.create!(:name => collab_type, :settings => {})

          get "/courses/#{@course.id}/collaborations/"
          get "/courses/#{@course.id}/collaborations/#add_collaboration"
          wait_for_ajaximations
          assert_wizard_visibility true
        end

        it 'should leave the collaboration wizard open when someone navigates to the add_collaboration fragment and there is some collaborations' do
          skip_if_ie('Java crashes')
          PluginSetting.create!(:name => collab_type, :settings => {})
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
          skip_if_ie('Java crashes')
          PluginSetting.create!(:name => collab_type, :settings => {})
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

        it "should not show collaborator selection menus if there aren't any collaborators" do
          PluginSetting.create!(:name => collab_type, :settings => {})
          @collaboration = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration.context = @course
          @collaboration.attributes = {:title => "My Collab"}
          @collaboration.save!
          get "/courses/#{@course.id}/collaborations/"
          wait_for_ajaximations
          driver.find_element(:css, "div.collaboration_#{@collaboration.id} a.edit_collaboration_link").click
          wait_for_ajaximations
          driver.find_element(:css, "form.collaboration_#{@collaboration.id} div.footer").should_not include_text('Collaborate With')
          driver.execute_script("$('.add_collaboration_link').click();")
          driver.find_element(:css, "form#add_collaboration_form div.collaborator_list").should_not include_text('Collaborate With')
        end

        it "should show collaborator selection menus if there are any collaborators" do
          PluginSetting.create!(:name => collab_type, :settings => {})
          student_in_course :course => @course
          @student.name = "test student 1"
          @student.save!
          @collaboration = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration.context = @course
          @collaboration.attributes = {:title => "My Collab"}
          @collaboration.save!
          get "/courses/#{@course.id}/collaborations/"
          wait_for_ajaximations
          driver.find_element(:css, "div.collaboration_#{@collaboration.id} a.edit_collaboration_link").click
          wait_for_ajaximations
          driver.find_element(:css, "form.collaboration_#{@collaboration.id} div.footer").should include_text('Collaborate With')
          driver.execute_script("$('.add_collaboration_link').click();")
          driver.find_element(:css, "form#add_collaboration_form div.collaborator_list").should include_text('Collaborate With')
        end

        it "should show collaborator selection menus if there are any collaborators" do
          PluginSetting.create!(:name => collab_type, :settings => {})
          student_in_course :course => @course, :name => "test student 1"
          @collaboration = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration.context = @course
          @collaboration.attributes = {:title => "My Collab"}
          @collaboration.save!
          get "/courses/#{@course.id}/collaborations/"
          wait_for_ajaximations
          driver.find_element(:css, "div.collaboration_#{@collaboration.id} a.edit_collaboration_link").click
          wait_for_ajaximations
          driver.find_element(:css, "form.collaboration_#{@collaboration.id} div.footer").should include_text('Collaborate With')
          driver.execute_script("$('.add_collaboration_link').click();")
          driver.find_element(:css, "form#add_collaboration_form div.collaborator_list").should include_text('Collaborate With')
        end

        it "should distinguish checkbox lists when someone clicks (de)select all" do
          PluginSetting.create!(:name => collab_type, :settings => {})
          @students = [student_in_course(:course => @course, :name => "test student 1").user,
                       student_in_course(:course => @course, :name => "test student 2").user,
                       student_in_course(:course => @course, :name => "test student 3").user,
                       student_in_course(:course => @course, :name => "test student 4").user]
          @collaboration1 = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration1.context = @course
          @collaboration1.attributes = {:title => "My Collab 1"}
          @collaboration1.save!
          @collaboration2 = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration2.context = @course
          @collaboration2.attributes = {:title => "My Collab 2"}
          @collaboration2.save!
          @collaboration3 = Collaboration.typed_collaboration_instance(collab_title)
          @collaboration3.context = @course
          @collaboration3.attributes = {:title => "My Collab 3"}
          @collaboration3.save!
          get "/courses/#{@course.id}/collaborations/"
          wait_for_ajaximations
          driver.find_element(:css, "div.collaboration_#{@collaboration1.id} a.edit_collaboration_link").click
          driver.find_element(:css, "div.collaboration_#{@collaboration2.id} a.edit_collaboration_link").click
          driver.find_element(:css, "div.collaboration_#{@collaboration3.id} a.edit_collaboration_link").click
          driver.execute_script("$('.add_collaboration_link').click();")
          wait_for_ajaximations

          forms = ["form#add_collaboration_form",
                   "form.collaboration_#{@collaboration1.id}",
                   "form.collaboration_#{@collaboration2.id}",
                   "form.collaboration_#{@collaboration3.id}"]
          @students.each do |student|
            forms.each do |form|
              test_checkbox form, student, false
            end
          end

          forms.each do |form|
            driver.find_element(:css, "#{form} a.select_all_link").click
            @students.each do |student|
              forms.each do |other_form|
                test_checkbox other_form, student, form == other_form
              end
            end
            driver.find_element(:css, "#{form} a.deselect_all_link").click
            @students.each do |student|
              forms.each do |other_form|
                test_checkbox other_form, student, false
              end
            end
          end

          forms.each do |form|
            driver.find_element(:css, "#{form} a.select_all_link").click
          end
          @students.each do |student|
            forms.each do |form|
              test_checkbox form, student, true
            end
          end

          forms.each do |form|
            driver.find_element(:css, "#{form} a.deselect_all_link").click
            @students.each do |student|
              forms.each do |other_form|
                test_checkbox other_form, student, form != other_form
              end
            end
            driver.find_element(:css, "#{form} a.select_all_link").click
            @students.each do |student|
              forms.each do |other_form|
                test_checkbox other_form, student, true
              end
            end
          end
        end
      end
    end
  end

  context "etherpad collaborations as a student" do

    before (:each) do
      course_with_teacher(:active_all => true, :name => 'teacher@example.com')
      student_in_course(:course => @course, :name => "example student").user
    end

    it "should create a collaboration and validate that a student can see it" do
      collaborators = [] #[@current_user]
      PluginSetting.create!(:name => 'etherpad', :settings => {})
      @collaboration = Collaboration.typed_collaboration_instance('EtherPad')
      @collaboration.context = @course
      @collaboration.attributes = {:title => "My Collab", :user => @teacher}
      collaborators << @student if user
      @collaboration.collaboration_users = collaborators
      @collaboration.save!

      user_session(@student)
      get "/courses/#{@course.id}/collaborations"
      wait_for_ajaximations
      collaboration = driver.find_element(:css, ".collaboration_#{@collaboration.id}")
      collaboration.should be_displayed
      collaboration.find_element(:css, '.toggle_collaborators_link').click
      wait_for_animations
      collaboration.find_element(:css, '.collaborators').should include_text(@student.name)
      collaboration.find_element(:css, '.collaborators').should include_text(@teacher.name)
    end
  end
end
