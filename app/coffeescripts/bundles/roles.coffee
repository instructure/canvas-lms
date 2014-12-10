require [
  'jquery'
  'underscore'
  'i18n!roles'
  'compiled/models/Role'
  'compiled/models/Account'
  'compiled/collections/RolesCollection'
  'compiled/views/roles/RolesOverrideIndexView'
  'compiled/views/roles/RolesCollectionView'
  'compiled/views/roles/ManageRolesView'
  'compiled/views/roles/NewRoleView'
], ($, _, I18n, Role, Account, RolesCollection, RolesOverrideIndexView, RolesCollectionView, ManageRolesView, NewRoleView, account_template, course_template) ->
  account_roles = new RolesCollection ENV.ACCOUNT_ROLES
  course_roles = new RolesCollection ENV.COURSE_ROLES

  course_permissions = ENV.COURSE_PERMISSIONS
  account_permissions = ENV.ACCOUNT_PERMISSIONS

  course_base_types = []
  _.each ENV.COURSE_ROLES, (role) ->
    if role.role == role.base_role_type
      course_base_types.push
        value : role.base_role_type
        label : role.label

  account_base_types = [{value: 'AccountMembership', label: I18n.t('AccountMembership')}]

  # They will both use the same collection.
  rolesOverrideIndexView = new RolesOverrideIndexView 
    el: '#content'
    showCourseRoles: !ENV.IS_SITE_ADMIN
    views:
      'account-roles': new RolesCollectionView
        newRoleView: new NewRoleView
          title: I18n.t('New Account Role')
          base_role_types: account_base_types
          collection: account_roles
          label_id: 'new_account'
        views: 
          'roles_table' : new ManageRolesView
            collection: account_roles
            base_role_types: account_base_types
            permission_groups: account_permissions
      'course-roles': new RolesCollectionView
        newRoleView: new NewRoleView
          title: I18n.t('New Course Role')
          base_role_types: course_base_types
          collection: course_roles
          label_id: 'new_course'
        views: 
          'roles_table' : new ManageRolesView
            collection: course_roles
            base_role_types: course_base_types
            permission_groups: course_permissions

  rolesOverrideIndexView.render()

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

  $(document).on 'click', '.btn.dropdown-toggle', (event) ->
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