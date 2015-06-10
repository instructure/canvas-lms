def new_collaborations_form(type)
  PluginSetting.create!(:name => type, :settings => {})
  validate_collaborations
end

def be_editable(type, title)
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

def no_edit_if_no_access(type, title)
  create_collaboration!(type, title)
  validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

  #Negitave check
  expect(f('.edit_collaboration_link')).to be_nil
end

def be_deletable(type, title)
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

def display_available_collaborators(type)
  PluginSetting.create!(:name => type, :settings => {})

  student_in_course(:course => @course)
  @student.update_attribute(:name, 'Don Draper')

  get "/courses/#{@course.id}/collaborations"

  keep_trying_until {
    expect(ffj('.available-users:visible li').length).to eq 1
  }
end

def select_collaborators(type)
  PluginSetting.create!(:name => type, :settings => {})

  student_in_course(:course => @course)
  @student.update_attribute(:name, 'Don Draper')

  get "/courses/#{@course.id}/collaborations"

  fj('.available-users:visible a').click
  keep_trying_until {
    expect(ffj('.members-list li').length).to eq 1
  }
end

def select_from_all_course_groups(type, title)
  group_model(:context => @course, :name => "grup grup")

  create_collaboration!(type, title)
  validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

  f('.edit_collaboration_link').click
  wait_for_ajaximations
  fj("#groups-filter-btn-#{@collaboration.id}:visible").click
  wait_for_ajaximations

  groups = ffj('.available-groups:visible a')
  expect(groups.count).to eq 1
  groups.first.click
  wait_for_ajaximations

  keep_trying_until {
    expect(ffj('.members-list li').length).to eq 1
  }
  expect_new_page_load do
    submit_form('.edit_collaboration')
  end
  @collaboration.reload
  collaborator = @collaboration.collaborators.where(:group_id => @group).first
  expect(collaborator).to_not be_blank
end

def deselect_collaborators(type)
  PluginSetting.create!(:name => type, :settings => {})

  student_in_course(:course => @course)
  @student.update_attribute(:name, 'Don Draper')

  get "/courses/#{@course.id}/collaborations"

  fj('.available-users:visible a').click
  fj('.members-list a').click
  expect(ffj('.members-list li').length).to eq 0
end

def select_collaborators_and_look_for_start(type)
  PluginSetting.create!(:name => type, :settings => {})

  collaboration_name = "StreetsOfRage"
  manually_create_collaboration(collaboration_name)

  get "/courses/#{@course.id}/collaborations"
  expect(f('.title')).to include_text(collaboration_name)
end


def no_edit_with_no_access
  create_collaboration!('google_docs', 'Google Docs')
  validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

  #Negitave check
  expect(f('.edit_collaboration_link')).to be_nil
end

def no_delete_with_no_access
  create_collaboration!('google_docs', 'Google Docs')
  validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)

  #Negitave check
  expect(f('.delete_collaboration_link')).to be_nil
end

def not_display_new_form_if_none_exist(type,title)
  create_collaboration!(type, title)
  validate_collaborations(%W{/courses/#{@course.id}/collaborations}, false)
end

def display_new_form_if_none_exist(type)
  PluginSetting.create!(:name => type, :settings => {})
  validate_collaborations(%W{/courses/#{@course.id}/collaborations
            /courses/#{@course.id}/collaborations#add_collaboration}, true)
end

def hide_new_form_if_exists(type,title)
    create_collaboration!(type, title)
    validate_collaborations(%W{/courses/#{@course.id}/collaborations
              /courses/#{@course.id}/collaborations#add_collaboration}, false)
end

def open_form_if_last_was_deleted(type, title)
  create_collaboration!(type, title)
  validate_collaborations("/courses/#{@course.id}/collaborations/", false, true)
  delete_collaboration(@collaboration, type)
  expect(form_visible?).to be_truthy
end

def not_display_new_form_when_penultimate_collaboration_is_deleted(type, title)
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

def leave_new_form_open_when_last_is_deleted(type, title)
  create_collaboration!(type, title)
  validate_collaborations(%W{/courses/#{@course.id}/collaborations
                                     /courses/#{@course.id}/collaborations#add_collaboration}, false, true)
  f('.add_collaboration_link').click
  delete_collaboration(@collaboration, type)
  expect(form_visible?).to be_truthy
end
