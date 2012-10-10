define [
  'jquery'
  'compiled/calendar/commonEventFactory'
  'jquery.ajaxJSON'
  'vendor/jquery.ba-tinypubsub'
], ($, commonEventFactory) ->

  class
    constructor: (contexts) ->
      @contexts = contexts
      @clearCache()
      @inFlightRequest = false
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
        if range[0] <= start && start <= range[1]
          start = range[1]
        if range[0] <= end && end <= range[1]
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
      contextCode = event.contextCode()
      contextInfo = @cache.contexts[contextCode]

      contextInfo.events[event.id] = event

    getEventsFromCacheForContext: (start, end, context) =>
      contextInfo = @cache.contexts[context]

      events = []
      for id, event of contextInfo.events
        if !event.start && !start || event.start >= start && event.start <= end
          events.push event

      events

    processNextRequest: () =>
      request = @pendingRequests.shift()
      if request
        method = request[0]
        args = request[1]
        method args...

    getEventsFromCache: (start, end, contexts) =>
      events = []
      for context in contexts
        events = events.concat(@getEventsFromCacheForContext start, end, context)
      events

    getAppointmentGroupsFromCache: () =>
      (group for id, group of @cache.appointmentGroups)

    getAppointmentGroups: (fetchManageable, cb) =>
      if @inFlightRequest
        @pendingRequests.push([@getAppointmentGroups, arguments])
        return

      if @cache.fetchedAppointmentGroups && @cache.fetchedAppointmentGroups.manageable == fetchManageable
        cb @getAppointmentGroupsFromCache()
        @processNextRequest()
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

      fetchJobs = [[ '/api/v1/appointment_groups', { include: [ 'appointments', 'child_events' ] } ]]

      if fetchManageable
        fetchJobs.push [ '/api/v1/appointment_groups', { scope: 'manageable', include: [ 'appointments', 'child_events' ] } ]

      @startFetch fetchJobs, dataCB, doneCB

    processAppointmentData: (group) =>
      id = group.id
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
                event.childEvents.push childEvent

    getEventsForAppointmentGroup: (group, cb) =>
      if @inFlightRequest
        @pendingRequests.push([@getEventsForAppointmentGroup, arguments])
        return

      # appointment group events are cached on the appointment group itself
      if group.appointmentEvents
        cb group.appointmentEvents
        @processNextRequest()
        return

      dataCB = (data) =>
        @processAppointmentData data if data

      params = { include: [ 'appointments', 'child_events' ]}
      @startFetch [[ group.url, params ]], dataCB, (() => cb group.appointmentEvents)

    getEvents: (start, end, contexts, cb) =>
      if @inFlightRequest
        @pendingRequests.push([@getEvents, arguments])
        return

      paramsForDatedEvents = (start, end, contexts) =>
        [ startDay, endDay ] = @requiredDateRangeForContexts(start, end, contexts)

        if startDay >= endDay
          return null

        {
          context_codes: contexts
          start_date: $.dateToISO8601UTC(startDay)
          end_date: $.dateToISO8601UTC(endDay)
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
        cb @getEventsFromCache(start, end, contexts)
        @processNextRequest()
        return

      for context in contexts
        contextInfo = @cache.contexts[context]
        if contextInfo
          if start
            contextInfo.fetchedRanges.push([start, end])
          else
            contextInfo.fetchedUndated = true

      doneCB = () =>
        cb @getEventsFromCache(start, end, contexts)

      dataCB = (data) =>
        if data
          for e in data
            event = commonEventFactory(e, @contexts)
            if event && event.object.workflow_state != 'deleted'
              @addEventToCache event

      @startFetch [
        [ '/api/v1/calendar_events', params ]
        [ '/api/v1/calendar_events', $.extend({type: 'assignment'}, params) ]
      ], dataCB, doneCB

    getParticipants: (appointmentGroup, registrationStatus, cb) =>
      if @inFlightRequest
        @pendingRequests.push([@getParticipants, arguments])
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
    startFetch: (urlAndParamsArray, dataCB, doneCB) =>
      numCompleted = 0

      @inFlightRequest = true

      wrapperCB = (data, isDone, url, params) =>
        dataCB(data, url, params)

        if isDone
          numCompleted += 1
          if numCompleted >= urlAndParamsArray.length
            doneCB()
            @inFlightRequest = false
            @processNextRequest()

      for urlAndParams in urlAndParamsArray
        do (urlAndParams) =>
          @fetchNextBatch urlAndParams[0], urlAndParams[1], (data, isDone) -> wrapperCB(data, isDone, urlAndParams[0], urlAndParams[1])

    # Will fetch the URL with the given params, and if the response includes a Link
    # header, will fetch that link too (with the same params). At the end of every
    # request it will call cb(data, isDone). isDone will be true on the last request.
    fetchNextBatch: (url, params, cb) =>
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

        if rels?.next
          cb(data, false)
          @fetchNextBatch rels.next, {}, cb
          return

        cb(data, true)
