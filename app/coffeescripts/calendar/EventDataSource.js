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
import _ from 'lodash'
import fcUtil from '../util/fcUtil'
import commonEventFactory from '../calendar/commonEventFactory'
import 'jquery.ajaxJSON'
import 'vendor/jquery.ba-tinypubsub'

export default class EventDataSource {
  constructor(contexts) {
    this.eventSaved = this.eventSaved.bind(this)
    this.eventDeleted = this.eventDeleted.bind(this)
    this.eventWithId = this.eventWithId.bind(this)
    this.clearCache = this.clearCache.bind(this)
    this.needUndatedEventsForContexts = this.needUndatedEventsForContexts.bind(this)
    this.getEventsFromCacheForContext = this.getEventsFromCacheForContext.bind(this)
    this.processNextRequest = this.processNextRequest.bind(this)
    this.getEventsFromCache = this.getEventsFromCache.bind(this)
    this.getAppointmentGroupsFromCache = this.getAppointmentGroupsFromCache.bind(this)
    this.getAppointmentGroups = this.getAppointmentGroups.bind(this)
    this.processAppointmentData = this.processAppointmentData.bind(this)
    this.getEventsForAppointmentGroup = this.getEventsForAppointmentGroup.bind(this)
    this.getEvents = this.getEvents.bind(this)
    this.getParticipants = this.getParticipants.bind(this)
    this.startFetch = this.startFetch.bind(this)
    this.fetchNextBatch = this.fetchNextBatch.bind(this)

    this.contexts = contexts
    this.clearCache()
    this.inFlightRequest = {}
    this.pendingRequests = []
    // The cache will store all the events we've fetched so far, and looks like this:
    // {
    //   contexts: {
    //     "user_1": {
    //       fetchedRanges: [
    //         sorted list of [start, end] tuples that represent
    //         ranges of dates that we have already fetched for
    //       ]
    //       events: {
    //         "assignment_1": <CommonEvent object>
    //       },
    //       fetchedUndated: true/false
    //     }, ...
    //   },
    //   appointmentGroups: {
    //     "1": <object>
    //   },
    //   participants: {
    //     "1_unregistered": [ users or groups ]
    //   }
    //   fetchedAppointmentGroups: { manageable: true/false }
    // }

    // Note that the appointmentGroups are not cached per context, as
    // we get them all in the same request (not scoped to contexts at
    // all.) This might end up being confusing.
    $.subscribe('CommonEvent/eventDeleted', this.eventDeleted)
    $.subscribe('CommonEvent/eventSaved', this.eventSaved)
  }

  eventSaved(event) {
    return this.addEventToCache(event)
  }

  eventDeleted(event) {
    const cached = this.cache.contexts[event.contextCode()]
    const events = cached && cached.events
    if (events) delete events[event.id]
  }

  eventWithId(id) {
    for (const contextCode in this.cache.contexts) {
      const contextData = this.cache.contexts[contextCode]
      if (contextData.events[id]) {
        return contextData.events[id]
      }
    }
    return null
  }

  clearCache() {
    this.cache = {
      contexts: {},
      appointmentGroups: {},
      participants: {},
      fetchedAppointmentGroups: null
    }
    this.contexts.forEach(contextInfo => {
      this.cache.contexts[contextInfo.asset_string] = {
        events: {},
        fetchedRanges: [],
        fetchedUndated: false
      }
    })
  }

  removeCachedReservation(event) {
    const cached_ag = this.cache.appointmentGroups[event.appointment_group_id]
    if (cached_ag) {
      cached_ag.reserved_times = _.reject(
        cached_ag.reserved_times,
        reservation => reservation.id === event.id
      )
      if (cached_ag.reserved_times.length === 0) {
        cached_ag.requiring_action = true
      }
    }
  }

  requiredDateRangeForContext(start, end, context) {
    let contextInfo, ranges
    if (!(contextInfo = this.cache.contexts[context])) return [start, end]

    if (!(ranges = contextInfo.fetchedRanges)) return [start, end]

    ranges.forEach(range => {
      if (range[0] <= start && start < range[1]) start = range[1]
      if (range[0] < end && end <= range[1]) end = range[0]
    })
    return [start, end]
  }

