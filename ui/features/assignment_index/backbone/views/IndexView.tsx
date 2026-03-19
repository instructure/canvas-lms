/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {debounce} from 'es-toolkit/compat'
import {useScope as createI18nScope} from '@canvas/i18n'
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
import keyboardNavTemplate from '@canvas/keyboard-nav-dialog/jst/KeyboardNavDialog.handlebars'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import React from 'react'
import {createRoot} from 'react-dom/client'
import template from '../../jst/IndexView.handlebars'
import NoAssignmentsSearch from '../../react/NoAssignmentsSearch'
import AssignmentKeyBindingsMixin from '../mixins/AssignmentKeyBindingsMixin'
import userSettings from '@canvas/user-settings'
import GradingPeriodsAPI from '@canvas/grading/jquery/gradingPeriodsApi'
import IndexMenu from '../../react/IndexMenu'
import configureIndexMenuStore from '../../react/stores/indexMenuStore'
import BulkEditIndex from '../../react/bulk_edit/BulkEditIndex'
import '@canvas/rails-flash-notifications'
import easy_student_view from '@canvas/easy-student-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import IndexCreate from '../../react/IndexCreate'

const I18n = createI18nScope('assignmentsIndexView')

// @ts-expect-error
extend(IndexView, Backbone.View)

// @ts-expect-error
function IndexView() {
  // @ts-expect-error
  this.filterKeyBindings = this.filterKeyBindings.bind(this)
  // @ts-expect-error
  this.focusOnAssignments = this.focusOnAssignments.bind(this)
  // @ts-expect-error
  this.filterResults = this.filterResults.bind(this)
  // @ts-expect-error
  this.hide_dnd_warning = this.hide_dnd_warning.bind(this)
  // @ts-expect-error
  this.show_dnd_warning = this.show_dnd_warning.bind(this)
  // @ts-expect-error
  this.cancelBulkEdit = this.cancelBulkEdit.bind(this)
  // @ts-expect-error
  this.handleBulkEditSaved = this.handleBulkEditSaved.bind(this)
  // @ts-expect-error
  this.requestBulkEdit = this.requestBulkEdit.bind(this)
  // @ts-expect-error
  return IndexView.__super__.constructor.apply(this, arguments)
}

// @ts-expect-error
IndexView.mixin(AssignmentKeyBindingsMixin)

IndexView.prototype.template = template

IndexView.prototype.el = '#content'

// @ts-expect-error
IndexView.child('assignmentGroupsView', '[data-view=assignmentGroups]')

// @ts-expect-error
IndexView.child('createGroupView', '[data-view=createGroup]')

// @ts-expect-error
IndexView.child('assignmentSettingsView', '[data-view=assignmentSettings]')

// @ts-expect-error
IndexView.child('assignmentSyncSettingsView', '[data-view=assignmentSyncSettings]')

// @ts-expect-error
IndexView.child('showByView', '[data-view=showBy]')

IndexView.prototype.events = {
  'keyup #search_term': 'search',
  'change #grading_period_selector': 'filterResults',
  'focus .drag_and_drop_warning': 'show_dnd_warning',
  'blur .drag_and_drop_warning': 'hide_dnd_warning',
}

IndexView.prototype.els = {
  '#addGroup': '$addGroupButton',
  '#assignmentSettingsCog': '$assignmentSettingsButton',
  '#settingsMountPoint': '$settingsMountPoint',
  '#indexCreateMountPoint': '$indexCreateMountPoint',
  '#bulkEditRoot': '$bulkEditRoot',
}

IndexView.prototype.initialize = function () {
  // @ts-expect-error
  IndexView.__super__.initialize.apply(this, arguments)
  this.collection.once('reset', this.enableSearch, this)
  this.collection.on('cancelSearch', this.clearSearch, this)
  return (this.bulkEditMode = false)
}

IndexView.prototype.toJSON = function () {
  // @ts-expect-error
  const json = IndexView.__super__.toJSON.apply(this, arguments)
  // @ts-expect-error
  json.course_home = ENV.COURSE_HOME
  // @ts-expect-error
  json.weight_final_grades = ENV.WEIGHT_FINAL_GRADES
  json.bulkEditMode = this.bulkEditMode
  return json
}

