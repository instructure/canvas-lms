require File.expand_path(File.dirname(__FILE__) + '/../common')

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
  if (type == "google_docs")
    PluginSetting.create!(:name => 'google_drive', :settings => {})
  end
  #PluginSetting.where(:name => type).destroy_all
  #PluginSetting.where(:name => 'google_drive').destroy_all

  @collaboration         = Collaboration.typed_collaboration_instance(title)
  @collaboration.context = @course
  @collaboration.title   = title
  @collaboration.user = @user
  @collaboration.save!
end

def set_up_google_docs(type, setupDrive = true)
  UserService.register(
      :service => "google_docs",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
  )

  GoogleDocs::Connection.any_instance.
      stubs(:verify_access_token).
      returns(true)

  # GoogleDocs::Connection.any_instance.
  #     stubs(:list).
  #     returns(nil)


  GoogleDocsCollaboration.any_instance.
      stubs(:initialize_document).
      returns(nil)

  GoogleDocsCollaboration.any_instance.
      stubs(:delete_document).
      returns(nil)

  if (setupDrive == true)
    set_up_drive_connection
  end

end

def set_up_drive_connection
  UserService.register(
      :service => "google_drive",
      :token => "token",
      :secret => "secret",
      :user => @user,
      :service_domain => "drive.google.com",
      :service_user_id => "service_user_id",
      :service_user_name => "service_user_name"
  )

  GoogleDocs::DriveConnection.any_instance.
      stubs(:verify_access_token).
      returns(true)
end

def manually_create_collaboration(collaboration_name)
  student_in_course(:course => @course)
  @student.update_attribute(:name, 'Don Draper')

  get "/courses/#{@course.id}/collaborations"

  fj('#collaboration_title').send_keys(collaboration_name)

  fj('.available-users:visible a').click
  keep_trying_until {
    expect(ffj('.members-list li').length).to eq 1
  }

  f('button[type="submit"]').click
end