define [
  'jquery'
  'underscore'
  'helpers/fakeENV'
  'compiled/gradebook2/GradebookHeaderMenu'
  'compiled/gradebook2/SetDefaultGradeDialog'
  'compiled/gradebook2/CurveGradesDialog'
], (
  $, _, fakeENV, GradebookHeaderMenu, SetDefaultGradeDialog, CurveGradesDialog
) ->

  module 'GradebookHeaderMenu#isCurrentUserAdmin',
    setup: ->
      fakeENV.setup()
      @isCurrentUserAdmin = GradebookHeaderMenu.prototype.isCurrentUserAdmin

    teardown: ->
      fakeENV.teardown()

  test 'returns false if ENV.current_user_roles exists but does not contain the admin role', ->
    ENV.current_user_roles = ['forty_two', 'plebian']

    equal @isCurrentUserAdmin(), false

  test 'returns true if ENV.current_user_roles contains the admin role', ->
    ENV.current_user_roles = ['admin']

    equal @isCurrentUserAdmin(), true

  module 'GradebookHeaderMenu#menuPopupOpenHandler',
    setup: ->
      @menuPopupOpenHandler = GradebookHeaderMenu.prototype.menuPopupOpenHandler
      @hideMenuActionsWithUnmetDependencies = @stub()
      @disableUnavailableMenuActions = @stub()

      @menu = 'mockMenu'

    teardown: ->

  test 'calls @hideMenuActionsWithUnmetDependencies with the passed in menu when
    @isCurrentUserAdmin returns true', ->
    @isCurrentUserAdmin = @stub().returns(true)
    @menuPopupOpenHandler()

    ok @hideMenuActionsWithUnmetDependencies.called

  test 'calls @hideMenuActionsWithUnmetDependencies with the passed in menu when
    @isCurrentUserAdmin returns false', ->
    @isCurrentUserAdmin = @stub().returns(false)
    @menuPopupOpenHandler()

    ok @hideMenuActionsWithUnmetDependencies.called

  test 'does not call @disableUnavailableMenuActions with the passed in menu when
    @isCurrentUserAdmin returns true', ->
    @isCurrentUserAdmin = @stub().returns(true)
    @menuPopupOpenHandler()

    notOk @disableUnavailableMenuActions.called

  test 'calls @disableUnavailableMenuActions with the passed in menu when
    @isCurrentUserAdmin returns false', ->
    @isCurrentUserAdmin = @stub().returns(false)
    @menuPopupOpenHandler()

    ok @disableUnavailableMenuActions.called

  module 'GradebookHeaderMenu#hideMenuActionsWithUnmetDependencies',
    setup: ->
      fakeENV.setup()
      @hideMenuActionsWithUnmetDependencies = GradebookHeaderMenu.prototype.hideMenuActionsWithUnmetDependencies

      # These are all set to ensure all options are visible by default
      @allSubmissionsLoaded = true
      @assignment = {
        grading_type: 'not pass_fail',
        points_possible: 10,
        submission_types: 'online_upload',
        has_submitted_submissions: true
        submissions_downloads: 1
      }
      @gradebook = {
        options: {
          gradebook_is_editable: true
        }
      }

      @menuElement = document.createElement('ul')
      @createMenu(@menuElement)
      @menu = $(@menuElement)

    teardown: ->
      fakeENV.teardown()

    createMenu: (root) ->
      menuItems = [
        'showAssignmentDetails',
        'messageStudentsWho',
        'setDefaultGrade',
        'curveGrades',
        'downloadSubmissions',
        'reuploadSubmissions'
      ]

      for item in menuItems
        menuItem = document.createElement('li')
        menuItem.setAttribute('data-action', item)

        root.appendChild(menuItem)

    visibleMenuItems: (root) ->
      root.find('li:not([style*="display: none"])')

    visibleMenuItemNames: (root) ->
      _.map @visibleMenuItems(root), (item) ->
        item.getAttribute('data-action')

  test 'hides 0 menu items given optimal conditions', ->
    @hideMenuActionsWithUnmetDependencies(@menu)

    equal @visibleMenuItems(@menu).length, 6

  test 'hides the showAssignmentDetails menu item when @allSubmissionsLoaded is false', ->
    @allSubmissionsLoaded = false
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'showAssignmentDetails')

  test 'hides the messageStudentsWho menu item when @allSubmissionsLoaded is false', ->
    @allSubmissionsLoaded = false
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'messageStudentsWho')

  test 'hides the setDefaultGrade menu item when @allSubmissionsLoaded is false', ->
    @allSubmissionsLoaded = false
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'setDefaultGrade')

  test 'hides the curveGrades menu item when @allSubmissionsLoaded is false', ->
    @allSubmissionsLoaded = false
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'curveGrades')

  test 'hides the curveGrades menu item when @assignment.grading_type is pass_fail', ->
    @assignment.grading_type = 'pass_fail'
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'curveGrades')

  test 'hides the curveGrades menu item when @assignment.points_possible is empty', ->
    delete @assignment.points_possible
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'curveGrades')

  test 'hides the curveGrades menu item when @assignment.points_possible is 0', ->
    @assignment.points_possible = 0
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'curveGrades')

  test 'does not hide the downloadSubmissions menu item when @assignment.submission_types is online_text_entry or online_url', ->
    for submission_type in ['online_text_entry', 'online_url']
      @assignment.submission_types = 'online_text_entry'
      @hideMenuActionsWithUnmetDependencies(@menu)

      ok _.contains(@visibleMenuItemNames(@menu), 'downloadSubmissions')

  test 'hides the downloadSubmissions menu item when @assignment.submission_types is not one of online_upload, online_text_entry or online_url', ->
    @assignment.submission_types = 'go-ravens'
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'downloadSubmissions')

  test 'hides the reuploadSubmissions menu item when gradebook is editable', ->
    @gradebook.options.gradebook_is_editable = false
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'reuploadSubmissions')

  test 'hides the reuploadSubmissions menu item when @assignment.submission_downloads is 0', ->
    @assignment.submissions_downloads = 0
    @hideMenuActionsWithUnmetDependencies(@menu)

    notOk _.contains(@visibleMenuItemNames(@menu), 'reuploadSubmissions')

  module 'GradebookHeaderMenu#disableUnavailableMenuActions',
    setup: ->
      fakeENV.setup()
      @disableUnavailableMenuActions = GradebookHeaderMenu.prototype.disableUnavailableMenuActions

      @menuElement = document.createElement('ul')
      @createMenu(@menuElement)
      @menu = $(@menuElement)

    teardown: ->
      fakeENV.teardown()

    createMenu: (root) ->
      menuItems = ['first', 'second', 'curveGrades', 'setDefaultGrade', 'fifth']

      for item in menuItems
        menuItem = document.createElement('li')
        menuItem.setAttribute('data-action', item)

        root.appendChild(menuItem)

    disabledMenuItems: (root) ->
      root.find('.ui-state-disabled')

  test 'returns false when not given a menu', ->
    equal @disableUnavailableMenuActions(), false

  test 'disables 0 menu items when given a menu but @assignment does not exist', ->
    equal @disableUnavailableMenuActions(@menu), false
    equal @disabledMenuItems(@menu).length, 0

  test 'disables 0 menu items when given a menu and @assignment which does not have
    has_due_date_in_closed_grading_period set', ->
    @assignment = {}

    equal @disableUnavailableMenuActions(@menu), false
    equal @disabledMenuItems(@menu).length, 0

  test 'disables 0 menu items when given a menu and @assignment which has
    has_due_date_in_closed_grading_period set', ->
    @assignment = {
      has_due_date_in_closed_grading_period: false
    }

    equal @disableUnavailableMenuActions(@menu), false
    equal @disabledMenuItems(@menu).length, 0

  test 'disables the curveGrades and setDefaultGrade menu items when given a menu and @assignment
    which _does_ have has_due_date_in_closed_grading_period set', ->
    @assignment = {
      has_due_date_in_closed_grading_period: true
    }

    equal @disableUnavailableMenuActions(@menu), true

    disabledMenuItems = @disabledMenuItems(@menu)
    equal disabledMenuItems.length, 2
    equal disabledMenuItems[0].getAttribute('data-action'), 'curveGrades'
    equal disabledMenuItems[1].getAttribute('data-action'), 'setDefaultGrade'
    ok disabledMenuItems[0].getAttribute('aria-disabled'), true
    ok disabledMenuItems[1].getAttribute('aria-disabled'), true

  module 'GradebookHeaderMenu#setDefaultGrade',
    setup: ->
      fakeENV.setup()
      @setDefaultGrade = GradebookHeaderMenu.prototype.setDefaultGrade

      @options = {
        isAdmin: true
        assignment: {
          has_due_date_in_closed_grading_period: false
        }
      }
      @spy($, 'flashError')
      @dialogStub = @stub SetDefaultGradeDialog.prototype, 'initDialog'

    teardown: ->
      fakeENV.teardown()

  test 'calls the SetDefaultGradeDialog when isAdmin is true and assignment has no due date in
    a closed grading period', ->
    @setDefaultGrade(@options)

    ok @dialogStub.called

  test 'calls the SetDefaultGradeDialog when isAdmin is true and assignment does have a due date in
    a closed grading period', ->
    @options.assignment.has_due_date_in_closed_grading_period = true
    @setDefaultGrade(@options)

    ok @dialogStub.called

  test 'calls the SetDefaultGradeDialog when isAdmin is false and assignment has no due date in
    a closed grading period', ->
    @options.isAdmin = false
    @setDefaultGrade(@options)

    ok @dialogStub.called

  test 'calls the flashError when isAdmin is false and assignment does have a due date in
    a closed grading period', ->
    @options.isAdmin = false
    @options.assignment.has_due_date_in_closed_grading_period = true
    @setDefaultGrade(@options)

    notOk @dialogStub.called
    ok $.flashError.called

  module 'GradebookHeaderMenu#curveGrades',
    setup: ->
      fakeENV.setup()
      @curveGrades = GradebookHeaderMenu.prototype.curveGrades

      @options = {
        isAdmin: true
        assignment: {
          has_due_date_in_closed_grading_period: false
        }
      }
      @spy($, 'flashError')
      @dialogStub = @stub CurveGradesDialog.prototype, 'initDialog'

    teardown: ->
      fakeENV.teardown()

  test 'calls the CurveGradesDialog when isAdmin is true and assignment has no due date in
    a closed grading period', ->
    @curveGrades(@options)

    ok @dialogStub.called

  test 'calls the CurveGradesDialog when isAdmin is true and assignment does have a due date in
    a closed grading period', ->
    @options.assignment.has_due_date_in_closed_grading_period = true
    @curveGrades(@options)

    ok @dialogStub.called

  test 'calls the CurveGradesDialog when isAdmin is false and assignment has no due date in
    a closed grading period', ->
    @options.isAdmin = false
    @curveGrades(@options)

    ok @dialogStub.called

  test 'calls the flashError when isAdmin is false and assignment does have a due date in
    a closed grading period', ->
    @options.isAdmin = false
    @options.assignment.has_due_date_in_closed_grading_period = true
    @curveGrades(@options)

    notOk @dialogStub.called
    ok $.flashError.called
