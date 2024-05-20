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

import $ from 'jquery'
import {extend, pick} from 'lodash'
import Backbone from '@canvas/backbone'
import {raw} from '@instructure/html-escape'

const pageReloadOptions = ['reloadMessage', 'warning', 'interval']

export default class WikiPageReloadView extends Backbone.View {
  static initClass() {
    this.prototype.setViewProperties = false

    this.prototype.defaults = {
      modelAttributes: ['title', 'url', 'body'],
      warning: false,
    }

    this.prototype.events = {'click a.reload': 'reload'}
  }

  template() {
    return `<div class='alert alert-${raw(
      this.options.warning ? 'warning' : 'info'
    )} reload-changed-page'>${raw(this.reloadMessage)}</div>`
  }

  initialize(options) {
    super.initialize(...arguments)
    return extend(this, pick(options || {}, pageReloadOptions))
  }

  pollForChanges() {
    if (!this.model) return

    const view = this
    const {model} = this
    const latestRevision = (this.latestRevision = model.latestRevision())
    if (latestRevision && !model.isNew()) {
      latestRevision.on('change:revision_id', () =>
        // when the revision changes, query the full record
        latestRevision.fetch({data: {summary: false}}).done(() => {
          view.render()
          view.trigger('changed')
          return view.stopPolling()
        })
      )

      return latestRevision.pollForChanges(this.interval)
    }
  }

  stopPolling() {
    return this.latestRevision != null ? this.latestRevision.stopPolling() : undefined
  }

  reload(ev) {
    if (ev != null) {
      ev.preventDefault()
    }
    this.model.set(pick(this.latestRevision.attributes, this.options.modelAttributes))
    this.trigger('reload')
    return this.latestRevision.startPolling()
  }
}
WikiPageReloadView.initClass()
