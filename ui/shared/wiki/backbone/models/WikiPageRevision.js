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
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import $ from 'jquery'
import {pick, has, omit, throttle} from 'lodash'
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'
import PandaPubPoller from '@canvas/panda-pub-poller'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'

let WikiPageRevision

const I18n = useI18nScope('pages')

const pageRevisionOptions = ['contextAssetString', 'page', 'pageUrl', 'latest', 'summary']

export default WikiPageRevision = (function () {
  WikiPageRevision = class WikiPageRevision extends Backbone.Model {
    constructor(...args) {
      super(...args)
      this.doPoll = this.doPoll.bind(this)
    }

    static initClass() {
      this.mixin(DefaultUrlMixin)
    }

    initialize(attributes, options) {
      super.initialize(...arguments)
      Object.assign(this, pick(options || {}, pageRevisionOptions))

      // the CollectionView managing the revisions "accidentally" passes in a url, so we have to nuke it here...
      if (has(this, 'url')) {
        return delete this.url
      }
    }

    urlRoot() {
      return `/api/v1/${this._contextPath()}/pages/${this.pageUrl}/revisions`
    }

    url() {
      const base = this.urlRoot()
      if (this.latest) {
        return `${base}/latest`
      }
      if (this.get('revision_id')) {
        return `${base}/${this.get('revision_id')}`
      }
      return base
    }

    fetch(options) {
      if (options == null) {
        options = {}
      }
      if (this.summary) {
        if (options.data == null) {
          options.data = {}
        }
        if (options.data.summary == null) {
          options.data.summary = true
        }
      }
      return super.fetch(options)
    }

    pollForChanges(interval) {
      if (interval == null) {
        interval = 30000
      }
      if (!this._poller) {
        // When an update arrives via pandapub, we're just going to trigger a
        // normal poll. However, updates might arrive quickly, and we don't want
        // to poll any more than the normal interval, so we created a throttled
        // version of our poll method.
        let pp
        const throttledPoll = throttle(this.doPoll, interval)

        this._poller = new PandaPubPoller(interval, interval * 10, throttledPoll)
        if ((pp = window.ENV.WIKI_PAGE_PANDAPUB)) {
          this._poller.setToken(pp.CHANNEL, pp.TOKEN)
        }
        this._poller.setOnData(() => throttledPoll())
        return this._poller.start()
      }
    }

    startPolling() {
      if (this._poller) {
        return this._poller.start()
      }
    }

    stopPolling() {
      if (this._poller) {
        return this._poller.stop()
      }
    }

    doPoll(done) {
      if (!this._poller || !this._poller.isRunning()) {
        return
      }

      return this.fetch().done(function (data, status, xhr) {
        status = xhr.status.toString()
        if (status[0] === '4' || status[0] === '5') {
          this._poller.stop()
        }

        if (done) {
          return done()
        }
      })
    }

    parse(response, _options) {
      if (response.url) {
        response.id = response.url
      }
      return response
    }

    toJSON() {
      return omit(super.toJSON(...arguments), 'id')
    }

    restore() {
      const d = $.ajaxJSON(this.url(), 'POST').fail(() =>
        $.flashError(I18n.t('restore_failed', 'Failed to restore page revision'))
      )
      $('#wiki_page_revisions').disableWhileLoading($.Deferred())
      return d
    }
  }
  WikiPageRevision.initClass()
  return WikiPageRevision
})()
