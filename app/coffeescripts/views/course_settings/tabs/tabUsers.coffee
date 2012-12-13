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
    alreadyExisted = false
    if enrollment.custom_role_asset_string
      enrollmentType = $.underscore(enrollment.custom_role_asset_string)
      $(".user_list." + enrollmentType + "s").find(".none").remove()
      viewName = enrollmentType + 'sView'
    else
      enrollmentType = $.underscore(enrollment.type)
      $(".user_list." + enrollmentType + "s").find(".none").remove()
      viewName = enrollmentType.split('_')[0] + 'sView'
    users = app.usersTab[viewName].collection
    if ($userEl = $("#user_" + enrollment.user_id)).length
      $userEl.remove()
      users.remove users.get(enrollment.user_id)
      alreadyExisted = true
    user = new User id: enrollment.user_id
    user.urlRoot = users.url
    user.fetch
      data: ENV.USER_PARAMS
      success: (u, r) -> users.add u
    if alreadyExisted then 1 else 0