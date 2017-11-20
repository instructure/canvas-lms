/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!roles'
import RolesCollection from 'compiled/collections/RolesCollection'
import RolesOverrideIndexView from 'compiled/views/roles/RolesOverrideIndexView'
import RolesCollectionView from 'compiled/views/roles/RolesCollectionView'
import ManageRolesView from 'compiled/views/roles/ManageRolesView'
import NewRoleView from 'compiled/views/roles/NewRoleView'

const accountRoles = new RolesCollection(ENV.ACCOUNT_ROLES)
const courseRoles = new RolesCollection(ENV.COURSE_ROLES)

const coursePermissions = ENV.COURSE_PERMISSIONS
const accountPermissions = ENV.ACCOUNT_PERMISSIONS

const courseBaseTypes = []
_.each(ENV.COURSE_ROLES, (role) => {
  if (role.role === role.base_role_type) {
    courseBaseTypes.push({
      value: role.base_role_type,
      label: role.label
    })
  }
})

const accountBaseTypes = [{value: 'AccountMembership', label: ''}]

// They will both use the same collection.
const rolesOverrideIndexView = new RolesOverrideIndexView({
  el: '#content',
  showCourseRoles: !ENV.IS_SITE_ADMIN,
  views: {
    'account-roles': new RolesCollectionView({
      newRoleView: new NewRoleView({
        title: I18n.t('New Account Role'),
        base_role_types: accountBaseTypes,
        collection: accountRoles,
        label_id: 'new_account'
      }),
      views: {
        roles_table: new ManageRolesView({
          collection: accountRoles,
          base_role_types: accountBaseTypes,
          permission_groups: accountPermissions
        })
      }
    }),
    'course-roles': new RolesCollectionView({
      newRoleView: new NewRoleView({
        title: I18n.t('New Course Role'),
        base_role_types: courseBaseTypes,
        collection: courseRoles,
        label_id: 'new_course'
      }),
      views: {
        roles_table: new ManageRolesView({
          collection: courseRoles,
          base_role_types: courseBaseTypes,
          permission_groups: coursePermissions
        })
      }
    })
  }
})

rolesOverrideIndexView.render()

// This is not the right way to do this and is just a hack until
// something offical in canvas is built.
// Adds toggle functionality to the menu buttons.
// Yes, it's ugly but works :) Sorry.
// ============================================================
// DELETE ME SOMEDAY!
// ============================================================
$(document).on('click', (event) => {
  const container = $('.btn-group')
  if (container.has(event.target).length === 0 && !$(event.target).hasClass('.btn')) {
    container.removeClass('open')
  }
  return true
})
$(document).on('focus', 'label', (e) => {
  return false
})
$(document).on('click', '.btn.dropdown-toggle', function (event) {
  event.preventDefault()
  const previousState = $(this).parent().hasClass('open')
  $('.btn-group').removeClass('open')

  if (previousState === false && !$(this).attr('disabled')) {
    $(this).parent().addClass('open')
    const inputFocus = $(this).siblings('.dropdown-menu').find('input:checked').attr('id')
    $(`[for=${inputFocus}]`).focus()
  }
  $(document).on('keyup', (event) => {
    if (event.keyCode === 27) {
      $('.btn-group').removeClass('open')
      $(this).focus()
    }
  })
})
// #################################################################
