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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {debounce} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
import keyboardNavTemplate from '@canvas/keyboard-nav-dialog/jst/KeyboardNavDialog.handlebars'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import template from '../../jst/IndexView.handlebars'
import NoAssignments from '../../jst/NoAssignmentsSearch.handlebars'
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

const I18n = useI18nScope('assignmentsIndexView')

extend(IndexView, Backbone.View)

function IndexView() {
  this.filterKeyBindings = this.filterKeyBindings.bind(this)
  this.focusOnAssignments = this.focusOnAssignments.bind(this)
  this.filterResults = this.filterResults.bind(this)
  this.hide_dnd_warning = this.hide_dnd_warning.bind(this)
  this.show_dnd_warning = this.show_dnd_warning.bind(this)
  this.cancelBulkEdit = this.cancelBulkEdit.bind(this)
  this.handleBulkEditSaved = this.handleBulkEditSaved.bind(this)
  this.requestBulkEdit = this.requestBulkEdit.bind(this)
  return IndexView.__super__.constructor.apply(this, arguments)
}

IndexView.mixin(AssignmentKeyBindingsMixin)

IndexView.prototype.template = template

IndexView.prototype.el = '#content'

IndexView.child('assignmentGroupsView', '[data-view=assignmentGroups]')

IndexView.child('createGroupView', '[data-view=createGroup]')

IndexView.child('assignmentSettingsView', '[data-view=assignmentSettings]')

IndexView.child('assignmentSyncSettingsView', '[data-view=assignmentSyncSettings]')

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
  IndexView.__super__.initialize.apply(this, arguments)
  this.collection.once('reset', this.enableSearch, this)
  this.collection.on('cancelSearch', this.clearSearch, this)
  return (this.bulkEditMode = false)
}

IndexView.prototype.toJSON = function () {
  const json = IndexView.__super__.toJSON.apply(this, arguments)
  json.course_home = ENV.COURSE_HOME
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
      weighted: ENV.WEIGHT_FINAL_GRADES,
      externalTools: [],
      modalIsOpen: false,
      selectedTool: null,
    })
    const contextInfo = ENV.context_asset_string.split('_')
    const contextType = contextInfo[0]
    const contextId = parseInt(contextInfo[1], 10)
    const requestBulkEditFn = (!ENV.COURSE_HOME && this.requestBulkEdit) || void 0
    if (this.$settingsMountPoint.length) {
      ReactDOM.render(
        React.createElement(IndexMenu, {
          store: this.indexMenuStore,
          contextType,
          contextId,
          requestBulkEdit: !ENV.IN_PACED_COURSE ? requestBulkEditFn : void 0,
          setTrigger: this.assignmentSettingsView.setTrigger.bind(this.assignmentSettingsView),
          setDisableTrigger: this.assignmentSyncSettingsView.setTrigger.bind(
            this.assignmentSyncSettingsView
          ),
          registerWeightToggle: this.assignmentSettingsView.on.bind(this.assignmentSettingsView),
          disableSyncToSis: this.assignmentSyncSettingsView.openDisableSync.bind(
            this.assignmentSyncSettingsView
          ),
          sisName: ENV.SIS_NAME,
          postToSisDefault: ENV.POST_TO_SIS_DEFAULT,
          hasAssignments: ENV.HAS_ASSIGNMENTS,
          assignmentGroupsCollection: this.collection,
        }),
        this.$settingsMountPoint[0]
      )
    }
  }
  if (this.$indexCreateMountPoint.length) {
    ReactDOM.render(
      React.createElement(IndexCreate, {
        newAssignmentUrl: ENV.URLS.new_assignment_url,
        quizLtiEnabled: ENV.QUIZ_LTI_ENABLED,
        manageAssignmentAddPermission: ENV.PERMISSIONS.manage_assignments_add,
      }),
      this.$indexCreateMountPoint[0]
    )
  }
  if (this.bulkEditMode && this.$bulkEditRoot.length) {
    ReactDOM.render(
      React.createElement(BulkEditIndex, {
        courseId: ENV.COURSE_ID,
        onCancel: this.cancelBulkEdit,
        onSave: this.handleBulkEditSaved,
        defaultDueTime: ENV.DEFAULT_DUE_TIME,
      }),
      this.$bulkEditRoot[0]
    )
  }
  this.filterKeyBindings()
  if (!ENV.disable_keyboard_shortcuts) {
    this.kbDialog = new KeyboardNavDialog().render(
      keyboardNavTemplate({
        keyBindings: this.keyBindings,
      })
    )
    window.onkeydown = this.focusOnAssignments
  }
  ReactDOM.render(
    <TextInput
      onChange={e => {
        // Sends events to hidden input to utilize backbone
        const hiddenInput = $('[data-view=inputFilter]')
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
            'Search assignments. As you type in this field, the list of assignments will be automatically filtered to only include those whose names match your input.'
          )}
        </ScreenReaderContent>
      }
      renderBeforeInput={() => <IconSearchLine />}
    />,
    this.$el.find('#search_input_container')[0]
  )
  return this.selectGradingPeriod()
}

