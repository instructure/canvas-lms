//
// Copyright (C) 2012 - present Instructure, Inc.
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
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import splitAssetString from '../str/splitAssetString'
import Depaginate from 'jsx/shared/CheatDepaginator'
import I18n from 'i18n!calendar.edit'

export default class CalendarEvent extends Backbone.Model {
  urlRoot = '/api/v1/calendar_events/'

  dateAttributes = ['created_at', 'end_at', 'start_at', 'updated_at']

  _filterAttributes(obj) {
    const filtered = _(obj).pick(
      'start_at',
      'end_at',
      'title',
      'description',
      'context_code',
      'remove_child_events',
      'location_name',
      'location_address',
      'duplicate',
      'comments'
    )
    if (obj.use_section_dates && obj.child_event_data) {
      filtered.child_event_data = _.chain(obj.child_event_data)
        .compact()
        .filter(this._hasValidInputs)
        .map(this._filterAttributes)
        .value()
    }
    return filtered
  }

  _hasValidInputs(o) {
    // has a start_at or has a date and either has both a start and end time or neither
    return !!o.start_at || (o.start_date && !!o.start_time === !!o.end_time)
  }

  toJSON() {
    return {calendar_event: this._filterAttributes(super.toJSON(...arguments))}
  }

  present() {
    const result = Backbone.Model.prototype.toJSON.call(this)
    result.newRecord = !result.id
    return result
  }

  fetch(otps={}) {
    let sectionsDfd, syncDfd

    this.showSpinner()

    const {success, error, ...options} = otps

    if (this.get('id')) {
      syncDfd = (this.sync || Backbone.sync).call(this, 'read', this, options)
    }

    if (this.get('sections_url')) {
      sectionsDfd = Depaginate(this.get('sections_url'))
    }

    const combinedSuccess = (syncArgs=[], sectionsResp=[]) => {
      this.hideSpinner()

      const [syncResp, syncStatus, syncXhr] = syncArgs
      const calEventData = CalendarEvent.mergeSectionsIntoCalendarEvent(syncResp, sectionsResp)
      if (!this.set(this.parse(calEventData), options)) return false
      if (success) return success(this, calEventData)
    }

    return $.when(syncDfd, sectionsDfd)
      .then(combinedSuccess)
      .fail(() => this.loadFailure(error))
  }

  showSpinner() {
    ReactDOM.render(
      <div>
        <Spinner title={I18n.t('Loading')} size="medium" />
      </div>
    ,
      this.view.el
    )
  }

  hideSpinner() {
    return ReactDOM.unmountComponentAtNode(this.view.el)
  }

  loadFailure(errHandler) {
    this.hideSpinner()
    if (!this.view.el.querySelector('.error-msg')) {
      const msg = document.createElement('div')
      msg.setAttribute('class', 'error-msg')
      msg.innerHTML = I18n.t('Failed loading course sections. Refresh page to try again.')
      this.view.el.appendChild(msg)
    }

    if (errHandler) return errHandler()
  }

  static mergeSectionsIntoCalendarEvent(eventData={}, sections) {
    eventData.recurring_calendar_events = ENV.RECURRING_CALENDAR_EVENTS_ENABLED
    eventData.course_sections = sections
    eventData.use_section_dates = !!(eventData.child_events && eventData.child_events.length)
    _(eventData.child_events).each((child, index) => {
      // 'parse' turns string dates into Date objects
      child = eventData.child_events[index] = CalendarEvent.prototype.parse(child)
      const sectionId = splitAssetString(child.context_code)[1]
      const section = _(sections).find(section => section.id === sectionId)
      section.event = child
    })
    return eventData
  }
}
