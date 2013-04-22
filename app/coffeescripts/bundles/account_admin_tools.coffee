require [
  'compiled/models/CourseRestore'
  'compiled/views/accounts/admin_tools/AdminToolsView'
  'compiled/views/accounts/admin_tools/RestoreContentPaneView'
  'compiled/views/accounts/admin_tools/CourseSearchFormView'
  'compiled/views/accounts/admin_tools/CourseSearchResultsView'
  ], (CourseRestoreModel, AdminToolsView, RestoreContentPaneView, CourseSearchFormView, CourseSearchResultsView) -> 
    # This is used by admin tools to display search results
    restoreModel = new CourseRestoreModel account_id: ENV.ACCOUNT_ID

    # Render tabs
    admin_tools_view = new AdminToolsView
      tabs: 
        courseRestore: ENV.PERMISSIONS.restore_course
      el: "#content"
      restoreContentPaneView: new RestoreContentPaneView
                                courseSearchFormView: new CourseSearchFormView
                                  model: restoreModel
                                courseSearchResultsView: new CourseSearchResultsView
                                  model: restoreModel

    admin_tools_view.render()

