define [
  'jquery'
  'underscore'
  'helpers/fakeENV'
  'compiled/gradebook2/GradebookHeaderMenu'
  'compiled/gradebook2/SetDefaultGradeDialog'
  'compiled/gradebook2/CurveGradesDialog'
], ($, _, fakeENV, GradebookHeaderMenu, SetDefaultGradeDialog, CurveGradesDialog) ->

  module 'GradebookHeaderMenu#menuPopupOpenHandler',
    setup: ->
      @menuPopupOpenHandler = GradebookHeaderMenu.prototype.menuPopupOpenHandler
      @hideMenuActionsWithUnmetDependencies = @stub()
      @disableUnavailableMenuActions = @stub()

      @menu = 'mockMenu'

    teardown: ->
      fakeENV.teardown()

  test 'calls @hideMenuActionsWithUnmetDependencies when isAdmin', ->
    fakeENV.setup({current_user_roles: ['admin']})
    @menuPopupOpenHandler()
    ok @hideMenuActionsWithUnmetDependencies.called

  test 'calls @hideMenuActionsWithUnmetDependencies when not isAdmin', ->
    fakeENV.setup({current_user_roles: []})
    @menuPopupOpenHandler()
    ok @hideMenuActionsWithUnmetDependencies.called

  test 'does not call @disableUnavailableMenuActions when isAdmin', ->
    fakeENV.setup({current_user_roles: ['admin']})
    @menuPopupOpenHandler()
    notOk @disableUnavailableMenuActions.called

  test 'calls @disableUnavailableMenuActions when not isAdmin', ->
    fakeENV.setup({current_user_roles: []})
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
      fakeENV.setup({
        GRADEBOOK_OPTIONS: {
          multiple_grading_periods_enabled: true
        }
      })
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

  test 'disables 0 menu items when given a menu but @assignment does not exist', ->
    @disableUnavailableMenuActions(@menu)
    equal @disabledMenuItems(@menu).length, 0

  test 'disables 0 menu items when given a menu and @assignment which does not have inClosedGradingPeriod set', ->
    @assignment = {}

    @disableUnavailableMenuActions(@menu)
    equal @disabledMenuItems(@menu).length, 0

  test 'disables 0 menu items when given a menu and @assignment which has inClosedGradingPeriod set', ->
    @assignment = {
      inClosedGradingPeriod: false
    }

    @disableUnavailableMenuActions(@menu)
    equal @disabledMenuItems(@menu).length, 0

  test 'given an assignment in closed grading period, disable curveGrades and setDefaultGrade menu items', ->
    @assignment = {
      inClosedGradingPeriod: true
    }

    @disableUnavailableMenuActions(@menu)

    disabledMenuItems = @disabledMenuItems(@menu)
    equal disabledMenuItems.length, 2
    equal disabledMenuItems[0].getAttribute('data-action'), 'curveGrades'
    equal disabledMenuItems[1].getAttribute('data-action'), 'setDefaultGrade'
    ok disabledMenuItems[0].getAttribute('aria-disabled')
    ok disabledMenuItems[1].getAttribute('aria-disabled')

  module 'GradebookHeaderMenu#setDefaultGrade',
    setup: ->
      fakeENV.setup({
        GRADEBOOK_OPTIONS: {
          multiple_grading_periods_enabled: true
        },
        current_user_roles: ['admin']
      })
      @setDefaultGrade = GradebookHeaderMenu.prototype.setDefaultGrade

      @options = {
        assignment: {
          inClosedGradingPeriod: false
        }
      }
      @spy($, 'flashError')
      @dialogStub = @stub SetDefaultGradeDialog.prototype, 'initDialog'

    teardown: ->
      fakeENV.teardown()

  test 'calls the SetDefaultGradeDialog when isAdmin is true and assignment ' +
    'has no due date in a closed grading period', ->
      @setDefaultGrade(@options)

      ok @dialogStub.called

  test 'calls the SetDefaultGradeDialog when isAdmin is true and assignment ' +
    'does have a due date in a closed grading period', ->
      @options.assignment.inClosedGradingPeriod = true
      @setDefaultGrade(@options)

      ok @dialogStub.called

  test 'calls the SetDefaultGradeDialog when isAdmin is false and assignment ' +
    'has no due date in a closed grading period', ->
      ENV.current_user_roles = []
      @setDefaultGrade(@options)

      ok @dialogStub.called

  test 'calls the flashError when isAdmin is false and assignment does have ' +
    'a due date in a closed grading period', ->
      ENV.current_user_roles = []
      @options.assignment.inClosedGradingPeriod = true
      @setDefaultGrade(@options)

      notOk @dialogStub.called
      ok $.flashError.called

  module 'GradebookHeaderMenu#curveGrades',
    setup: ->
      fakeENV.setup({
        GRADEBOOK_OPTIONS: {
          multiple_grading_periods_enabled: true
        },
        current_user_roles: ['admin']
      })
      @curveGrades = GradebookHeaderMenu.prototype.curveGrades

      @options = {
        assignment: {
          inClosedGradingPeriod: false
        }
      }
      @spy($, 'flashError')
      @dialogStub = @stub CurveGradesDialog.prototype, 'initDialog'

    teardown: ->
      fakeENV.teardown()

  test 'calls the CurveGradesDialog when isAdmin is true and assignment has ' +
    'no due date in a closed grading period', ->
      @curveGrades(@options)

      ok @dialogStub.called

  test 'calls the CurveGradesDialog when isAdmin is true and assignment ' +
    'does have a due date in a closed grading period', ->
      @options.assignment.inClosedGradingPeriod = true
      @curveGrades(@options)

      ok @dialogStub.called

  test 'calls the CurveGradesDialog when isAdmin is false and assignment ' +
    'has no due date in a closed grading period', ->
      ENV.current_user_roles = []
      @curveGrades(@options)

      ok @dialogStub.called

  test 'calls flashError when isAdmin is false and assignment does have ' +
    'a due date in a closed grading period', ->
      ENV.current_user_roles = []
      @options.assignment.inClosedGradingPeriod = true
      @curveGrades(@options)

      notOk @dialogStub.called
      ok $.flashError.called