  requiredDateRangeForContexts(start, end, contexts) {
    // We assume that we're not going to need anything from the cache - setting
    // the initial assumptions to the opposites of the requests is a fun way to
    // do that.
    let earliest = end
    let latest = start
    contexts.forEach(context => {
      const [s, e] = this.requiredDateRangeForContext(start, end, context)
      if (s < earliest) earliest = s
      if (e > latest) latest = e
    })
    return [earliest, latest]
  }

  needUndatedEventsForContexts(contexts) {
    return contexts.some(context => !this.cache.contexts[context].fetchedUndated)
  }

  addEventToCache(event) {
    if (event.old_context_code) {
      delete this.cache.contexts[event.old_context_code].events[event.id]
      delete event.old_context_code
    }
    // Split by comma, for the odd case where #contextCode() returns a comma seprated list
    const possibleContexts = event.contextCode().split(',')
    const okayContexts = possibleContexts.filter(cCode => !!this.cache.contexts[cCode])
    const contextCode = okayContexts[0]
    const contextInfo = this.cache.contexts[contextCode]
    contextInfo.events[event.id] = event
  }

  getEventsFromCacheForContext(start, end, context) {
    const contextInfo = this.cache.contexts[context]
    const events = []
    for (const id in contextInfo.events) {
      const event = contextInfo.events[id]
      if (this.eventInRange(event, start, end)) {
        events.push(event)
      }
    }
    return events
  }

  eventInRange(event, start, end) {
    let ref
    if (!event.originalStart && !start) {
      // want undated, have undated, include it
      return true
    } else if (!event.originalStart || !start) {
      // want undated, have dated (or vice versa), skip it
      return false
    } else {
      // want dated, have dated. but when comparing to the range, remember
      // that we made start/end be unwrapped values (down in getEvents), so
      // unwrap event.originalStart too before comparing
      return start <= (ref = fcUtil.unwrap(event.originalStart)) && ref < end
    }
  }

  processNextRequest(inFlightCheckKey = 'default') {
    let i, id, len
    const ref = this.pendingRequests
    for (id = i = 0, len = ref.length; i < len; id = ++i) {
      const [method, args, key] = ref[id]
      if (key === inFlightCheckKey) {
        this.pendingRequests.splice(id, 1)
        method(...args)
        return
      }
    }
  }

  getEventsFromCache(start, end, contexts) {
    let events = []
    for (let i = 0, len = contexts.length; i < len; i++) {
      const context = contexts[i]
      if (context.match(/^appointment_group_/)) {
        continue
      }
      events = events.concat(this.getEventsFromCacheForContext(start, end, context))
    }
    return events
  }

  getAppointmentGroupsFromCache() {
    const results = []
    for (const id in this.cache.appointmentGroups) {
      const group = this.cache.appointmentGroups[id]
      results.push(group)
    }
    return results
  }

  getAppointmentGroups(fetchManageable, cb) {
    if (this.inFlightRequest.appointmentGroups) {
      this.pendingRequests.push([this.getAppointmentGroups, arguments, 'appointmentGroups'])
      return
    }
    if (
      this.cache.fetchedAppointmentGroups &&
      this.cache.fetchedAppointmentGroups.manageable === fetchManageable
    ) {
      cb(this.getAppointmentGroupsFromCache())
      this.processNextRequest('appointmentGroups')
      return
    }
    this.cache.fetchedAppointmentGroups = {
      manageable: fetchManageable
    }
    this.cache.appointmentGroups = {}
    const dataCB = (data, url, params) => {
      let group, i, len, results
      if (data) {
        results = []
        for (i = 0, len = data.length; i < len; i++) {
          group = data[i]
          if (params.scope === 'manageable') {
            group.is_manageable = true
          } else {
            group.is_scheduleable = true
          }
          results.push(this.processAppointmentData(group))
        }
        return results
      }
    }
    const doneCB = () => cb(this.getAppointmentGroupsFromCache())
    const fetchJobs = [
      [
        '/api/v1/appointment_groups',
        {
          include: ['reserved_times', 'participant_count']
        }
      ]
    ]
    if (fetchManageable) {
      fetchJobs.push([
        '/api/v1/appointment_groups',
        {
          scope: 'manageable',
          include: ['reserved_times', 'participant_count'],
          include_past_appointments: true
        }
      ])
    }
    return this.startFetch(fetchJobs, dataCB, doneCB, {
      inFlightCheckKey: 'appointmentGroups'
    })
  }

