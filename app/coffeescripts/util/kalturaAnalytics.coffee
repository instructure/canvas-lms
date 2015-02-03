define [
  'jquery'
  'underscore'
  'vendor/jquery.cookie'
], ($, _) ->

  # A class to setup kaltura analytics listeners on a mediaElement player
  # for a specific video being played
  # As events are created they are sent to kaltura's analytics api
  class KalturaAnalytics

    constructor: (@mediaId, @mediaElement, @pluginSettings) ->

      @ensureAnalyticSession()
      @generateApiUrl()

      @defaultData =
        service: 'stats'
        action: 'collect'
        'event:entryId': @mediaId
        'event:sessionId': @kaSession
        'event:isFirstInSession': "false"
        'event:objectType': "KalturaStatsEvent"
        'event:partnerId': @pluginSettings.partner_id
        'event:uiconfId': @pluginSettings.kcw_ui_conf
        'event:queryStringReferrer': window.location.href

    # Builds the url to send the analytic event and adds it to the processing queue
    queueAnalyticEvent: (eventId) =>
      data = _.clone(@defaultData);
      data['event:eventType'] = eventId
      data['event:duration'] = @mediaElement.duration
      data['event:currentPoint'] = parseInt(@mediaElement.currentTime * 1000)
      data['event:eventTimestamp'] =  new Date().getTime()

      @queueApiCall(@apiUrl + $.param(data))

    # kaltura expects a persistent analytic session token for the user
    # this generates a simple session id for analytic purposes
    # no session/authentication is associated with this token
    ensureAnalyticSession: =>
      @kaSession = $.cookie('kaltura_analytic_tracker', undefined, path: '/')
      if !@kaSession
        @kaSession = (Math.random().toString(16) + Math.random().toString(16) + Math.random().toString(16)).replace(/\./g,'')
        $.cookie('kaltura_analytic_tracker', @kaSession, path: '/');

    # pulls the kaltura domain from the plugin settins and sets up the base
    # url for sending analytics events
    generateApiUrl: =>
      if window.location.protocol is 'http:'
        domain = "http://#{@pluginSettings.domain}"
      else
        domain = "https://#{@pluginSettings.domain}"

      @apiUrl = "#{domain}/api_v3/index.php?"

    # Since the analytic call is a cross-domain call, set the url in an iFrame
    setupApiIframes: (count) =>
      @qIndex = 0
      @iframes = []
      for i in [0..count-1]
        iframe = document.createElement('iframe')
        $(iframe).addClass('hidden kaltura-analytics')
        $(document.body).append($(iframe))

        # there is no reliable way to know when a remote url has loaded in an
        # iframe, so just send them every 4 seconds
        queue = []
        f = ((iframe, queue) ->
          -> iframe.src = url if url = queue.shift()
        )(iframe, queue)
        @iframes[i] = {iframe: iframe, queue: queue, pinger: _.throttle(f, 4000)}
      @iframes

    queueApiCall: (url) =>
      if !@iframes
        @setupApiIframes(@pluginSettings.parallel_api_calls || 3)
      @iframes[@qIndex].queue.push(url)
      @iframes[@qIndex].pinger()
      @qIndex = (@qIndex + 1) % @iframes.length
      @qIndex


    # Adds event listenrs to the mediaElement player
    #
    # Tracks events for widget loaded, play, replay, media loaded, seek, buffer
    # open full screen, close full screen, and play progress
    addListeners: =>
      @queueAnalyticEvent 1 #widget loaded

      @mediaElement.addEventListener 'play', =>
        @mediaElement.pauseObserved = false
        @mediaElement.endedObserved = false
        if @mediaElement.endedOnce
          @queueAnalyticEvent mediaId, 16 #Replay
          @mediaElement.endedOnce = false
        @queueAnalyticEvent 3 #Play

      @mediaElement.addEventListener 'canplay', =>
        @queueAnalyticEvent 2 #media loaded

      @mediaElement.addEventListener 'seeked', =>
        return if @mediaElement.endedObserved
        @queueAnalyticEvent 17 #'seek'

      @mediaElement.addEventListener 'pause', =>
        return if @mediaElement.pauseObserved
        @mediaElement.pauseObserved = true

      # first time loaded
      @mediaElement.addEventListener 'progress', =>
        if !@mediaElement.endedOnce
          @queueAnalyticEvent 12 #'progress / buffering'

      _lastTime = 0
      _isFullScreen = false
      @mediaElement.addEventListener "playing", ((e) =>
        return if @mediaElement.listeningToPlaying

        interval = setInterval(=>
          return if @mediaElement.paused or isNaN(@mediaElement.duration) or not @mediaElement.duration

          if @mediaElement.isFullScreen != _isFullScreen
            if !_isFullScreen
              @queueAnalyticEvent 14 #open full screen
            else
              @queueAnalyticEvent 15 #close full screen
            _isFullScreen = @mediaElement.isFullScreen

          stopPoints = [
            0.25 * @mediaElement.duration,
            0.5 * @mediaElement.duration,
            0.75 * @mediaElement.duration
            0.98 * @mediaElement.duration # :)
          ]
          currentTime = @mediaElement.currentTime
          if not isNaN(currentTime) and currentTime > 0
            j = stopPoints.length - 1

            while j >= 0
              cueTime = stopPoints[j]
              if cueTime > _lastTime and cueTime <= currentTime
                if j == 0
                  @queueAnalyticEvent 4 #play reached 25
                else if j == 1
                  @queueAnalyticEvent 5 #play reached 50
                else if j == 2
                  @queueAnalyticEvent 6 #play reached 75
                else if j == 3
                  @queueAnalyticEvent 7 #play reached "100"
              --j
            _lastTime = currentTime
        , 50)
        @mediaElement.listeningToPlaying = true
      ), false

  # entry method returned for using kaltura analytics
  # just give it the media id and the player and it does all setup
  (mediaId, mediaElement, pluginSettings) ->
    if pluginSettings && pluginSettings.do_analytics
      ka = new KalturaAnalytics(mediaId, mediaElement, pluginSettings)
      ka.addListeners()
      ka
