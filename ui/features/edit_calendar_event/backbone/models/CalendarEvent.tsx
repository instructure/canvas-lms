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
import {Spinner} from '@instructure/ui-spinner'
import $ from 'jquery'
import {pick, each, find, compact, filter, map} from 'es-toolkit/compat'
import Backbone from '@canvas/backbone'

import {useScope as createI18nScope} from '@canvas/i18n'

import NaiveRequestDispatch from '@canvas/network/NaiveRequestDispatch/index'
import splitAssetString from '@canvas/util/splitAssetString'

const I18n = createI18nScope('calendar.edit')

const LOADING_STATE = {
  PRE_SPINNER: 0,
  SPINNER_UP: 1,
  LOADED: 2,
}

export default class CalendarEvent extends Backbone.Model {
  // @ts-expect-error TS7006 (typescriptify)
  constructor(event) {
    super(event)
    // @ts-expect-error TS2339 (typescriptify)
    this.loadingState = LOADING_STATE.PRE_SPINNER
  }

  urlRoot = '/api/v1/calendar_events/'

  dateAttributes = ['created_at', 'end_at', 'start_at', 'updated_at']

  // @ts-expect-error TS7006 (typescriptify)
  _filterAttributes(obj) {
    const filtered = pick(obj, [
      'start_at',
      'end_at',
      'title',
      'description',
      'context_code',
      'remove_child_events',
      'location_name',
      'location_address',
      'duplicate',
      'comments',
      'web_conference',
      'important_dates',
      'blackout_date',
      'rrule',
    ])

    if (obj.use_section_dates && obj.child_event_data) {
      const compacted = compact(obj.child_event_data)
      const filtered_data = filter(compacted, this._hasValidInputs)
      // @ts-expect-error TS2339 (typescriptify)
      filtered.child_event_data = map(filtered_data, this._filterAttributes)
    }
    return filtered
  }

  // @ts-expect-error TS7006 (typescriptify)
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

  url() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.isNew()) return this.urlRoot
    // @ts-expect-error TS2339 (typescriptify)
    let retval = this.urlRoot + encodeURIComponent(this.id)
    // @ts-expect-error TS2339 (typescriptify)
    if (this.get('which')) {
      // @ts-expect-error TS2339 (typescriptify)
      retval += `?which=${this.get('which')}`
    }
    return retval
  }

  fetch(opts = {}) {
    let sectionsDfd, syncDfd

    this.showSpinner()

    // @ts-expect-error TS2339 (typescriptify)
    const {success, error, ...options} = opts

    // @ts-expect-error TS2339 (typescriptify)
    options.url = this.url() + '?include[]=web_conference&include[]=series_head'

    // @ts-expect-error TS2339 (typescriptify)
    if (this.get('id')) {
      // @ts-expect-error TS2339 (typescriptify)
      syncDfd = (this.sync || Backbone.sync).call(this, 'read', this, options)
    }

    // @ts-expect-error TS2339 (typescriptify)
    let sectionsUrl = this.get('sections_url')
    if (sectionsUrl) {
      sectionsUrl += '?include[]=permissions'
      const dispatch = new NaiveRequestDispatch()
      sectionsDfd = dispatch.getDepaginated(sectionsUrl)
    }

    const combinedSuccess = (syncArgs = [], sectionsResp = []) => {
      this.hideSpinner()

      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const [syncResp, syncStatus, syncXhr] = syncArgs
      const calEventData = CalendarEvent.mergeSectionsIntoCalendarEvent(syncResp, sectionsResp)
      // @ts-expect-error TS2339 (typescriptify)
      if (!this.set(this.parse(calEventData), options)) return false
      if (success) return success(this, calEventData)
    }

    return $.when(syncDfd, sectionsDfd)
      .then(combinedSuccess)
      .fail(() => this.loadFailure(error))
  }

  showSpinner() {
    function waitForView() {
      // @ts-expect-error TS2683 (typescriptify)
      if (this.view?.el) {
        // @ts-expect-error TS2683 (typescriptify)
        if (this.loadingState === LOADING_STATE.LOADED) return
        // @ts-expect-error TS2683 (typescriptify)
        this.loadingState = LOADING_STATE.SPINNER_UP

        ReactDOM.render(
          <div>
            <Spinner renderTitle={I18n.t('Loading')} size="medium" />
          </div>,
          // @ts-expect-error TS2683 (typescriptify)
          this.view.el,
        )
        return
      }
      // @ts-expect-error TS2683 (typescriptify)
      requestAnimationFrame(waitForView.bind(this))
    }

    waitForView.bind(this)()
  }

  hideSpinner() {
    // @ts-expect-error TS2339 (typescriptify)
    const curState = this.loadingState
    // @ts-expect-error TS2339 (typescriptify)
    this.loadingState = LOADING_STATE.LOADED

    // @ts-expect-error TS2339 (typescriptify)
    if (curState === LOADING_STATE.SPINNER_UP) ReactDOM.unmountComponentAtNode(this.view.el)
  }

  // @ts-expect-error TS7006 (typescriptify)
  loadFailure(errHandler) {
    this.hideSpinner()
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.view.el.querySelector('.error-msg')) {
      const msg = document.createElement('div')
      msg.setAttribute('class', 'error-msg')
      msg.innerHTML = I18n.t('Failed loading course sections. Refresh page to try again.')
      // @ts-expect-error TS2339 (typescriptify)
      this.view.el.appendChild(msg)
    }

    if (errHandler) return errHandler()
  }

  // @ts-expect-error TS7006 (typescriptify)
  static mergeSectionsIntoCalendarEvent(eventData = {}, sections) {
    // @ts-expect-error TS2339 (typescriptify)
    eventData.course_sections = sections
    // @ts-expect-error TS2339 (typescriptify)
    eventData.use_section_dates = !!(eventData.child_events && eventData.child_events.length)
    // @ts-expect-error TS2339 (typescriptify)
    each(eventData.child_events, (child, index) => {
      // 'parse' turns string dates into Date objects
      // @ts-expect-error TS2339 (typescriptify)
      child = eventData.child_events[index] = CalendarEvent.prototype.parse(child)
      // @ts-expect-error TS2532 (typescriptify)
      const sectionId = splitAssetString(child.context_code)[1]
      const section = find(sections, section => section.id === sectionId)
      section.event = child
    })
    return eventData
  }
}
