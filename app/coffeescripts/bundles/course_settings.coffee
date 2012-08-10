require [
  'compiled/views/course_settings/UserCollectionView'
  'compiled/collections/UserCollection'
  'compiled/views/course_settings/tabs/tabUsers'
  'vendor/jquery.cookie'
  'course_settings'
  'external_tools'
  'grading_standards'
], (UserCollectionView, UserCollection) ->

  loadUsersTab = ->
    window.app = usersTab: {}
    for eType in ['student', 'observer', 'teacher', 'designer', 'ta']
      # produces app.usersTab.studentsView .observerView etc.
      window.app.usersTab["#{eType}sView"] = new UserCollectionView
        el: $("##{eType}_enrollments")
        url: ENV.USERS_URL
        requestParams:
          enrollment_type: eType

  $ ->
    if $("#tab-users").is(":visible")
      loadUsersTab()

    $("#course_details_tabs").bind 'tabsshow', (e,ui) ->
      if ui.tab.hash == '#tab-users' and not window.app?.usersTab
        loadUsersTab()