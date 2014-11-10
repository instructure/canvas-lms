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
      keep_trying_until { expect(f('#delete_collaboration_dialog .delete_button')).to be_displayed }
      f('#delete_collaboration_dialog .delete_button').click
    else
      #driver.switch_to.alert.accept
    end
    keep_trying_until { expect(f(".collaboration_#{collaboration.id} .delete_collaboration_link")).to be_nil }
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
        expect(form_visible?).to eq form_visible
      }
    end
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

          UserService.register(
            :service => "google_docs",
            :token => "token",
            :secret => "secret",
            :user => @user,
            :service_domain => "google.com",
            :service_user_id => "service_user_id",
            :service_user_name => "service_user_name"
          )
          if type == 'google_docs'
            GoogleDocs::Connection.any_instance.
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

          expect(f('.collaboration .title').text).to eq new_title
          expect(Collaboration.order("id DESC").last.title).to eq new_title
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

          expect(f('#no_collaborations_message')).to be_displayed
          expect(Collaboration.order("id DESC").last).to be_deleted
        end

        it 'should display available collaborators' do
          PluginSetting.create!(:name => type, :settings => {})

          student_in_course(:course => @course)
          @student.update_attribute(:name, 'Don Draper')

          get "/courses/#{@course.id}/collaborations"

          wait_for_ajaximations

          keep_trying_until {
            expect(ffj('.available-users:visible li').length).to eq 1
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
            expect(ffj('.members-list li').length).to eq 1
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
          expect(ffj('.members-list li').length).to eq 0
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
