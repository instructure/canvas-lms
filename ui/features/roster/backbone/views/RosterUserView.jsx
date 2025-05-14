//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, some, every, find as _find, filter, reject, isEmpty} from 'lodash'
import {View} from '@canvas/backbone'
import template from '../../jst/rosterUser.handlebars'
import EditSectionsView from './EditSectionsView'
import EditRolesView from './EditRolesView'
import InvitationsView from './InvitationsView'
import React from 'react'
import {createRoot} from 'react-dom/client'
import {Avatar} from '@instructure/ui-avatar'
import LinkToStudents from '../../react/LinkToStudents'
import {nanoid} from 'nanoid'
import 'jquery-kyle-menu'
import '@canvas/jquery/jquery.disableWhileLoading'
import RosterDialogMixin from './RosterDialogMixin'
import UserTaggedModal from '@canvas/differentiation-tags/react/UserTaggedModal/UserTaggedModal'
import MessageBus from '@canvas/util/MessageBus'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('RosterUserView')

let editSectionsDialog = null
let editRolesDialog = null
let invitationDialog = null

export default class RosterUserView extends View {
  static initClass() {
    this.mixin(RosterDialogMixin)

    this.prototype.tagName = 'tr'

    this.prototype.className = 'rosterUser al-hover-container'

    this.prototype.template = template

    this.prototype.events = {
      'click .admin-links [data-event]': 'handleMenuEvent',
      'focus *': 'focus',
      'blur *': 'blur',
      'change .select-user-checkbox': 'handleCheckboxChange',
      'click .user-tags-icon': 'handleTagIconClick',
      'keydown .select-user-checkbox': 'handleKeyDown',
    }
  }

  attach() {
    $(document).on('keydown', e => {
      if (e.key === 'Shift') {
        this.isShiftPressed = true
      }
    })

    $(document).on('keyup', e => {
      if (e.key === 'Shift') {
        this.isShiftPressed = false
      }
    })

    return this.model.on('change', this.render, this)
  }

  initialize(options) {
    options.model.attributes.avatarId = `user-avatar-people-page-${nanoid()}`
    super.initialize(...arguments)
    // assumes this model only has enrollments for 1 role
    this.model.currentRole = __guard__(this.model.get('enrollments')[0], x => x.role)

    this.$el.attr('id', `user_${options.model.get('id')}`)

    this.isShiftPressed = false
    return Array.from(this.model.get('enrollments')).map(e => this.$el.addClass(e.type))
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    this.permissionsJSON(json)
    this.observerJSON(json)
    this.contextCardJSON(json)
    const collection = this.model.collection
    if (collection && collection.masterSelected) {
      // If masterSelected is true, mark as selected unless explicitly de-selected.
      json.isSelected = !collection.deselectedUserIds.includes(this.model.id)
    } else {
      json.isSelected = collection?.selectedUserIds?.includes(this.model.id) ?? false
    }
    return json
  }

  contextCardJSON(json) {
    let enrollment
    if ((enrollment = _find(json.enrollments, e => e.type === 'StudentEnrollment'))) {
      return (json.course_id = enrollment.course_id)
    }
  }

  permissionsJSON(json) {
    json.url = `${ENV.COURSE_ROOT_URL}/users/${this.model.get('id')}`
    json.isObserver = this.model.hasEnrollmentType('ObserverEnrollment')
    json.isStudent = this.model.hasEnrollmentType('StudentEnrollment')
    json.isPending = this.model.pending(this.model.currentRole)
    json.isInactive = this.model.inactive()
    if (!json.isInactive) {
      json.enrollments = reject(json.enrollments, en => en.enrollment_state === 'inactive') // if not _completely_ inactive, treat the inactive enrollments as deleted
    }
    json.canRemoveUsers = every(this.model.get('enrollments'), e => e.can_be_removed)
    json.canResendInvitation =
      !json.isInactive &&
      some(this.model.get('enrollments'), en =>
        ENV.permissions.active_granular_enrollment_permissions.includes(en.type),
      )

    if (json.canRemoveUsers && !ENV.course.concluded) {
      json.canEditRoles = !some(
        this.model.get('enrollments'),
        e => e.type === 'ObserverEnrollment' && e.associated_user_id,
      )
    }

    json.canEditSections = !json.isInactive && !isEmpty(this.model.sectionEditableEnrollments())
    json.canLinkStudents = json.isObserver && !ENV.course.concluded
    json.canViewLoginIdColumn = ENV.permissions.view_user_logins
    json.canViewSisIdColumn = ENV.permissions.read_sis
    json.canManageDifferentiationTags =
      ENV.permissions.can_manage_differentiation_tags &&
      ENV.permissions.allow_assign_to_differentiation_tags

    const candoAdminActions = ENV.permissions.can_allow_course_admin_actions

    json.canManage = some(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], et =>
      this.model.hasEnrollmentType(et),
    )
      ? candoAdminActions
      : this.model.hasEnrollmentType('ObserverEnrollment')
        ? candoAdminActions || ENV.permissions.manage_students
        : ENV.permissions.manage_students
    json.customLinks = this.model.get('custom_links')

