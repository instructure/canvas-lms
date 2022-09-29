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
import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/WikiPageRevision.handlebars'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'

const I18n = useI18nScope('pages')

export default class WikiPageRevisionView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'li'
    this.prototype.className = 'revision clearfix'
    this.prototype.template = template

    this.prototype.events = {
      'click .restore-link': 'restore',
      'keydown .restore-link': 'restore',
    }

    this.prototype.els = {'.revision-details': '$revisionButton'}
  }

  initialize() {
    super.initialize(...arguments)
    return this.model.on('change', () => this.render())
  }

  render() {
    const hadFocus = this.$revisionButton != null ? this.$revisionButton.is(':focus') : undefined
    super.render(...arguments)
    if (hadFocus) {
      return this.$revisionButton.focus()
    }
  }

  afterRender() {
    super.afterRender(...arguments)
    this.$el.toggleClass('selected', !!this.model.get('selected'))
    return this.$el.toggleClass('latest', !!this.model.get('latest'))
  }

  toJSON() {
    const latest = this.model.collection != null ? this.model.collection.latest : undefined
    const json = {
      ...super.toJSON(...arguments),
      IS: {
        LATEST: !!this.model.get('latest'),
        SELECTED: !!this.model.get('selected'),
        LOADED: !!this.model.get('title') && !!this.model.get('body'),
      },
    }
    json.IS.SAME_AS_LATEST =
      json.IS.LOADED &&
      this.model.get('title') === (latest != null ? latest.get('title') : undefined) &&
      this.model.get('body') === (latest != null ? latest.get('body') : undefined)
    json.updated_at = $.datetimeString(json.updated_at)
    json.edited_by = json.edited_by != null ? json.edited_by.display_name : undefined
    return json
  }

  windowLocation() {
    return window.location
  }

  async restore(ev) {
    const restore = await showConfirmationDialog({
      label: I18n.t('Confirm Restore'),
      body: I18n.t('Are you sure you want to restore this revision?'),
      confirmText: I18n.t('Restore'),
    })

    if (!restore) return

    if ((ev != null ? ev.type : undefined) === 'keydown') {
      if (ev.keyCode !== 13) return
    }
    if (ev != null) {
      ev.preventDefault()
    }
    return this.model.restore().done(attrs => {
      if (this.pages_path) {
        return (this.windowLocation().href = `${this.pages_path}/${attrs.url}/revisions`)
      } else {
        return this.windowLocation().reload()
      }
    })
  }
}
WikiPageRevisionView.initClass()
