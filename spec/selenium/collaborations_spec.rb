require File.expand_path(File.dirname(__FILE__) + '/common')

describe "collaborations" do
  include_examples "in-process server selenium tests"

  # Helper methods
  # ==============

  # Public: Determine if a collaboration form is visible.
  #
  # Returns a boolean.
  def form_visible?
    ffj('.collaborator-picker:visible').length > 0
  end

  # Public: Delete the given collaboration.
  #
  # collaboration - The collaboration model to delete.
  # type - The type of collaboration - "etherpad" or "google_docs" (default: etherpad).
  #
  # Returns nothing.
  def delete_collaboration(collaboration, type = 'etherpad')
    f(".collaboration_#{collaboration.id} .delete_collaboration_link").click

    if type == 'google_docs'
      keep_trying_until { f('#delete_collaboration_dialog .delete_button').should be_displayed }
      f('#delete_collaboration_dialog .delete_button').click
    else
      #driver.switch_to.alert.accept
    end
    keep_trying_until { f(".collaboration_#{collaboration.id} .delete_collaboration_link").should be_nil }
  end

  # Public: Given an array of collaborations, verify their presence.
  #
  # urls - An array of collaboration URLs to validate.
  # form_visible - The expected visibility of the form as a boolean (default: true).
  # execute_script - Boolean flag to override window.confirm (default: false).
  #
  # Returns nothing.
  def validate_collaborations(urls = %W{/courses/#{@course.id}/collaborations},
                              form_visible = true,
                              execute_script = false)
    Array(urls).each do |url|
      get url
      wait_for_ajaximations
      if execute_script
        driver.execute_script 'window.confirm = function(msg) { return true; }'
      end
      keep_trying_until {
        form_visible?.should == form_visible
      }
    end
  end

  # Public: Determine if the given collaborator has been selected.
  #
  # user - The collaborator to check.
  #
  # Returns a boolean.
  def collaborator_is_selected?(user)
    fj(".members-list li[data-id=#{user.id}]").present?
  end

  # Public: Create a new collaboration.
  #
  # type - The type of the collaboration (e.g. "etherpad" or "google_docs")
  # title - The title of the new collaboration (default: "New collaboration").
  #
  # Returns a boolean.
  def create_collaboration!(type, title = 'New collaboration')
    PluginSetting.create!(:name => type, :settings => {})

    @collaboration         = Collaboration.typed_collaboration_instance(title)
    @collaboration.context = @course
    @collaboration.title   = title
    @collaboration.user = @user
    @collaboration.save!
  end

  context "a teacher's" do
    [['EtherPad', 'etherpad'], ['Google Docs', 'google_docs']].each do |title, type|
      context "#{title} collaboration" do
        before(:each) do
          course_with_teacher_logged_in

          if type == 'google_docs'
            GoogleDocs.any_instance.
              stubs(:verify_access_token).
              returns(true)

            GoogleDocsCollaboration.any_instance.
                stubs(:initialize_document).
                returns(nil)

            GoogleDocsCollaboration.any_instance.
                stubs(:delete_document).
                returns(nil)
          end
        end

        it 'should display the new collaboration form if there are no existing collaborations' do
          PluginSetting.create!(:name => type, :settings => {})
          validate_collaborations
        end

        it 'should be editable' do
          create_collaboration!(type, title)
          validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

          new_title = 'Edited collaboration'
          f('.edit_collaboration_link').click
          replace_content(fj('input[name="collaboration[title]"]:visible'), new_title)
          expect_new_page_load do
            submit_form('.edit_collaboration')
          end

          f('.collaboration .title').text.should == new_title
          Collaboration.order("id DESC").last.title.should == new_title
        end

        it 'should be delete-able' do
          create_collaboration!(type, title)
          validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

          f('.delete_collaboration_link').click

          if type == 'google_docs'
            f('#delete_collaboration_dialog .delete_button').click
          else
            driver.switch_to.alert.accept
          end
          wait_for_ajaximations

          f('#no_collaborations_message').should be_displayed
          Collaboration.order("id DESC").last.should be_deleted
        end

        it 'should not display the new collaboration form if other collaborations exist' do
          create_collaboration!(type, title)
          validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)
        end

        describe '#add_collaboration fragment' do
          it 'should display the new collaboration form if no collaborations exist' do
            PluginSetting.create!(:name => type, :settings => {})
            validate_collaborations(%W{/courses/#{@course.id}/collaborations
              /courses/#{@course.id}/collaborations#add_collaboration}, true)
          end

          it 'should hide the new collaboration form if collaborations exist' do
            create_collaboration!(type, title)
            validate_collaborations(%W{/courses/#{@course.id}/collaborations
              /courses/#{@course.id}/collaborations#add_collaboration}, false)
          end
        end

        it 'should open the new collaboration form if the last collaboration is deleted' do
          create_collaboration!(type, title)
          validate_collaborations("/courses/#{@course.id}/collaborations/", false, true)
          delete_collaboration(@collaboration, type)
          form_visible?.should be_true
        end

        it 'should not display the new collaboration form when the penultimate collaboration is deleted' do
          PluginSetting.create!(:name => type, :settings => {})

          @collaboration1 = Collaboration.typed_collaboration_instance(title)
          @collaboration1.context = @course
          @collaboration1.attributes = {:title => "My Collab 1"}
          @collaboration1.user = @user
          @collaboration1.save!
          @collaboration2 = Collaboration.typed_collaboration_instance(title)
          @collaboration2.context = @course
          @collaboration2.attributes = {:title => "My Collab 2"}
          @collaboration2.user = @user
          @collaboration2.save!

          validate_collaborations("/courses/#{@course.id}/collaborations/", false, true)
          delete_collaboration(@collaboration1, type)
          form_visible?.should be_false
          delete_collaboration(@collaboration2, type)
          form_visible?.should be_true
        end

        it 'should leave the new collaboration form open when the last collaboration is deleted' do
          create_collaboration!(type, title)
          validate_collaborations(%W{/courses/#{@course.id}/collaborations
                                     /courses/#{@course.id}/collaborations#add_collaboration}, false, true)
          f('.add_collaboration_link').click
          delete_collaboration(@collaboration, type)
          form_visible?.should be_true
        end

        it 'should display available collaborators' do
          PluginSetting.create!(:name => type, :settings => {})

          student_in_course(:course => @course)
          @student.update_attribute(:name, 'Don Draper')

          get "/courses/#{@course.id}/collaborations"

          wait_for_ajaximations

          keep_trying_until {
            ffj('.available-users:visible li').length.should == 1
          }
        end

        it 'should select collaborators' do
          PluginSetting.create!(:name => type, :settings => {})

          student_in_course(:course => @course)
          @student.update_attribute(:name, 'Don Draper')

          get "/courses/#{@course.id}/collaborations"

          wait_for_ajaximations
          fj('.available-users:visible a').click
          keep_trying_until {
            ffj('.members-list li').length.should == 1
          }
        end

        it 'should deselect collaborators' do
          PluginSetting.create!(:name => type, :settings => {})

          student_in_course(:course => @course)
          @student.update_attribute(:name, 'Don Draper')

          get "/courses/#{@course.id}/collaborations"

          wait_for_ajaximations

          fj('.available-users:visible a').click
          fj('.members-list a').click
          ffj('.members-list li').length.should == 0
        end
      end
    end
  end

  context "a student's etherpad collaboration" do
    before(:each) do
      course_with_teacher(:active_all => true, :name => 'teacher@example.com')
      student_in_course(:course => @course, :name => 'Don Draper')
    end

    it 'should be visible to the student' do
      PluginSetting.create!(:name => 'etherpad', :settings => {})

      @collaboration = Collaboration.typed_collaboration_instance('EtherPad')
      @collaboration.context = @course
      @collaboration.attributes = { :title => 'My collaboration',
                                    :user  => @teacher }
      @collaboration.update_members([@student])
      @collaboration.save!

      user_session(@student)
      get "/courses/#{@course.id}/collaborations"

      wait_for_ajaximations

      ff('#collaborations .collaboration').length == 1
    end
  end
end