    if (json.canViewLoginIdColumn) {
      json.canViewLoginId = true
    }

    if (json.canViewSisIdColumn) {
      json.canViewSisId = true
      json.sis_id = json.sis_user_id
    }
    json.hideSectionsOnCourseUsersPage = ENV.course.hideSectionsOnCourseUsersPage
    return json
  }

  observerJSON(json) {
    if (json.isObserver) {
      let user
      const observerEnrollments = filter(json.enrollments, en => en.type === 'ObserverEnrollment')
      json.enrollments = reject(json.enrollments, en => en.type === 'ObserverEnrollment')

      json.sections = map(json.enrollments, en => ENV.CONTEXTS.sections[en.course_section_id])

      const users = {}
      if (
        observerEnrollments.length >= 1 &&
        every(observerEnrollments, enrollment => !enrollment.observed_user)
      ) {
        users[''] = {name: I18n.t('nobody', 'nobody')}
      } else {
        for (const en of Array.from(observerEnrollments)) {
          if (!en.observed_user) {
            continue
          }
          user = en.observed_user
          if (!users[user.id]) {
            users[user.id] = user
          }
        }
      }

      return (() => {
        const result = []
        for (const id in users) {
          user = users[id]
          const ob = {
            role: I18n.t('observing_user', 'Observing: %{user_name}', {user_name: user.name}),
          }
          result.push(json.enrollments.push(ob))
        }
        return result
      })()
    }
  }

  resendInvitation() {
    if (!invitationDialog) {
      invitationDialog = new InvitationsView()
    }
    invitationDialog.model = this.model
    return invitationDialog.render().show()
  }

  editSections() {
    if (!editSectionsDialog) {
      editSectionsDialog = new EditSectionsView()
    }
    editSectionsDialog.model = this.model
    return editSectionsDialog.render().show()
  }

  editRoles() {
    if (!editRolesDialog) {
      editRolesDialog = new EditRolesView()
    }
    editRolesDialog.model = this.model
    return editRolesDialog.render().show()
  }

  getUniqueObservees(enrollments) {
    const uniqueObserveesMap = new Map()

    for (const enrollment of enrollments) {
      if (uniqueObserveesMap.has(enrollment.observed_user.id)) {
        continue
      }
      uniqueObserveesMap.set(enrollment.observed_user.id, enrollment.observed_user)
    }

    return Array.from(uniqueObserveesMap.values())
  }

  linkToStudents() {
    const mountPoint = document.getElementById('link_to_students_mount_point')
    const root = createRoot(mountPoint)
    const observer = this.model.attributes
    const observerEnrollmentsWithObservedUser = observer.enrollments.filter(
      enrollment => enrollment.type === 'ObserverEnrollment' && enrollment.observed_user,
    )
    const initialObservees = this.getUniqueObservees(observerEnrollmentsWithObservedUser)
    const course = ENV.current_context

    root.render(
      <LinkToStudents
        observer={observer}
        initialObservees={initialObservees}
        course={course}
        onSubmit={(addedEnrollments, removedEnrollments) => {
          this.updateEnrollments(addedEnrollments, removedEnrollments)
        }}
        onClose={() => {
          root.unmount()
        }}
      />,
    )
  }

  deactivateUser() {
    if (
      !window.confirm(
        I18n.t(
          'Are you sure you want to deactivate this user? They will be unable to participate in the course while inactive.',
        ),
      )
    ) {
      return
    }
    const deferreds = []
    for (const en of Array.from(this.model.get('enrollments'))) {
      if (en.enrollment_state !== 'inactive') {
        const url = `/api/v1/courses/${ENV.course.id}/enrollments/${en.id}?task=deactivate`
        en.enrollment_state = 'inactive'
        deferreds.push($.ajaxJSON(url, 'DELETE'))
      }
    }

    return $('.roster-tab').disableWhileLoading(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.render()
          return $.flashMessage(I18n.t('User successfully deactivated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t('Something went wrong while deactivating the user. Please try again later.'),
          ),
        ),
    )
  }

  reactivateUser() {
    const deferreds = []
    for (const en of Array.from(this.model.get('enrollments'))) {
      const url = `/api/v1/courses/${ENV.course.id}/enrollments/${en.id}/reactivate`
      en.enrollment_state = 'active'
      deferreds.push($.ajaxJSON(url, 'PUT'))
    }

    return $('.roster-tab').disableWhileLoading(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.render()
          return $.flashMessage(I18n.t('User successfully re-activated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t('Something went wrong re-activating the user. Please try again later.'),
          ),
        ),
    )
  }

  removeFromCourse(_e) {
    if (!window.confirm(I18n.t('Are you sure you want to remove this user?'))) {
      return
    }
    this.$el.hide()
    const success = () => {
      // TODO: change the count on the search roles drop down
      $.flashMessage(I18n.t('User successfully removed.'))
      const $previousRow = this.$el.prev(':visible')

      try {
        queryClient.invalidateQueries({
          queryKey: ['differentiationTagCategories'],
          exact: false,
        })
      } catch (error) {
        console.error('Error invalidating query, error:', error)
      }

      const $focusElement = $previousRow.length ? $previousRow.find('.al-trigger') : $('#addUsers')
      return $focusElement.focus()
    }

    const failure = () => {
      this.$el.show()
      return $.flashError(
        I18n.t('flash.removeError', 'Unable to remove the user. Please try again later.'),
      )
    }
    const deferreds = map(this.model.get('enrollments'), e =>
      $.ajaxJSON(`${ENV.COURSE_ROOT_URL}/unenroll/${e.id}`, 'DELETE'),
    )
    return $.when(...Array.from(deferreds || [])).then(success, failure)
  }

  handleMenuEvent(e) {
    this.blur()
    e.preventDefault()
    const method = $(e.currentTarget).data('event')
    return this[method].call(this, e)
  }

  // Helper for range selection
  handleRangeSelection(isChecked, currentIndex) {
    const {selectedUserIds, masterSelected, deselectedUserIds, lastCheckedIndex} =
      this.model.collection
    const $checkboxes = $(
      this.model.collection
        .map(model => model.view.$('.select-user-checkbox').get(0))
        .filter(Boolean),
    )
    const start = Math.min(lastCheckedIndex, currentIndex)
    const end = Math.max(lastCheckedIndex, currentIndex)

    if (start === end) {
      return
    }

    for (let i = start; i <= end; i++) {
      const checkbox = $checkboxes[i]
      const checkboxUserId = this.model.collection.models.filter(rosterUser =>
        rosterUser.hasEnrollmentType('StudentEnrollment'),
      )[i].id
      if (isChecked) {
        if (!selectedUserIds.includes(checkboxUserId)) {
          selectedUserIds.push(checkboxUserId)
        }
        this.model.collection.deselectedUserIds = deselectedUserIds.filter(
          id => id !== checkboxUserId,
        )
      } else {
        selectedUserIds.splice(
          0,
          selectedUserIds.length,
          ...selectedUserIds.filter(id => id !== checkboxUserId),
        )
        if (masterSelected && !deselectedUserIds.includes(checkboxUserId)) {
          this.model.collection.deselectedUserIds.push(checkboxUserId)
        }
      }
      $(checkbox).prop('checked', isChecked)
    }
    this.model.collection.lastCheckedIndex = currentIndex
    MessageBus.trigger('userSelectionChanged', {
      model: this.model,
      selected: isChecked,
      selectedUsers: this.model.collection.selectedUserIds,
      deselectedUserIds: this.model.collection.deselectedUserIds,
      masterSelected: this.model.collection.masterSelected,
    })
  }

  // If unchecking a user while master is on, add them to the "deselected" list
  handleCheckboxChange(e) {
    const isChecked = $(e.currentTarget).is(':checked')
    const userId = this.model.id
    const {selectedUserIds, masterSelected, deselectedUserIds, lastCheckedIndex} =
      this.model.collection
    const $checkboxes = $(
      this.model.collection
        .map(model => model.view.$('.select-user-checkbox').get(0))
        .filter(Boolean),
    )
    const currentIndex = $checkboxes.index($(e.currentTarget))
    if (this.isShiftPressed && lastCheckedIndex !== null) {
      this.handleRangeSelection(isChecked, currentIndex)
    } else {
      if (isChecked) {
        // Add user to selected list if not already
        if (!selectedUserIds.includes(userId)) {
          selectedUserIds.push(userId)
        }
        // Remove from deselected list if present
        this.model.collection.deselectedUserIds = deselectedUserIds.filter(id => id !== userId)
      } else {
        // Remove from selected list
        this.model.collection.selectedUserIds = selectedUserIds.filter(id => id !== userId)

        // If master is set, add to deselected list
        if (masterSelected && !deselectedUserIds.includes(userId)) {
          this.model.collection.deselectedUserIds.push(userId)
        }
      }

      this.model.collection.lastCheckedIndex = this.model.collection.selectedUserIds.length
        ? currentIndex
        : null

      MessageBus.trigger('userSelectionChanged', {
        model: this.model,
        selected: isChecked,
        selectedUsers: this.model.collection.selectedUserIds,
        deselectedUserIds: this.model.collection.deselectedUserIds,
        masterSelected: this.model.collection.masterSelected,
      })
    }
  }

  handleKeyDown(e) {
    // Only act if the focused element is a checkbox
    if (e.key === 'Shift') {
      e.preventDefault()
      const isChecked = !$(e.currentTarget).is(':checked')
      const $checkboxes = $(
        this.model.collection
          .map(model => model.view.$('.select-user-checkbox').get(0))
          .filter(Boolean),
      )
      const currentIndex = $checkboxes.index($(e.currentTarget))
      const {lastCheckedIndex} = this.model.collection
      if (lastCheckedIndex !== null) {
        this.handleRangeSelection(isChecked, currentIndex)
      }
    }
  }

  handleTagIconClick() {
    this.renderUserTagModal(true, this.model.id, this.model.get('name'))
  }

  renderUserTagModal(isOpen, userId, userName) {
    const el = document.getElementById('userTagsModalContainer')
    const returnFocusTo = document.getElementById(`tag-icon-id-${userId}`)
    const onModalClose = (userId, userName) => {
      this.renderUserTagModal(false, userId, userName)
      returnFocusTo?.focus()
      this.userTagModalContainer.unmount()
      this.userTagModalContainer = null
    }
    if (!this.userTagModalContainer) this.userTagModalContainer = createRoot(el)
    this.userTagModalContainer.render(
      <UserTaggedModal
        isOpen={isOpen}
        courseId={ENV.course.id}
        userId={userId}
        userName={userName}
        onClose={onModalClose}
      />,
    )
  }

  focus() {
    return this.$el.addClass('al-hover-container-active table-hover-row')
  }

  blur() {
    return this.$el.removeClass('al-hover-container-active table-hover-row')
  }

  afterRender() {
    const container = this.$el.find(`#${this.model.attributes.avatarId}`)[0]
    if (container) {
      const root = createRoot(container)
      root.render(
        <a href={`users/${this.model.id}`}>
          <Avatar
            name={this.model.attributes.name}
            src={this.model.attributes.avatar_url}
            size="small"
            alt={this.model.attributes.name}
          />
          <span className="screenreader-only">{this.model.attributes.name}</span>
        </a>,
      )
      this._reactRoot = root
    }
    this.userTagModalContainer = null
  }

  remove() {
    $(document).off('keydown')
    $(document).off('keyup')

    if (this._reactRoot) {
      this._reactRoot.unmount()
    }
    if (this.userTagModalContainer) {
      this.userTagModalContainer.unmount()
      this.userTagModalContainer = null
    }
    return super.remove(...arguments)
  }
}
RosterUserView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
