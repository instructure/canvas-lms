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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {difference, flatten, each, filter} from 'es-toolkit/compat'
import Backbone from '@canvas/backbone'
import Cache from '../../cache'
import AssignmentGroup from '@canvas/assignments/backbone/models/AssignmentGroup'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('assignmentsToggleShowByView')

export default class ToggleShowByView extends Backbone.View {
  // @ts-expect-error
  initialize(...args) {
    super.initialize(...args)
    // @ts-expect-error
    this.menuOpened = false
    // @ts-expect-error
    this.initialized = $.Deferred()
    // @ts-expect-error
    this.course.on('change', () => this.initializeCache())
    // @ts-expect-error
    this.course.on('change', this.render, this)
    // @ts-expect-error
    this.assignmentGroups.once('change:submissions', () => this.initializeDateGroups())
    // @ts-expect-error
    this.on('changed:showBy', () => this.setAssignmentGroups())
    // @ts-expect-error
    this.on('changed:showBy', this.render, this)
    // @ts-expect-error
    this.on('changed:toggleMenu', this.render, this)
  }

  initializeCache() {
    // @ts-expect-error
    if (this.course.get('id') == null) return
    $.extend(true, this, Cache)
    // @ts-expect-error
    if (ENV.current_user_id != null) this.cache.use('localStorage')
    // @ts-expect-error
    if (this.cache.get(this.cacheKey()) == null) this.cache.set(this.cacheKey(), true)
    // @ts-expect-error
    return this.initialized.resolve()
  }

  initializeDateGroups() {
    // @ts-expect-error
    const assignments = flatten(this.assignmentGroups.map(ag => ag.get('assignments').models))
    // @ts-expect-error
    const undated = []
    // @ts-expect-error
    const past = []
    // @ts-expect-error
    const overdue = []
    // @ts-expect-error
    const upcoming = []

    each(assignments, a => {
      let group
      // @ts-expect-error
      if (a.hasSubAssignments()) {
        // @ts-expect-error
        group = a.getCheckpointDateGroup()
      } else {
        // @ts-expect-error
        group = a.getDateSortGroup()
      }
      switch (group) {
        case 'undated':
          undated.push(a)
          break
        case 'upcoming':
          upcoming.push(a)
          break
        case 'overdue':
          overdue.push(a)
          break
        case 'past':
          past.push(a)
          break
      }
    })
    const overdue_group = new AssignmentGroup({
      id: 'overdue',
      name: I18n.t('overdue_assignments', 'Overdue Assignments'),
      // @ts-expect-error
      assignments: overdue,
    })
    const upcoming_group = new AssignmentGroup({
      id: 'upcoming',
      name: I18n.t('upcoming_assignments', 'Upcoming Assignments'),
      // @ts-expect-error
      assignments: upcoming,
    })
    const undated_group = new AssignmentGroup({
      id: 'undated',
      name: I18n.t('undated_assignments', 'Undated Assignments'),
      // @ts-expect-error
      assignments: undated,
    })
    const past_group = new AssignmentGroup({
      id: 'past',
      name: I18n.t('past_assignments', 'Past Assignments'),
      // @ts-expect-error
      assignments: past,
    })

    const sorted_groups = this._sortGroups(overdue_group, upcoming_group, undated_group, past_group)

    // @ts-expect-error
    this.groupedByAG = this.assignmentGroups.models
    // @ts-expect-error
    this.groupedByDate = sorted_groups

    return this.setAssignmentGroups()
  }

  // @ts-expect-error
  _sortGroups(overdue, upcoming, undated, past) {
    this._sortAscending(overdue.get('assignments'))
    this._sortAscending(upcoming.get('assignments'))
    this._sortDescending(past.get('assignments'))
    return [overdue, upcoming, undated, past]
  }

  // @ts-expect-error
  _sortAscending(assignments) {
    // @ts-expect-error
    assignments.comparator = a => Date.parse(a.sortingDueAt())
    return assignments.sort()
  }

  // @ts-expect-error
  _sortDescending(assignments) {
    // @ts-expect-error
    assignments.comparator = a => new Date() - Date.parse(a.sortingDueAt())
    return assignments.sort()
  }

  afterRender() {
    // @ts-expect-error
    return $.when(this.initialized).then(() => this.renderToggle())
  }

  showByMenuTrigger() {
    return (
      <Button>
        {I18n.t('Show By')}
        <View margin="0 0 0 small">
          {/* @ts-expect-error */}
          {this.menuOpened ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
        </View>
      </Button>
    )
  }

  toggleMenu() {
    // @ts-expect-error
    this.menuOpened = !this.menuOpened
    // @ts-expect-error
    this.trigger('changed:toggleMenu')
  }

  renderToggle() {
    ReactDOM.render(
      ENV.FEATURES?.instui_nav ? (
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
      // @ts-expect-error
      this.el,
    )
  }

  setAssignmentGroups() {
    // @ts-expect-error
    let groups = this.showByDate() ? this.groupedByDate : this.groupedByAG
    this.setAssignmentGroupAssociations(groups)
    groups = filter(groups, group => {
      const hasWeight =
        // @ts-expect-error
        this.course.get('apply_assignment_group_weights') && group.get('group_weight') > 0
      return group.get('assignments').length > 0 || hasWeight
    })
    // @ts-expect-error
    return this.assignmentGroups.reset(groups)
  }

  // @ts-expect-error
  setAssignmentGroupAssociations(groups) {
    // @ts-expect-error
    ;(groups || []).forEach(assignment_group => {
      // @ts-expect-error
      ;(assignment_group.get('assignments').models || []).forEach(assignment => {
        // we are keeping this change on the frontend only (for keyboard nav), will not persist in the db
        assignment.collection = assignment_group
        assignment.set('assignment_group_id', assignment_group.id)
      })
    })
  }

  showByDate() {
    // @ts-expect-error
    if (!this.cache) return true
    // @ts-expect-error
    return this.cache.get(this.cacheKey())
  }

  cacheKey() {
    return [
      'course',
      // @ts-expect-error
      this.course.get('id'),
      'user',
      ENV.current_user_id,
      'assignments_show_by_date',
    ]
  }

  // @ts-expect-error
  toggleShowBy(value) {
    const key = this.cacheKey()
    const showByDate = value === 'date'
    // @ts-expect-error
    const currentlyByDate = this.cache.get(key)
    if (currentlyByDate !== showByDate) {
      // @ts-expect-error
      this.cache.set(key, showByDate)
      // @ts-expect-error
      this.trigger('changed:showBy')
    }

    // @ts-expect-error
    return this.assignmentGroups.trigger('cancelSearch')
  }
}
// @ts-expect-error
ToggleShowByView.optionProperty('course')
// @ts-expect-error
ToggleShowByView.optionProperty('assignmentGroups')