IndexView.prototype.requestBulkEdit = function () {
  if (window.ENV.FEATURES.instui_nav) {
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
  if (window.ENV.FEATURES.instui_nav) {
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
  return this.filterResults()
}, 200)

IndexView.prototype.gradingPeriods = GradingPeriodsAPI.deserializePeriods(
  ENV.active_grading_periods
)

IndexView.prototype.show_dnd_warning = function (event) {
  return this.$(event.currentTarget).removeClass('screenreader-only')
}

IndexView.prototype.hide_dnd_warning = function (event) {
  return this.$(event.currentTarget).addClass('screenreader-only')
}

IndexView.prototype.filterResults = function () {
  let atleastoneGroup, gradingPeriod, gradingPeriodIndex, matchingAssignmentCount, regex, ul
  const term = $('#search_term').val()
  gradingPeriod = null
  if (ENV.HAS_GRADING_PERIODS) {
    gradingPeriodIndex = $('#grading_period_selector').val()
    if (gradingPeriodIndex !== 'all') {
      gradingPeriod = this.gradingPeriods[parseInt(gradingPeriodIndex, 10)]
    }
    this.saveSelectedGradingPeriod(gradingPeriod)
  }
  if (term === '' && gradingPeriod === null) {
    this.collection.each(
      (function (_this) {
        return function (group) {
          return group.groupView.endSearch()
        }
      })(this)
    )
    if (this.noAssignments != null) {
      this.noAssignments.remove()
      return (this.noAssignments = null)
    }
  } else {
    regex = new RegExp(this.cleanSearchTerm(term), 'ig')
    matchingAssignmentCount = this.collection.reduce(function (runningTotal, group) {
      const additionalCount = group.groupView.search(regex, gradingPeriod)
      return runningTotal + additionalCount
    }, 0)
    atleastoneGroup = matchingAssignmentCount > 0
    this.alertForMatchingGroups(matchingAssignmentCount)
    if (!atleastoneGroup) {
      if (!this.noAssignments) {
        this.noAssignments = new Backbone.View({
          template: NoAssignments,
          tagName: 'li',
          className: 'item-group-condensed',
        })
        ul = this.assignmentGroupsView.$el.children('.collectionViewItems')
        return ul.append(this.noAssignments.render().el)
      }
    } else if (this.noAssignments != null) {
      this.noAssignments.remove()
      return (this.noAssignments = null)
    }
  }
}

IndexView.prototype.alertForMatchingGroups = function (numAssignments) {
  const msg = I18n.t(
    {
      one: '1 assignment found.',
      other: '%{count} assignments found.',
      zero: 'No matching assignments found.',
    },
    {
      count: numAssignments,
    }
  )
  return $.screenReaderFlashMessageExclusive(msg)
}

IndexView.prototype.cleanSearchTerm = function (text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')
}

IndexView.prototype.focusOnAssignments = function (e) {
  if (e.keyCode === 74) {
    if (!$(e.target).is(':input')) {
      return $('.assignment_group').filter(':visible').first().attr('tabindex', -1).focus()
    }
  }
}

IndexView.prototype.filterKeyBindings = function () {
  const canManage = ENV.PERMISSIONS.manage
  const canAdd = ENV.PERMISSIONS.manage_assignments_add
  const canDelete = ENV.PERMISSIONS.manage_assignments_delete
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

IndexView.prototype.saveSelectedGradingPeriod = function (gradingPeriod) {
  return userSettings.contextSet(
    'assignments_current_grading_period',
    gradingPeriod && gradingPeriod.id
  )
}

export default IndexView