IndexView.prototype.afterRender = function () {
  if (this.createGroupView) {
    this.createGroupView.hide()
    this.createGroupView.setTrigger(this.$addGroupButton)
  }
  if (this.assignmentSettingsView) {
    this.assignmentSettingsView.hide()
    this.assignmentSyncSettingsView.hide()
    this.indexMenuStore = configureIndexMenuStore({
      // @ts-expect-error
      weighted: ENV.WEIGHT_FINAL_GRADES,
      externalTools: [],
      modalIsOpen: false,
      selectedTool: null,
    })
    const contextInfo = ENV.context_asset_string.split('_')
    const contextType = contextInfo[0]
    const contextId = parseInt(contextInfo[1], 10)
    // @ts-expect-error
    const requestBulkEditFn = (!ENV.COURSE_HOME && this.requestBulkEdit) || void 0
    if (this.$settingsMountPoint.length) {
      const settingsRoot = createRoot(this.$settingsMountPoint[0])
      settingsRoot?.render(
        React.createElement(IndexMenu, {
          store: this.indexMenuStore,
          contextType,
          // @ts-expect-error
          contextId,
          requestBulkEdit: !ENV.IN_PACED_COURSE ? requestBulkEditFn : void 0,
          setTrigger: this.assignmentSettingsView.setTrigger.bind(this.assignmentSettingsView),
          setDisableTrigger: this.assignmentSyncSettingsView.setTrigger.bind(
            this.assignmentSyncSettingsView,
          ),
          registerWeightToggle: this.assignmentSettingsView.on.bind(this.assignmentSettingsView),
          disableSyncToSis: this.assignmentSyncSettingsView.openDisableSync.bind(
            this.assignmentSyncSettingsView,
          ),
          // @ts-expect-error
          sisName: ENV.SIS_NAME,
          // @ts-expect-error
          postToSisDefault: ENV.POST_TO_SIS_DEFAULT,
          // @ts-expect-error
          hasAssignments: ENV.HAS_ASSIGNMENTS,
          assignmentGroupsCollection: this.collection,
        }),
      )
    }
  }
  if (this.$indexCreateMountPoint.length) {
    const indexRoot = createRoot(this.$indexCreateMountPoint[0])
    indexRoot?.render(
      React.createElement(IndexCreate, {
        // @ts-expect-error
        newAssignmentUrl: ENV.URLS.new_assignment_url,
        // @ts-expect-error
        quizLtiEnabled: ENV.QUIZ_LTI_ENABLED,
        // @ts-expect-error
        manageAssignmentAddPermission: ENV.PERMISSIONS.manage_assignments_add,
      }),
    )
  }
  if (this.bulkEditMode && this.$bulkEditRoot.length) {
    const bulkEditRoot = createRoot(this.$bulkEditRoot[0])
    bulkEditRoot?.render(
      React.createElement(BulkEditIndex, {
        courseId: ENV.COURSE_ID,
        onCancel: this.cancelBulkEdit,
        onSave: this.handleBulkEditSaved,
        defaultDueTime: ENV.DEFAULT_DUE_TIME,
      }),
    )
  }
  this.filterKeyBindings()
  if (!ENV.disable_keyboard_shortcuts) {
    this.kbDialog = new KeyboardNavDialog().render(
      keyboardNavTemplate({
        keyBindings: this.keyBindings,
      }),
    )
    window.onkeydown = this.focusOnAssignments
  }

  this.$inputMountPoint = $('#search_input_container')
  if (this.$inputMountPoint?.length) {
    const inputRoot = createRoot(this.$inputMountPoint[0])
    inputRoot?.render(
      <TextInput
        onChange={e => {
          // Sends events to hidden input to utilize backbone
          const hiddenInput = $('[data-view=inputFilter]')
          // @ts-expect-error
          hiddenInput[0].value = e.target?.value
          hiddenInput.keyup()
        }}
        display="inline-block"
        type="text"
        data-testid="assignment-search-input"
        placeholder={I18n.t('Search...')}
        width="16rem"
        renderLabel={
          <ScreenReaderContent>
            {I18n.t(
              'Search assignments. As you type in this field, the list of assignments will be automatically filtered to only include those whose names match your input.',
            )}
          </ScreenReaderContent>
        }
        renderBeforeInput={() => <IconSearchLine />}
      />,
    )
  }
  return this.selectGradingPeriod()
}

IndexView.prototype.requestBulkEdit = function () {
  if (window.ENV.FEATURES?.instui_nav) {
    const bulkEditCrumb = $('<li>').text('Edit Assignment Dates')
    $('#breadcrumbs ul').append(bulkEditCrumb)
  }
  easy_student_view.hide()
  this.bulkEditMode = true
  return this.render()
}

IndexView.prototype.handleBulkEditSaved = function () {
  return (this.bulkEditSaved = true)
}

IndexView.prototype.cancelBulkEdit = function () {
  if (window.ENV.FEATURES?.instui_nav) {
    const lastCrumb = $('#breadcrumbs ul').children().last()
    lastCrumb.remove()
  }
  easy_student_view.show()
  if (this.bulkEditSaved) {
    return window.location.reload()
  } else {
    this.bulkEditMode = false
    return this.render()
  }
}

IndexView.prototype.enableSearch = function () {
  return this.$('#search_term').prop('disabled', false)
}

IndexView.prototype.clearSearch = function () {
  this.$('#search_term').val('')
  return this.filterResults()
}

IndexView.prototype.search = debounce(function () {
  // @ts-expect-error
  return this.filterResults()
}, 200)

