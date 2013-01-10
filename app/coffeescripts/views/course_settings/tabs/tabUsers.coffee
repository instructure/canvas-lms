define [
  'jquery'
  'compiled/user_lists'
  'compiled/models/User'
], ($, UL, User) ->

  $enrollUsersForm = $("#enroll_users_form")
  $enrollUsersForm.hide()
  $(".add_users_link").click (event) ->
    $(this).hide()
    event.preventDefault()
    $enrollUsersForm.show()
    $("html,body").scrollTo $enrollUsersForm
    $enrollUsersForm.find("#enrollment_type").focus().select()

  # override adding to the users lists to work with UserCollectionView
  UL.addUserToList = (enrollment) ->
    user_list_id = null
    if enrollment.custom_role_asset_string
      user_list_id = enrollment.custom_role_asset_string
      viewName = user_list_id + 'sView'
    else
      user_list_id = $.underscore(enrollment.type) + "s"
      viewName = user_list_id.split('_')[0] + 'sView'
    $("#" + user_list_id).find(".none").remove()
    view = app.usersTab[viewName]
    users = view.collection
    # see if the user is already enrolled _with this role_
    if ($userEl = $("#" + user_list_id + " #user_" + enrollment.user_id)).length
      $userEl.remove()
      users.remove users.get(enrollment.user_id)
    user = new User id: enrollment.user_id
    user.urlRoot = users.url
    user.fetch
      data: ENV.USER_PARAMS
      success: (u, r) -> users.add u
    if enrollment.already_enrolled
      1
    else
      view.incrementCount(user)
      0
