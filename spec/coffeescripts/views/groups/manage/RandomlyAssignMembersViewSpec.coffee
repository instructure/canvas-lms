define [
  'jquery'
  'underscore'
  'compiled/views/groups/manage/GroupCategoryView'
  'compiled/views/groups/manage/RandomlyAssignMembersView'
  'compiled/models/GroupCategory'
  'helpers/fakeENV'
], ($, _, GroupCategoryView, RandomlyAssignMembersView, GroupCategory) ->

  server = null
  view = null
  model = null
  globalObj = this

  sendResponse = (method, url, json) ->
    server.respond {"cascade": false}, method, url, [200, {
      'Content-Type': 'application/json'
    }, JSON.stringify(json)]

  groupsResponse =   # GET "/api/v1/group_categories/20/groups?per_page=50&include[]=sections"
    [
      {
        "description": null,
        "group_category_id": 20,
        "id": 61,
        "is_public": false,
        "join_level": "invitation_only",
        "name": "Ninjas",
        "members_count": 14,
        "storage_quota_mb": 50,
        "context_type": "Course",
        "course_id": 1,
        "avatar_url": null,
        "role": null
      },
      {
        "description": null,
        "group_category_id": 20,
        "id": 62,
        "is_public": false,
        "join_level": "invitation_only",
        "name": "Samurai",
        "members_count": 14,
        "storage_quota_mb": 50,
        "context_type": "Course",
        "course_id": 1,
        "avatar_url": null,
        "role": null
      },
      {
        "description": null,
        "group_category_id": 20,
        "id": 395,
        "is_public": false,
        "join_level": "invitation_only",
        "name": "Pirates",
        "members_count": 12,
        "storage_quota_mb": 50,
        "context_type": "Course",
        "course_id": 1,
        "avatar_url": null,
        "role": null
      }
    ]

  unassignedUsersResponse =   # GET "/api/v1/group_categories/20/users?unassigned=true&per_page=50"
    [
      {
        "id": 41,
        "name": "Panda Farmer",
        "sortable_name": "Farmer, Panda",
        "short_name": "Panda Farmer",
        "sis_user_id": "337733",
        "sis_login_id": "pandafarmer134123@gmail.com",
        "login_id": "pandafarmer134123@gmail.com"
      },
      {
        "id": 45,
        "name": "Elmer Fudd",
        "sortable_name": "Fudd, Elmer",
        "short_name": "Elmer Fudd",
        "login_id": "elmerfudd"
      },
      {
        "id": 2,
        "name": "Leeroy Jenkins",
        "sortable_name": "Jenkins, Leeroy",
        "short_name": "Leeroy Jenkins"
      }
    ]

  assignUnassignedMembersResponse =    #  POST /api/v1/group_categories/20/assign_unassigned_members
    {
      "completion": 0,
      "context_id": 20,
      "context_type": "GroupCategory",
      "created_at": "2013-07-17T11:05:38-06:00",
      "id": 105,
      "message": null,
      "tag": "assign_unassigned_members",
      "updated_at": "2013-07-17T11:05:38-06:00",
      "user_id": null,
      "workflow_state": "running",
      "url": "http://localhost:3000/api/v1/progress/105"
    }
  progressResponse =        # GET  /api/v1/progress/105
    {
      "completion": 100,
      "context_id": 20,
      "context_type": "GroupCategory",
      "created_at": "2013-07-17T11:05:38-06:00",
      "id": 105,
      "message": null,
      "tag": "assign_unassigned_members",
      "updated_at": "2013-07-17T11:05:44-06:00",
      "user_id": null,
      "workflow_state": "completed",
      "url": "http://localhost:3000/api/v1/progress/105"
    }

  groupCategoryResponse =   # GET /api/v1/group_categories/20
    {
      "id": 20,
      "name": "Gladiators",
      "role": null,
      "self_signup": "enabled",
      "context_type": "Course",
      "course_id": 1
    }

  module 'RandomlyAssignMembersView',
    setup: ->
      server = sinon.fakeServer.create()
      @_ENV = globalObj.ENV
      globalObj.ENV =
        group_user_type: 'student'
        IS_LARGE_ROSTER: false

      model = new GroupCategory(id: 20, name: "Project Group")
      view = new GroupCategoryView
        model: model

      ##
      # instantiating GroupCategoryView will run GroupCategory.groups()
      #   therefore, server will now have one GET request for "/api/v1/group_categories/20/groups?per_page=50"
      #   and one GET request for "/api/v1/group_categories/20/users?unassigned=true&per_page=50"
      server.respondWith("GET", "/api/v1/group_categories/20/groups?per_page=50",
        [200, { "Content-Type": "application/json" }, JSON.stringify(groupsResponse)])
      server.respondWith("GET", "/api/v1/group_categories/20/users?per_page=50&include[]=sections&exclude[]=pseudonym&unassigned=true",
        [200, { "Content-Type": "application/json" }, JSON.stringify(unassignedUsersResponse)])

      view.render()
      view.$el.appendTo($("#fixtures"))

      server.respond()
      server.responses = []

    teardown: ->
      server.restore()
      globalObj.ENV = @_ENV
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'randomly assigns unassigned users', ->
    $progressContainer = $('.progress-container')
    $groups = $('[data-view=groups]')
    equal $progressContainer.length, 0, "Progress bar hidden by default"
    equal $groups.length, 1, "Groups shown by default"
    equal model.unassignedUsers().length, 3, "There are unassigned users to begin with"

    ##
    # click the options cog to reveal the options menu
    $cog = $('.icon-mini-arrow-down')
    $cog.click()

    ##
    # click the randomly assign students option to open up the confirmation dialog view
    $assignOptionLink = $('.randomly-assign-members')
    $assignOptionLink.click()

    ##
    # click the confirm button to run the assignment process
    $confirmAssignButton = $('.randomly-assign-members-confirm')
    $confirmAssignButton.click()

    ##
    # the click will fire a POST request to "/api/v1/group_categories/20/assign_unassigned_members"
    sendResponse("POST", "/api/v1/group_categories/20/assign_unassigned_members", assignUnassignedMembersResponse)

    ##
    # verify that there is progress bar
    $progressContainer = $('.progress-container')
    $groups = $('[data-view=groups]')
    equal $progressContainer.length, 1, "Shows progress bar during assigning process"
    equal $groups.length, 0, "Hides groups during assigning process"

    ##
    # progressable mixin ensures that the progress model is now polling, respond to it with a 100% completion
    sendResponse("GET", /progress/, progressResponse)

    ##
    # the 100% completion response will cascade a model.fetch request + model.groups().fetch + model.unassignedUsers().fetch calls
    sendResponse("GET", "/api/v1/group_categories/20?includes[]=unassigned_users_count&includes[]=groups_count", JSON.stringify(_.extend({}, groupCategoryResponse, {groups_count: 1, unassigned_users_count: 0})))
    server.respondWith("GET", "/api/v1/group_categories/20/groups?per_page=50",
      [200, { "Content-Type": "application/json" }, JSON.stringify(groupsResponse)])
    server.respondWith("GET", "/api/v1/group_categories/20/users?per_page=50&include[]=sections&exclude[]=pseudonym&unassigned=true",
      [200, { "Content-Type": "application/json" }, JSON.stringify([])])
    server.respond()

    ##
    # verify that the groups are shown again and the progress bar is hidden
    $progressContainer = $('.progress-container')
    $groups = $('[data-view=groups]')
    equal $progressContainer.length, 0, "Hides progress bar after assigning process"
    equal $groups.length, 1, "Reveals groups after assigning process"
    equal model.unassignedUsers().length, 0, "There are no longer unassigned users"




