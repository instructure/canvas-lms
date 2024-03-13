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

import {View} from '@canvas/backbone'
import 'jqueryui/button'
import $ from 'jquery'
import {debounce} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('DiscussionToolbarView')

// #
// requires a MaterializedDiscussionTopic model
export default class DiscussionToolbarView extends View {
  static initClass() {
    this.prototype.els = {
      '#discussion-search': '$searchInput',
      '#onlyUnread': '$unread',
      '#showDeleted': '$deleted',
      '.disableWhileFiltering': '$disableWhileFiltering',
    }

    this.prototype.events = {
      'keyup #discussion-search': 'filterBySearch',
      'change #onlyUnread': 'toggleUnread',
      'change #showDeleted': 'toggleDeleted',
      'click #collapseAll': 'collapseAll',
      'click #expandAll': 'expandAll',
    }

    this.prototype.filter = this.prototype.afterRender

    this.prototype.filterBySearch = debounce(function () {
      let value = this.$searchInput.val()
      if (value === '') {
        value = null
      }
      this.model.set('query', value)
      return this.maybeDisableFields()
    }, 250)
  }

  initialize() {
    super.initialize(...arguments)
    return this.model.on('change', () => this.clearInputs())
  }

  afterRender() {
    if (this.$el.find('#search_entries_container')[0]) {
      ReactDOM.render(
        <TextInput
          onChange={e => {
            // Sends events to hidden input to utilize backbone
            const hiddenInput = $('#discussion-search')
            hiddenInput[0].value = e.target?.value
            hiddenInput.keyup()
          }}
          display="inline-block"
          type="text"
          placeholder={I18n.t('Search entries or author')}
          aria-label={I18n.t(
            'Search entries or author. As you type in this field, the list of discussion entries be automatically filtered to only include those whose message or author match your input.'
          )}
          renderBeforeInput={() => <IconSearchLine />}
        />,
        this.$el.find('#search_entries_container')[0]
      )
    }
    this.$unread.button()
    return this.$deleted.button()
  }

  clearInputs = () => {
    if (this.model.hasFilter()) return
    this.$searchInput.val('')
    this.$unread.prop('checked', false)
    this.$unread.button('refresh')
    return this.maybeDisableFields()
  }

  toggleUnread() {
    // setTimeout so the ui can update the button before the rest
    // do expensive stuff

    return setTimeout(() => {
      this.model.set('unread', this.$unread.prop('checked'))
      return this.maybeDisableFields()
    }, 50)
  }

  toggleDeleted() {
    return this.trigger('showDeleted', this.$deleted.prop('checked'))
  }

  collapseAll() {
    this.model.set('collapsed', true)
    return this.trigger('collapseAll')
  }

  expandAll() {
    this.model.set('collapsed', false)
    return this.trigger('expandAll')
  }

  maybeDisableFields() {
    return this.$disableWhileFiltering.prop('disabled', this.model.hasFilter())
  }
}
DiscussionToolbarView.initClass()
