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

import React from 'react'
import ReactDOM from 'react-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, flatten, filter, difference} from 'lodash'
import Backbone from '@canvas/backbone'
import Cache from '../../cache'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('assignmentsToggleShowByView')

export default class ToggleShowByView extends Backbone.View {
  initialize(...args) {
    super.initialize(...args)
    this.menuOpened = false
    this.initialized = $.Deferred()
    this.course.on('change', () => this.initializeCache())
    this.course.on('change', this.render, this)
    this.assignmentGroups.once('change:submissions', () => this.initializeDateGroups())
    this.on('changed:showBy', () => this.setAssignmentGroups())
    this.on('changed:showBy', this.render, this)
    this.on('changed:toggleMenu', this.render, this)
  }

  initializeCache() {
    if (this.course.get('id') == null) return
    $.extend(true, this, Cache)
    if (ENV.current_user_id != null) this.cache.use('localStorage')
    if (this.cache.get(this.cacheKey()) == null) this.cache.set(this.cacheKey(), true)
    return this.initialized.resolve()
  }

  initializeDateGroups() {
    const assignments = flatten(this.assignmentGroups.map(ag => ag.get('assignments').models))
    const dated = filter(assignments, a => a.dueAt())
    const undated = difference(assignments, dated)
    const past = []
    const overdue = []
    const upcoming = []
    each(dated, a => {
      if (new Date() < Date.parse(a.dueAt())) return upcoming.push(a)

      const isOverdue = a.allowedToSubmit() && a.withoutGradedSubmission()
      // only handles observer observing one student, this needs to change to handle multiple users in the future
      const canHaveOverdueAssignment =
        !ENV.current_user_has_been_observer_in_this_course ||
        (ENV.observed_student_ids && ENV.observed_student_ids.length) === 1

      if (isOverdue && canHaveOverdueAssignment) return overdue.push(a)
      past.push(a)
    })

    const overdue_group = new AssignmentGroup({
      id: 'overdue',
      name: I18n.t('overdue_assignments', 'Overdue Assignments'),
      assignments: overdue,
    })
    const upcoming_group = new AssignmentGroup({
      id: 'upcoming',
      name: I18n.t('upcoming_assignments', 'Upcoming Assignments'),
      assignments: upcoming,
    })
    const undated_group = new AssignmentGroup({
      id: 'undated',
      name: I18n.t('undated_assignments', 'Undated Assignments'),
      assignments: undated,
    })
    const past_group = new AssignmentGroup({
      id: 'past',
      name: I18n.t('past_assignments', 'Past Assignments'),
      assignments: past,
    })

    const sorted_groups = this._sortGroups(overdue_group, upcoming_group, undated_group, past_group)

    this.groupedByAG = this.assignmentGroups.models
    this.groupedByDate = sorted_groups

    return this.setAssignmentGroups()
  }

  _sortGroups(overdue, upcoming, undated, past) {
    this._sortAscending(overdue.get('assignments'))
    this._sortAscending(upcoming.get('assignments'))
    this._sortDescending(past.get('assignments'))
    return [overdue, upcoming, undated, past]
  }

  _sortAscending(assignments) {
    assignments.comparator = a => Date.parse(a.dueAt())
    return assignments.sort()
  }

  _sortDescending(assignments) {
    assignments.comparator = a => new Date() - Date.parse(a.dueAt())
    return assignments.sort()
  }

  afterRender() {
    return $.when(this.initialized).then(() => this.renderToggle())
  }

  showByMenuTrigger() {
    return (
      <Button>
        {I18n.t('Show By')}
        <View margin="0 0 0 small">
          {this.menuOpened ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
        </View>
      </Button>
    )
  }

  toggleMenu() {
    this.menuOpened = !this.menuOpened
    this.trigger('changed:toggleMenu')
  }

  renderToggle() {
    ReactDOM.render(
      ENV.FEATURES.instui_nav ? (
        <Menu trigger={this.showByMenuTrigger()} onToggle={() => this.toggleMenu()}>
          <Menu.Group label="" selected={[this.showByDate() ? 'date' : 'type']}>
            <Menu.Item
              data-testid="show_by_date"
              onSelect={(e, val) => this.toggleShowBy(val)}
              value="date"
            >
              {I18n.t('Date')}
            </Menu.Item>
            <Menu.Item
              data-testid="show_by_type"
              onSelect={(e, val) => this.toggleShowBy(val)}
              value="type"
            >
              {I18n.t('Type')}
            </Menu.Item>
          </Menu.Group>
        </Menu>
      ) : (
        <RadioInputGroup
          description={<ScreenReaderContent>{I18n.t('Show By')}</ScreenReaderContent>}
          size="medium"
          name="show_by"
          variant="toggle"
          defaultValue={this.showByDate() ? 'date' : 'type'}
          onChange={(e, val) => this.toggleShowBy(val)}
        >
          <RadioInput id="show_by_date" label={I18n.t('Show by Date')} value="date" context="off" />
          <RadioInput id="show_by_type" label={I18n.t('Show by Type')} value="type" context="off" />
        </RadioInputGroup>
      ),
      this.el
    )
  }

  setAssignmentGroups() {
    let groups = this.showByDate() ? this.groupedByDate : this.groupedByAG
    this.setAssignmentGroupAssociations(groups)
    groups = filter(groups, group => {
      const hasWeight =
        this.course.get('apply_assignment_group_weights') && group.get('group_weight') > 0
      return group.get('assignments').length > 0 || hasWeight
    })
    return this.assignmentGroups.reset(groups)
  }

  setAssignmentGroupAssociations(groups) {
    ;(groups || []).forEach(assignment_group => {
      ;(assignment_group.get('assignments').models || []).forEach(assignment => {
        // we are keeping this change on the frontend only (for keyboard nav), will not persist in the db
        assignment.collection = assignment_group
        assignment.set('assignment_group_id', assignment_group.id)
      })
    })
  }

  showByDate() {
    if (!this.cache) return true
    return this.cache.get(this.cacheKey())
  }

  cacheKey() {
    return [
      'course',
      this.course.get('id'),
      'user',
      ENV.current_user_id,
      'assignments_show_by_date',
    ]
  }

  toggleShowBy(value) {
    const key = this.cacheKey()
    const showByDate = value === 'date'
    const currentlyByDate = this.cache.get(key)
    if (currentlyByDate !== showByDate) {
      this.cache.set(key, showByDate)
      this.trigger('changed:showBy')
    }

    return this.assignmentGroups.trigger('cancelSearch')
  }
}
ToggleShowByView.optionProperty('course')
ToggleShowByView.optionProperty('assignmentGroups')