IndexView.prototype.gradingPeriods = GradingPeriodsAPI.deserializePeriods(
  ENV.active_grading_periods,
)

// @ts-expect-error
IndexView.prototype.show_dnd_warning = function (event) {
  return this.$(event.currentTarget).removeClass('screenreader-only')
}

// @ts-expect-error
IndexView.prototype.hide_dnd_warning = function (event) {
  return this.$(event.currentTarget).addClass('screenreader-only')
}

IndexView.prototype.clearNoAssignments = function () {
  if (this.noAssignmentsRoot) {
    this.noAssignmentsRoot.unmount()
    this.noAssignmentsRoot = null
  }
  $(this.noAssignments).remove()
  return (this.noAssignments = null)
}

IndexView.prototype.filterResults = function () {
  // @ts-expect-error
  let atleastoneGroup, gradingPeriod, gradingPeriodIndex, matchingAssignmentCount, regex, ul
  const term = $('#search_term').val()
  gradingPeriod = null
  if (ENV.HAS_GRADING_PERIODS) {
    gradingPeriodIndex = $('#grading_period_selector').val()
    if (gradingPeriodIndex !== 'all') {
      // @ts-expect-error
      gradingPeriod = this.gradingPeriods[parseInt(gradingPeriodIndex, 10)]
    }
    this.saveSelectedGradingPeriod(gradingPeriod)
  }
  if (term === '' && gradingPeriod === null) {
    this.collection.each(
      (function (_this) {
        // @ts-expect-error
        return function (group) {
          return group.groupView.endSearch()
        }
      })(this),
    )
    if (this.noAssignments != null) {
      return this.clearNoAssignments()
    }
  } else {
    regex = new RegExp(this.cleanSearchTerm(term), 'ig')
    // @ts-expect-error
    matchingAssignmentCount = this.collection.reduce(function (runningTotal, group) {
      // @ts-expect-error
      const additionalCount = group.groupView.search(regex, gradingPeriod)
      return runningTotal + additionalCount
    }, 0)
    atleastoneGroup = matchingAssignmentCount > 0
    this.alertForMatchingGroups(matchingAssignmentCount)
    if (!atleastoneGroup) {
      if (!this.noAssignments) {
        const li = document.createElement('li')
        li.className = 'item-group-condensed'
        this.noAssignmentsRoot = createRoot(li)
        this.noAssignmentsRoot.render(<NoAssignmentsSearch />)
        this.noAssignments = li
        ul = this.assignmentGroupsView.$el.children('.collectionViewItems')
        return ul.append(this.noAssignments)
      }
    } else if (this.noAssignments != null) {
      return this.clearNoAssignments()
    }
  }
}

// @ts-expect-error
IndexView.prototype.alertForMatchingGroups = function (numAssignments) {
  const msg = I18n.t(
    {
      one: '1 assignment found.',
      other: '%{count} assignments found.',
      zero: 'No matching assignments found.',
    },
    {
      count: numAssignments,
    },
  )
  return $.screenReaderFlashMessageExclusive(msg)
}

// @ts-expect-error
IndexView.prototype.cleanSearchTerm = function (text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')
}

// @ts-expect-error
IndexView.prototype.focusOnAssignments = function (e) {
  if (e.keyCode === 74) {
    if (!$(e.target).is(':input')) {
      return $('.assignment_group').filter(':visible').first().attr('tabindex', -1).focus()
    }
  }
}

IndexView.prototype.filterKeyBindings = function () {
  // @ts-expect-error
  const canManage = ENV.PERMISSIONS.manage
  // @ts-expect-error
  const canAdd = ENV.PERMISSIONS.manage_assignments_add
  // @ts-expect-error
  const canDelete = ENV.PERMISSIONS.manage_assignments_delete
  // @ts-expect-error
  return (this.keyBindings = this.keyBindings.filter(function (binding) {
    if (!canManage && binding.keyCode === 69) {
      return false
    } else if (!canAdd && binding.keyCode === 65) {
      return false
    } else if (!canDelete && binding.keyCode === 68) {
      return false
    } else {
      return true
    }
  }))
}

IndexView.prototype.selectGradingPeriod = function () {
  let i, results
  const gradingPeriodId = userSettings.contextGet('assignments_current_grading_period')
  if (gradingPeriodId !== null) {
    results = []
    for (i in this.gradingPeriods) {
      if (this.gradingPeriods[i].id === gradingPeriodId) {
        $('#grading_period_selector').val(i)
        break
      } else {
        results.push(void 0)
      }
    }
    return results
  }
}

// @ts-expect-error
IndexView.prototype.saveSelectedGradingPeriod = function (gradingPeriod) {
  return userSettings.contextSet(
    'assignments_current_grading_period',
    gradingPeriod && gradingPeriod.id,
  )
}

export default IndexView
