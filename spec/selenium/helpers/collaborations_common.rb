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
  unless PluginSetting.where(:name => type).exists?
    PluginSetting.create!(:name => type, :settings => {})
    if (type == "google_docs")
      PluginSetting.create!(:name => 'google_drive', :settings => {})
    end
  end
  #PluginSetting.where(:name => type).destroy_all
  #PluginSetting.where(:name => 'google_drive').destroy_all

  name = Collaboration.collaboration_types.detect{|t| t[:type] == type}[:name]

  @collaboration         = Collaboration.typed_collaboration_instance(name)
  @collaboration.context = @course
  @collaboration.title   = title
  @collaboration.user = @user
  @collaboration.save!
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