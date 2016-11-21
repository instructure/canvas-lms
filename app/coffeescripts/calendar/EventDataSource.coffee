define [
  'jquery'
  'underscore'
  'compiled/util/fcUtil'
  'compiled/calendar/commonEventFactory'
  'jquery.ajaxJSON'
  'vendor/jquery.ba-tinypubsub'
], ($, _, fcUtil, commonEventFactory) ->

  class
    constructor: (contexts) ->
      @contexts = contexts
      @clearCache()
      @inFlightRequest = {}
      @pendingRequests = []

      # The cache will store all the events we've fetched so far, and looks like this:
      # {
      #   contexts: {
      #     "user_1": {
      #       fetchedRanges: [
      #         sorted list of [start, end] tuples that represent
      #         ranges of dates that we have already fetched for
      #       ]
      #       events: {
      #         "assignment_1": <CommonEvent object>
      #       },
      #       fetchedUndated: true/false
      #     }, ...
      #   },
      #   appointmentGroups: {
      #     "1": <object>
      #   },
      #   participants: {
      #     "1_unregistered": [ users or groups ]
      #   }
      #   fetchedAppointmentGroups: { manageable: true/false }
      # }
      #
      # Note that the appointmentGroups are not cached per context, as
      # we get them all in the same request (not scoped to contexts at
      # all.) This might end up being confusing.

      $.subscribe "CommonEvent/eventDeleted", @eventDeleted
      $.subscribe "CommonEvent/eventSaved", @eventSaved

    eventSaved: (event) =>
      @addEventToCache(event)

    eventDeleted: (event) =>
      events = @cache.contexts[event.contextCode()]?.events
      if events
        delete events[event.id]

    eventWithId: (id) =>
      for contextCode, contextData of @cache.contexts
        if contextData.events[id]
          return contextData.events[id]

      null

    clearCache: () =>
      @cache = {
        contexts: {}
        appointmentGroups: {}
        participants: {}
        fetchedAppointmentGroups: null
      }
      for contextInfo in @contexts
        @cache.contexts[contextInfo.asset_string] = {
          events: {},
          fetchedRanges: [],
          fetchedUndated: false,
        }

    requiredDateRangeForContext: (start, end, context) =>
      unless contextInfo = @cache.contexts[context]
        return [ start, end ]

      unless ranges = contextInfo.fetchedRanges
        return [ start, end ]

      for range in ranges
        if range[0] <= start < range[1]
          start = range[1]
        if range[0] < end <= range[1]
          end = range[0]

      [ start, end ]

    requiredDateRangeForContexts: (start, end, contexts) =>
      # We assume that we're not going to need anything from the cache - setting
      # the initial assumptions to the opposites of the requests is a fun way to
      # do that.
      earliest = end
      latest = start
      for context in contexts
        [ s, e ] = @requiredDateRangeForContext(start, end, context)
        earliest = s if s < earliest
        latest = e if e > latest

      [ earliest, latest ]

    needUndatedEventsForContexts: (contexts) =>
      for context in contexts
        return true if !@cache.contexts[context].fetchedUndated
      false

    addEventToCache: (event) =>
      if event.old_context_code
        delete @cache.contexts[event.old_context_code].events[event.id]
        delete event.old_context_code

      # Split by comma, for the odd case where #contextCode() returns a comma seprated list
      possibleContexts = event.contextCode().split(',')
      okayContexts = possibleContexts.filter((cCode) =>
        !!@cache.contexts[cCode]
      )
      contextCode = okayContexts[0]
      contextInfo = @cache.contexts[contextCode]

      contextInfo.events[event.id] = event

    getEventsFromCacheForContext: (start, end, context) =>
      contextInfo = @cache.contexts[context]

      events = []
      for id, event of contextInfo.events
        if @eventInRange(event, start, end)
          events.push(event)

      events

    eventInRange: (event, start, end) ->
      if !event.originalStart && !start
        # want undated, have undated, include it
        true
      else if !event.originalStart || !start
        # want undated, have dated (or vice versa), skip it
        false
      else
        # want dated, have dated. but when comparing to the range, remember
        # that we made start/end be unwrapped values (down in getEvents), so
        # unwrap event.originalStart too before comparing
        start <= fcUtil.unwrap(event.originalStart) < end

    processNextRequest: (inFlightCheckKey='default') =>
      for [method, args, key], id in @pendingRequests
        if key == inFlightCheckKey
          @pendingRequests.splice(id, 1)
          method args...
          return

    getEventsFromCache: (start, end, contexts) =>
      events = []
      for context in contexts
        continue if context.match /^appointment_group_/
        events = events.concat(@getEventsFromCacheForContext start, end, context)
      events

    getAppointmentGroupsFromCache: () =>
      (group for id, group of @cache.appointmentGroups)

    getAppointmentGroups: (fetchManageable, cb) =>
      if @inFlightRequest['appointmentGroups']
        @pendingRequests.push([@getAppointmentGroups, arguments, 'appointmentGroups'])
        return

      if @cache.fetchedAppointmentGroups && @cache.fetchedAppointmentGroups.manageable == fetchManageable
        cb @getAppointmentGroupsFromCache()
        @processNextRequest('appointmentGroups')
        return

      @cache.fetchedAppointmentGroups = { manageable: fetchManageable }
      @cache.appointmentGroups = {}

      dataCB = (data, url, params) =>
        if data
          for group in data
            if params.scope == "manageable"
              group.is_manageable = true
            else
              group.is_scheduleable = true
            @processAppointmentData group

      doneCB = () => cb @getAppointmentGroupsFromCache()

      fetchJobs = [[ '/api/v1/appointment_groups', { include: [ 'reserved_times', 'participant_count' ] } ]]

      if fetchManageable
        fetchJobs.push [ '/api/v1/appointment_groups', { scope: 'manageable', include: [ 'reserved_times', 'participant_count' ], include_past_appointments: true } ]

      @startFetch fetchJobs, dataCB, doneCB, {inFlightCheckKey: 'appointmentGroups'}

    processAppointmentData: (group) =>
      id = group.id
      if @cache.appointmentGroups[id]?.is_manageable
        group.is_manageable = true
      else
        group.is_scheduleable = true
      @cache.appointmentGroups[id] = group

      if group.appointments
        group.appointmentEvents = []
        for eventData in group.appointments
          event = commonEventFactory(eventData, @contexts)
          if event && event.object.workflow_state != 'deleted'
            group.appointmentEvents.push event
            @addEventToCache event

            if eventData.child_events
              event.childEvents = []
              for childEventData in eventData.child_events
                childEvent = commonEventFactory(childEventData, @contexts)
                @addEventToCache event
                if childEvent
                  event.childEvents.push childEvent

    getEventsForAppointmentGroup: (group, cb) =>
      if @inFlightRequest['default']
        @pendingRequests.push([@getEventsForAppointmentGroup, arguments, 'default'])
        return

      cachedEvents = @cache.appointmentGroups[group.id]?.appointmentEvents
      if cachedEvents
        cb cachedEvents
        @processNextRequest()
        return

      dataCB = (data) =>
        @processAppointmentData data if data

      params = { include: [ 'reserved_times', 'participant_count', 'appointments', 'child_events' ]}
      @startFetch [[ group.url, params ]], dataCB, (() => cb @cache.appointmentGroups[group.id].appointmentEvents)

    getEvents: (start, end, contexts, donecb, datacb, options = {}) =>
      if @inFlightRequest['default']
        @pendingRequests.push([@getEvents, arguments, 'default'])
        return

      # start/end as they come from fullcalendar or AgendaView may be
      # ambiguously-timed and/or ambiguously-zoned. that's just way too much
      # confusion. instead, let's always works with unwrapped datetimes, so we
      # know we're interpreting times in the context of the profile timezone,
      # and particularly ambiguously-timed dates as midnight in the profile
      # timezone.
      start = fcUtil.unwrap(start) if start
      end = fcUtil.unwrap(end) if end

      paramsForDatedEvents = (start, end, contexts) =>
        [ startDay, endDay ] = @requiredDateRangeForContexts(start, end, contexts)

        if startDay >= endDay
          return null

        # we treat end as an exclusive upper bound. the API treats it as
        # inclusive, so we may get back some events we didn't intend. but
        # addEventToCache handles the duplicate fine, so it's ok
        {
          context_codes: contexts
          start_date: startDay.toISOString()
          end_date: endDay.toISOString()
        }

      paramsForUndatedEvents = (contexts) =>
        if !@needUndatedEventsForContexts(contexts)
          return null

        {
          context_codes: contexts
          undated: '1'
        }

      params = if start
        paramsForDatedEvents start, end, contexts
      else
        paramsForUndatedEvents contexts

      if !params
        # Yay, this request can be satisfied by the cache
        list = @getEventsFromCache(start, end, contexts)
        list.requestID = options.requestID
        datacb list if datacb?
        donecb list
        @processNextRequest()
        return

      requestResults = {}
      dataCB = (data, url, params) =>
        return unless data
        newEvents = []
        key = 'type_'+params.type
        requestResult = requestResults[key] or {events: []}
        requestResult.next = data.next
        for e in data
          event = commonEventFactory(e, @contexts)
          if event && event.object.workflow_state != 'deleted'
            newEvents.push(event)
            requestResult.events.push(event)
        newEvents.requestID = options.requestID
        datacb newEvents if datacb?
        requestResults[key] = requestResult

      doneCB = () =>
        # TODO: there's a rare problem in this implementation. if a full page
        # or more of events have the same start time, then the first time one
        # or more show up in a response, that date will be the nextPageDate. as
        # such, all events for that date will be excluded. but then on the
        # followup, the nextPageDate will _still_ be that date, and zero events
        # will be included. it will then loop indefinitely in this state.

        # If any request had a next page, the combined results are valid
        # only through the earliest page end date. note that it's an exclusive
        # upper bound, just as we treated end earlier. (this is so that it can
        # be an inclusive lower bound on the next request)

        rendered = new Set
        upperBounds = []
        for key, requestResult of requestResults
          dates = []
          for event in requestResult.events
            @addEventToCache event
            rendered.add event.id
            if requestResult.next && event.originalStart
              dates.push(event.originalStart)
          if !_.isEmpty(dates)
            upperBounds.push(_.max(dates))

        # consumer of list.nextPageDate is going to expect to just be able to
        # pass it back to getEvents as the start, so it need to be wrapped
        # (which it is, if set, based on the events' originalStart). but for
        # use in place of end, it needs to be unwrapped
        if !_.isEmpty(upperBounds)
          nextPageDate = fcUtil.clone(_.min(upperBounds))
          end = fcUtil.unwrap(nextPageDate)

        for context in contexts
          contextInfo = @cache.contexts[context]
          contextInfo = (@cache.contexts[context] = {fetchedRanges: []}) unless contextInfo
          if contextInfo
            if start
              contextInfo.fetchedRanges.push([start, end])
            else
              contextInfo.fetchedUndated = true

        list = @getEventsFromCache(start, end, contexts)
        if datacb? && list.length > 0
          renderFromCache = list.filter (x) -> not rendered.has x.id
          datacb(renderFromCache) if renderFromCache.length > 0
        list.nextPageDate = nextPageDate
        list.requestID = options.requestID
        donecb list

      @startFetch [
        [ '/api/v1/calendar_events', params ]
        [ '/api/v1/calendar_events', @assignmentParams(params) ]
      ], dataCB, doneCB, options

    assignmentParams: (params) ->
      p = $.extend({type: 'assignment'}, params)
      p.context_codes = p.context_codes.filter (context) -> not context.match /^appointment_group_/
      p

    getParticipants: (appointmentGroup, registrationStatus, cb) =>
      if @inFlightRequest['default']
        @pendingRequests.push([@getParticipants, arguments, 'default'])
        return

      key = "#{appointmentGroup.id}_#{registrationStatus}"

      if @cache.participants[key]
        cb @cache.participants[key]
        @processNextRequest()
        return

      @cache.participants[key] = []

      dataCB = (data, url, params) =>
        if data
          @cache.participants[key].push.apply(@cache.participants[key], data)

      doneCB = () => cb @cache.participants[key]

      type = if appointmentGroup.participant_type is "Group" then 'groups' else 'users'
      @startFetch [
        ["/api/v1/appointment_groups/#{appointmentGroup.id}/#{type}", {registration_status: registrationStatus}]
      ], dataCB, doneCB

    # Starts a paginated fetch of the url/param combinations in the array. This makes
    # situations where you need to do paginated fetches of data from N different endpoints
    # a little simpler. dataCB(data, url, params) is called on every request with the data,
    # and completionCB is called when all fetches have completed.
    startFetch: (urlAndParamsArray, dataCB, doneCB, options = {}) =>
      numCompleted = 0

      inFlightCheckKey = options.inFlightCheckKey || 'default'
      @inFlightRequest[inFlightCheckKey] = true

      wrapperCB = (data, isDone, url, params) =>
        dataCB(data, url, params)

        if isDone
          numCompleted += 1
          if numCompleted >= urlAndParamsArray.length
            doneCB()
            @inFlightRequest[inFlightCheckKey] = false
            @processNextRequest(inFlightCheckKey)

      for urlAndParams in urlAndParamsArray
        do (urlAndParams) =>
          @fetchNextBatch urlAndParams[0], urlAndParams[1], ((data, isDone) -> wrapperCB(data, isDone, urlAndParams[0], urlAndParams[1])), options

    # Will fetch the URL with the given params, and if the response includes a Link
    # header, will fetch that link too (with the same params). At the end of every
    # request it will call cb(data, isDone). isDone will be true on the last request.
    fetchNextBatch: (url, params, cb, options = {}) =>
      parseLinkHeader = (header) ->
        # TODO: Write a real Link header parser. This will only work with what we output,
        # and might be fragile.
        return null unless header
        rels = {}
        for component in header.split(',')
          [ link, rel ] = component.split(';')
          link = link.replace(/^</, '').replace(/>$/, '')
          rel = rel.split('"')[1]
          rels[rel] = link
        rels

      $.publish "EventDataSource/ajaxStarted"

      unless url.match(/per_page=/) or params.per_page?
        params.per_page = 50

      $.ajaxJSON url, 'GET', params, (data, xhr) =>
        $.publish "EventDataSource/ajaxEnded"

        linkHeader = xhr.getResponseHeader?('Link')
        rels = parseLinkHeader(linkHeader)
        data.next = rels?.next

        if rels?.next && !options.singlePage
          cb(data, false)
          @fetchNextBatch rels.next, {}, cb
          return

        cb(data, true)
