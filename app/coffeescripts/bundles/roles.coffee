require [
  'jquery'
  'underscore'
  'compiled/models/Role'
  'compiled/models/Account'
  'compiled/collections/RolesCollection'
  'compiled/views/roles/RolesOverrideIndexView'
  'compiled/views/roles/AccountRolesView'
  'compiled/views/roles/CourseRolesView'
  'compiled/views/roles/ManageRolesView'
  'compiled/views/roles/NewRoleView'
], ($, _, Role, Account, RolesCollection, RolesOverrideIndexView, AccountRolesView, CourseRolesView, ManageRolesView, NewRoleView) -> 
  account_roles = new RolesCollection ENV.ACCOUNT_ROLES
  course_roles = new RolesCollection ENV.COURSE_ROLES

  course_permissions = ENV.COURSE_PERMISSIONS
  account_permissions = ENV.ACCOUNT_PERMISSIONS

  course_role_types = []
  _.each ENV.COURSE_ROLES, (role) ->
    if role.role == role.base_role_type
      course_role_types.push
        value : role.base_role_type
        label : role.label

  # They will both use the same collection.
  rolesOverrideIndexView = new RolesOverrideIndexView 
    el: '#content'
    showCourseRoles: !ENV.IS_SITE_ADMIN
    views:
      'account-roles': new AccountRolesView
        views: 
          '#account_roles' : new ManageRolesView
            collection: account_roles
            permission_groups: account_permissions
          'new-role' : new NewRoleView
            base_role_types: [{value:'AccountMembership', label:'AccountMembership'}]
            admin_roles: true
            collection: account_roles

      'course-roles': new CourseRolesView
        views: 
          '#course_roles' : new ManageRolesView
            collection: course_roles
            permission_groups: course_permissions
          'new-role' : new NewRoleView
            base_role_types: course_role_types
            collection: course_roles

  rolesOverrideIndexView.render()

  # Make sure the left navigation permissions is highlighted. 
  $('#section-tabs .permissions').addClass 'active'

  # This is not the right way to do this and is just a hack until 
  # something offical in canvas is built. 
  # Adds toggle functionality to the menu buttons.
  # Yes, it's ugly but works :) Sorry.
  # ============================================================
  # DELETE ME SOMEDAY!
  # ============================================================
  $(document).on 'click', (event) -> 
    container = $('.btn-group')
    if (container.has(event.target).length is 0 and !$(event.target).hasClass('.btn'))
      container.removeClass 'open'

  $(document).on 'click', '.btn', (event) -> 
    event.preventDefault()
    previous_state = $(this).parent().hasClass 'open'
    $('.btn-group').removeClass 'open'

    if (previous_state == false && !$(this).attr('disabled') )
      $(this).parent().addClass('open')
      $(this).siblings('.dropdown-menu').find('input').first().focus()

    $(document).on 'keyup', (event) => 
      if (event.keyCode == 27)
        $('.btn-group').removeClass 'open'
        $(this).focus()


  ##################################################################