  processAppointmentData(group) {
    const {id} = group
    if (
      this.cache.appointmentGroups[id] &&
      this.cache.appointmentGroups[id].is_manageable
    ) {
      group.is_manageable = true
    } else {
      group.is_scheduleable = true
    }
    this.cache.appointmentGroups[id] = group
    if (group.appointments) {
      group.appointmentEvents = []
      group.appointments.forEach(eventData => {
        const event = commonEventFactory(eventData, this.contexts)
        if (event && event.object.workflow_state !== 'deleted') {
          group.appointmentEvents.push(event)
          this.addEventToCache(event)
          if (eventData.child_events) {
            event.childEvents = []
            eventData.child_events.forEach(childEventData => {
              const childEvent = commonEventFactory(childEventData, this.contexts)
              this.addEventToCache(event)
              if (childEvent) event.childEvents.push(childEvent)
            })
          }
        }
      })
    }
  }

  getEventsForAppointmentGroup(group, cb) {
    if (this.inFlightRequest.default) {
      this.pendingRequests.push([this.getEventsForAppointmentGroup, arguments, 'default'])
      return
    }
    const cachedEvents =
      this.cache.appointmentGroups[group.id] &&
      this.cache.appointmentGroups[group.id].appointmentEvents

    if (cachedEvents) {
      cb(cachedEvents)
      this.processNextRequest()
      return
    }
    const dataCB = data => {
      if (data) {
        return this.processAppointmentData(data)
      }
    }
    const params = {
      include: ['reserved_times', 'participant_count', 'appointments', 'child_events']
    }
    return this.startFetch([[group.url, params]], dataCB, () =>
      cb(this.cache.appointmentGroups[group.id].appointmentEvents)
    )
  }

