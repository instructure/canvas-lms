#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'Backbone'
  'i18n!pages'
  '../backbone-ext/DefaultUrlMixin'
  '../str/splitAssetString'
  '../util/PandaPubPoller'
  '../jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
], ($, _, Backbone, I18n, DefaultUrlMixin, splitAssetString, PandaPubPoller) ->

  pageRevisionOptions = ['contextAssetString', 'page', 'pageUrl', 'latest', 'summary']

  class WikiPageRevision extends Backbone.Model
    @mixin DefaultUrlMixin

    initialize: (attributes, options) ->
      super
      _.extend(this, _.pick(options || {}, pageRevisionOptions))

      # the CollectionView managing the revisions "accidentally" passes in a url, so we have to nuke it here...
      delete @url if _.has(@, 'url')

    urlRoot: ->
      "/api/v1/#{@_contextPath()}/pages/#{@pageUrl}/revisions"

    url: ->
      base = @urlRoot()
      return "#{base}/latest" if @latest
      return "#{base}/#{@get('revision_id')}" if @get('revision_id')
      return base

    fetch: (options={}) ->
      if @summary
        options.data ?= {}
        options.data.summary ?= true
      super options

    pollForChanges: (interval=30000) ->
      unless @_poller

        # When an update arrives via pandapub, we're just going to trigger a
        # normal poll. However, updates might arrive quickly, and we don't want
        # to poll any more than the normal interval, so we created a throttled
        # version of our poll method.
        throttledPoll = _.throttle @doPoll, interval

        @_poller = new PandaPubPoller interval, interval * 10, throttledPoll
        if pp = window.ENV.WIKI_PAGE_PANDAPUB
          @_poller.setToken pp.CHANNEL , pp.TOKEN
        @_poller.setOnData => throttledPoll()
        @_poller.start()

    startPolling: ->
      @_poller.start() if @_poller

    stopPolling: ->
      @_poller.stop() if @_poller

    doPoll: (done) =>
      return unless @_poller and @_poller.isRunning()

      @fetch().done (data, status, xhr) ->
        status = xhr.status.toString()
        if status[0] == '4' || status[0] == '5'
          @_poller.stop()

        done() if done

    parse: (response, options) ->
      response.id = response.url if response.url
      response

    toJSON: ->
      _.omit super, 'id'

    restore: ->
      d = $.ajaxJSON(@url(), 'POST').fail ->
        $.flashError I18n.t 'restore_failed', 'Failed to restore page revision'
      $('#wiki_page_revisions').disableWhileLoading($.Deferred())
      d
