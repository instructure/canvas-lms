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
import {debounce} from 'es-toolkit/compat'
import React from 'react'
import ReactDOM from 'react-dom'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('DiscussionToolbarView')

// #
// requires a MaterializedDiscussionTopic model
export default class DiscussionToolbarView extends View {
  static initClass() {
    // @ts-expect-error TS2339 (typescriptify)
    this.prototype.els = {
      '#discussion-search': '$searchInput',
      '#onlyUnread': '$unread',
      '#showDeleted': '$deleted',
      '.disableWhileFiltering': '$disableWhileFiltering',
    }

    // @ts-expect-error TS2339 (typescriptify)
    this.prototype.events = {
      'keyup #discussion-search': 'filterBySearch',
      'change #onlyUnread': 'toggleUnread',
      'change #showDeleted': 'toggleDeleted',
      'click #collapseAll': 'collapseAll',
      'click #expandAll': 'expandAll',
    }

    // @ts-expect-error TS2339 (typescriptify)
    this.prototype.filter = this.prototype.afterRender

    // @ts-expect-error TS2339 (typescriptify)
    this.prototype.filterBySearch = debounce(function () {
      // @ts-expect-error TS2683 (typescriptify)
      let value = this.$searchInput.val()
      if (value === '') {
        value = null
      }
      // @ts-expect-error TS2683 (typescriptify)
      this.model.set('query', value)
      // @ts-expect-error TS2683 (typescriptify)
      return this.maybeDisableFields()
    }, 250)
  }

  initialize() {
    super.initialize(...arguments)
    // @ts-expect-error TS2339 (typescriptify)
    return this.model.on('change', () => this.clearInputs())
  }

  afterRender() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.$el.find('#search_entries_container')[0]) {
      ReactDOM.render(
        <TextInput
          onChange={e => {
            // Sends events to hidden input to utilize backbone
            const hiddenInput = $('#discussion-search')
            // @ts-expect-error TS2339 (typescriptify)
            hiddenInput[0].value = e.target?.value
            hiddenInput.keyup()
          }}
          display="inline-block"
          type="text"
          placeholder={I18n.t('Search entries or author')}
          aria-label={I18n.t(
            'Search entries or author. As you type in this field, the list of discussion entries be automatically filtered to only include those whose message or author match your input.',
          )}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Search entries or author')}</ScreenReaderContent>
          }
          renderBeforeInput={() => <IconSearchLine />}
        />,
        // @ts-expect-error TS2339 (typescriptify)
        this.$el.find('#search_entries_container')[0],
      )
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.$unread.button()
    // @ts-expect-error TS2339 (typescriptify)
    return this.$deleted.button()
  }

  clearInputs = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.model.hasFilter()) return
    // @ts-expect-error TS2339 (typescriptify)
    this.$searchInput.val('')
    // @ts-expect-error TS2339 (typescriptify)
    this.$unread.prop('checked', false)
    // @ts-expect-error TS2339 (typescriptify)
    this.$unread.button('refresh')
    return this.maybeDisableFields()
  }

  toggleUnread() {
    // setTimeout so the ui can update the button before the rest
    // do expensive stuff

    return setTimeout(() => {
      // @ts-expect-error TS2339 (typescriptify)
      this.model.set('unread', this.$unread.prop('checked'))
      return this.maybeDisableFields()
    }, 50)
  }

  toggleDeleted() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.trigger('showDeleted', this.$deleted.prop('checked'))
  }

  collapseAll() {
    // @ts-expect-error TS2339 (typescriptify)
    this.model.set('collapsed', true)
    // @ts-expect-error TS2339 (typescriptify)
    return this.trigger('collapseAll')
  }

  expandAll() {
    // @ts-expect-error TS2339 (typescriptify)
    this.model.set('collapsed', false)
    // @ts-expect-error TS2339 (typescriptify)
    return this.trigger('expandAll')
  }

  maybeDisableFields() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.$disableWhileFiltering.prop('disabled', this.model.hasFilter())
  }
}
DiscussionToolbarView.initClass()