  getEvents(start, end, contexts, donecb, datacb, options = {}) {
    if (this.inFlightRequest.default) {
      this.pendingRequests.push([this.getEvents, arguments, 'default'])
      return
    }

    // start/end as they come from fullcalendar or AgendaView may be
    // ambiguously-timed and/or ambiguously-zoned. that's just way too much
    // confusion. instead, let's always works with unwrapped datetimes, so we
    // know we're interpreting times in the context of the profile timezone,
    // and particularly ambiguously-timed dates as midnight in the profile
    // timezone.
    if (start) start = fcUtil.unwrap(start)
    if (end) end = fcUtil.unwrap(end)

    const paramsForDatedEvents = (start, end, contexts) => {
      const [startDay, endDay] = this.requiredDateRangeForContexts(start, end, contexts)
      if (startDay >= endDay) {
        return null
      }
      return {
        // we treat end as an exclusive upper bound. the API treats it as
        // inclusive, so we may get back some events we didn't intend. but
        // addEventToCache handles the duplicate fine, so it's ok
        context_codes: contexts,
        start_date: startDay.toISOString(),
        end_date: endDay.toISOString()
      }
    }
    const paramsForUndatedEvents = contexts => {
      if (!this.needUndatedEventsForContexts(contexts)) {
        return null
      }
      return {
        context_codes: contexts,
        undated: '1'
      }
    }
    const params = start
      ? paramsForDatedEvents(start, end, contexts)
      : paramsForUndatedEvents(contexts)
    if (!params) {
      // Yay, this request can be satisfied by the cache
      const list = this.getEventsFromCache(start, end, contexts)
      list.requestID = options.requestID
      if (datacb != null) datacb(list)
      donecb(list)
      this.processNextRequest()
      return
    }
    const requestResults = {}
    const dataCB = (data, url, params) => {
      let key
      if (!data) return

      const newEvents = []
      // planner_items and planner_notes are passing thru here too now
      // detect and add some missing fields the calendar code needs
      if (data.length && 'plannable' in data[0]) {
        data = this.transformPlannerItems(data)
        key = 'type_planner_item'
      } else if (data.length && 'todo_date' in data[0]) {
        data = this.fillOutPlannerNotes(data, url)
        key = 'type_planner_note'
      } else {
        key = `type_${params.type}`
      }
      const requestResult = requestResults[key] || {
        events: []
      }
      requestResult.next = data.next
      data.forEach(e => {
        const event = commonEventFactory(e, this.contexts)
        if (event && event.object.workflow_state !== 'deleted') {
          newEvents.push(event)
          requestResult.events.push(event)
        }
      })
      newEvents.requestID = options.requestID
      if (datacb != null) datacb(newEvents)

      return (requestResults[key] = requestResult)
    }
    const doneCB = () => {
      let nextPageDate
      // TODO: there's a rare problem in this implementation. if a full page
      // or more of events have the same start time, then the first time one
      // or more show up in a response, that date will be the nextPageDate. as
      // such, all events for that date will be excluded. but then on the
      // followup, the nextPageDate will _still_ be that date, and zero events
      // will be included. it will then loop indefinitely in this state.

      // If any request had a next page, the combined results are valid
      // only through the earliest page end date. note that it's an exclusive
      // upper bound, just as we treated end earlier. (this is so that it can
      // be an inclusive lower bound on the next request)
      const rendered = new Set()
      const upperBounds = []
      for (const key in requestResults) {
        const requestResult = requestResults[key]
        const dates = []
        requestResult.events.forEach(event => {
          this.addEventToCache(event)
          rendered.add(event.id)
          if (requestResult.next && event.originalStart) {
            dates.push(event.originalStart)
          }
        })

        if (!_.isEmpty(dates)) {
          upperBounds.push(_.max(dates))
        }
      }
      if (!_.isEmpty(upperBounds)) {
        nextPageDate = fcUtil.clone(_.min(upperBounds))
        end = fcUtil.unwrap(nextPageDate)
      }
      contexts.forEach(context => {
        let contextInfo = this.cache.contexts[context]
        if (!contextInfo) {
          contextInfo = this.cache.contexts[context] = {
            fetchedRanges: []
          }
        }
        if (contextInfo) {
          if (start) {
            contextInfo.fetchedRanges.push([start, end])
          } else {
            contextInfo.fetchedUndated = true
          }
        }
      })

      const list = this.getEventsFromCache(start, end, contexts)
      if (datacb != null && list.length > 0) {
        const renderFromCache = list.filter(x => !rendered.has(x.id))
        if (renderFromCache.length > 0) {
          datacb(renderFromCache)
        }
      }
      list.nextPageDate = nextPageDate
      list.requestID = options.requestID
      return donecb(list)
    }
    const eventDataSources = [
      ['/api/v1/calendar_events', this.indexParams(params)]
    ]
    params.context_codes = params.context_codes.filter(context => !context.match(/^appointment_group_/))
    eventDataSources.push(['/api/v1/calendar_events', this.assignmentParams(params)])
    if (ENV.STUDENT_PLANNER_ENABLED) {
      eventDataSources.push(['/api/v1/planner_notes', params])
    }
    if (ENV.PLANNER_ENABLED) {
      const [admin_contexts, student_contexts] = _.partition(params.context_codes, (cc) => (
        ENV.CALENDAR.MANAGE_CONTEXTS.indexOf(cc) >= 0
      ))
      if (student_contexts.length) {
        const pparams = _.extend({filter: 'ungraded_todo_items'}, params, {context_codes: student_contexts})
        eventDataSources.push(['/api/v1/planner/items', pparams])
      }
      if (admin_contexts.length) {
        const pparams = _.extend({filter: 'all_ungraded_todo_items'}, params, {context_codes: admin_contexts})
        eventDataSources.push(['/api/v1/planner/items', pparams])
      }
    }
    return this.startFetch(eventDataSources, dataCB, doneCB, options)
  }

  // rewrite `context_codes[]=appointment_group_X&context_codes[]=appointment_group_Y`
  // as `appointment_group_ids=X,Y` to reduce Link header size in the HTTP response
  // (which Apache limits to 8K)
  indexParams(params) {
    const ag_ids = []
    const context_codes = []
    params.context_codes.forEach(context_code => {
      const match = context_code.match(/^appointment_group_(\d+)$/)
      if (match && match.length === 2) {
        ag_ids.push(match[1])
      } else {
        context_codes.push(context_code)
      }
    })
    const p = {...params, context_codes}
    if (ag_ids.length > 0) {
      p.appointment_group_ids = ag_ids.join(',')
    }
    return p
  }

  assignmentParams(params) {
    return {type: 'assignment', ...params}
  }

