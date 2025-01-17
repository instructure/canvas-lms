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

import React from 'react'
import {createRoot} from 'react-dom/client'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/RestoreContentPane.handlebars'
import {EntitySearchForm} from '../../react/EntitySearchForm'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('restore_content_pane')

const accountId = ENV.ACCOUNT_ID

export default class RestoreContentPaneView extends Backbone.View {
  static initClass() {
    this.child('courseSearchResultsView', '#courseSearchResults')
    this.child('userSearchResultsView', '#userSearchResults')

    this.prototype.events = {'change #restoreType': 'onTypeChange'}

    this.prototype.template = template
  }

  constructor(options) {
    super(...arguments)
    this.permissions = this.options.permissions
    this.currentProps = null
    const courseModel = options.courseSearchResultsView.model
    const userModel = options.userSearchResultsView.model
    this.renderConfig = {
      user: {
        title: I18n.t('Restore Users'),
        inputConfig: {
          label: I18n.t('Search for a deleted user by ID'),
          placeholder: I18n.t('User ID'),
        },
        onSubmit: async entityId => {
          try {
            await userModel.search(entityId)
          } finally {
            this.showSearchResult('#userRestore')
          }
        },
      },
      course: {
        title: I18n.t('Restore Courses'),
        inputConfig: {
          label: I18n.t('Search for a deleted course by ID'),
          placeholder: I18n.t('Course ID'),
        },
        onSubmit: async entityId => {
          try {
            await courseModel.search(entityId)
          } finally {
            this.showSearchResult('#courseRestore')
          }
        },
      },
    }
    this.subscribeToRestoreState(courseModel)
    this.subscribeToRestoreState(userModel)
  }

  subscribeToRestoreState(model) {
    model.on('restoring', () => {
      this.renderSearchForm({...this.currentProps, isDisabled: true})
    })
    model.on('doneRestoring', () => {
      this.renderSearchForm({...this.currentProps, isDisabled: false})
    })
  }

  hideSearchResults() {
    this.$el.find('.restoreTypeContent').hide()
  }

  showSearchResult(selector) {
    this.$el.find(selector).show()
  }

  afterRender() {
    this.hideSearchResults()
  }

  renderSearchForm(props) {
    if (!this.root) {
      const mountPoint = document.getElementById('entity_search_mount_point')
      const root = createRoot(mountPoint)

      this.root = root
    }

    this.root.render(<EntitySearchForm {...props} />)
  }

  unmountSearchForm() {
    if (!this.root) {
      return
    }

    this.root.unmount()
    this.root = null
  }

  toJSON() {
    return {...this.permissions}
  }

  onTypeChange(event) {
    this.hideSearchResults()

    const $target = $(event.target)
    const selectedOption = $target.val()
    const props = this.renderConfig[selectedOption]
    this.currentProps = props

    this.renderSearchForm(props)
  }
}
RestoreContentPaneView.initClass()
