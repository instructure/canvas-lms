require File.expand_path(File.dirname(__FILE__) + '/../common')

module CollaborationsCommon
  # Public: Determine if a collaboration form is visible.
  #
  # Returns a boolean.
  def expect_form_to_be_visible
    expect(fj('.collaborator-picker:visible')).to be_present
  end

  # Public: Determine if a collaboration form is not visible.
  #
  # Returns a boolean.
  def expect_form_not_to_be_visible
    expect(f("#content")).not_to contain_jqcss('.collaborator-picker:visible')
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
      expect(f('#delete_collaboration_dialog .delete_button')).to be_displayed
      f('#delete_collaboration_dialog .delete_button').click
    end
    expect(f("#content")).not_to contain_css(".collaboration_#{collaboration.id} .delete_collaboration_link")
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

      driver.execute_script 'window.confirm = function(msg) { return true; }' if execute_script
      form_visible ? expect_form_to_be_visible : expect_form_not_to_be_visible
    end
  end

  # Public: Create a new collaboration.
  #
  # type - The type of the collaboration (e.g. "etherpad" or "google_docs")
  # title - The title of the new collaboration (default: "New collaboration").
  #
  # Returns a boolean.
  def create_collaboration!(collaboration_type, title = 'New collaboration')

    plugin_type = collaboration_type
    plugin_type = 'google_drive' if plugin_type == 'google_docs'
    unless PluginSetting.where(:name => plugin_type).exists?
      PluginSetting.create!(:name => plugin_type, :settings => {})
    end

    name = Collaboration.collaboration_types.detect{|t| t[:type] == collaboration_type}[:name]

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

    f('#collaboration_title').send_keys(collaboration_name)

    fj('.available-users:visible a').click
    expect(ff('.members-list li')).to have_size(1)

    f('button[type="submit"]').click

    # close the extra window so it doesn't cause focus problems for subsequent specs
    close_extra_windows
  end
end