  getParticipants(appointmentGroup, registrationStatus, cb) {
    if (this.inFlightRequest.default) {
      this.pendingRequests.push([this.getParticipants, arguments, 'default'])
      return
    }
    const key = `${appointmentGroup.id}_${registrationStatus}`
    if (this.cache.participants[key]) {
      cb(this.cache.participants[key])
      this.processNextRequest()
      return
    }
    this.cache.participants[key] = []
    const dataCB = (data, url, params) => {
      if (data) {
        return this.cache.participants[key].push.apply(this.cache.participants[key], data)
      }
    }
    const doneCB = () => cb(this.cache.participants[key])
    const type = appointmentGroup.participant_type === 'Group' ? 'groups' : 'users'
    return this.startFetch(
      [
        [
          `/api/v1/appointment_groups/${appointmentGroup.id}/${type}`,
          {
            registration_status: registrationStatus
          }
        ]
      ],
      dataCB,
      doneCB
    )
  }

  // Starts a paginated fetch of the url/param combinations in the array. This makes
  // situations where you need to do paginated fetches of data from N different endpoints
  // a little simpler. dataCB(data, url, params) is called on every request with the data,
  // and completionCB is called when all fetches have completed.
  startFetch(urlAndParamsArray, dataCB, doneCB, options = {}) {
    let numCompleted = 0
    const inFlightCheckKey = options.inFlightCheckKey || 'default'
    this.inFlightRequest[inFlightCheckKey] = true
    const wrapperCB = (data, isDone, url, params) => {
      dataCB(data, url, params)
      if (isDone) {
        numCompleted += 1
        if (numCompleted >= urlAndParamsArray.length) {
          doneCB()
          this.inFlightRequest[inFlightCheckKey] = false
          return this.processNextRequest(inFlightCheckKey)
        }
      }
    }
    const results = []
    for (let i = 0, len = urlAndParamsArray.length; i < len; i++) {
      const urlAndParams = urlAndParamsArray[i]
      results.push(
        (urlAndParams =>
          this.fetchNextBatch(
            urlAndParams[0],
            urlAndParams[1],
            (data, isDone) => wrapperCB(data, isDone, urlAndParams[0], urlAndParams[1]),
            options
          ))(urlAndParams)
      )
    }
    return results
  }

  // Will fetch the URL with the given params, and if the response includes a Link
  // header, will fetch that link too (with the same params). At the end of every
  // request it will call cb(data, isDone). isDone will be true on the last request.
  fetchNextBatch(url, params, cb, options = {}) {
    const parseLinkHeader = function(header) {
      if (!header) {
        // TODO: Write a real Link header parser. This will only work with what we output,
        // and might be fragile.
        return null
      }
      const rels = {}
      const ref = header.split(',')
      for (let i = 0, len = ref.length; i < len; i++) {
        const component = ref[i]
        let [link, rel] = component.split(';')
        link = link.replace(/^</, '').replace(/>$/, '')
        rel = rel.split('"')[1]
        rels[rel] = link
      }
      return rels
    }
    $.publish('EventDataSource/ajaxStarted')
    if (!(url.match(/per_page=/) || params.per_page != null)) {
      params.per_page = 50
    }
    return $.ajaxJSON(url, 'GET', params, (data, xhr) => {
      $.publish('EventDataSource/ajaxEnded')
      const linkHeader =
        typeof xhr.getResponseHeader === 'function' ? xhr.getResponseHeader('Link') : void 0
      const rels = parseLinkHeader(linkHeader)
      data.next = rels != null ? rels.next : void 0
      if (rels && rels.next && !options.singlePage) {
        cb(data, false)
        this.fetchNextBatch(rels.next, {}, cb)
        return
      }
      return cb(data, true)
    })
  }

  // Planner notes are getting pulled from the planner_notes api
  // Add some necessary fields so they can be processed just like a calendar event
  fillOutPlannerNotes(notes, url) {
    notes.forEach(note => {
      note.type = 'planner_note'
      note.context_code = note.course_id ? `course_${note.course_id}` : `user_${note.user_id}`
      note.all_context_codes = note.context_code
    })
    return notes
  }

  // make planner items readable as calendar events
  transformPlannerItems(items) {
    items.forEach(item => {
      /* eslint-disable no-param-reassign */
      item.type = 'todo_item'
      if (item.course_id) {
        item.context_code = `course_${item.course_id}`
      } else if (item.group_id) {
        item.context_code = `group_${item.group_id}`
      } else {
        item.context_code = `user_${item.user_id}`
      }
      item.all_context_codes = item.context_code
      /* eslint-enable no-param-reassign */
    })
    return items
  }
}
