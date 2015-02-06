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
          expect(form_visible?).to be_truthy
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
          expect(form_visible?).to be_falsey
          delete_collaboration(@collaboration2, type)
          expect(form_visible?).to be_truthy
        end

        it 'should leave the new collaboration form open when the last collaboration is deleted' do
          create_collaboration!(type, title)
          validate_collaborations(%W{/courses/#{@course.id}/collaborations
                                     /courses/#{@course.id}/collaborations#add_collaboration}, false, true)
          f('.add_collaboration_link').click
          delete_collaboration(@collaboration, type)
          expect(form_visible?).to be_truthy
        end
      end
    end
  end
end