/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import '@canvas/jquery/jquery.ajaxJSON'

import OutcomeGradebookView from '../backbone/views/OutcomeGradebookView'
import GradebookMenu from '@canvas/gradebook-menu'
import Paginator from '@canvas/instui-bindings/react/Paginator'

function normalizeSections(options) {
  const sections = options.sections || []
  return sections.sort((a, b) => a.id - b.id)
}

function currentSectionIdFromSettings(settings) {
  return settings?.filter_rows_by?.section_id || null
}

export default class LearningMastery {
  constructor(options) {
    this.options = options

    this.view = new OutcomeGradebookView({
      el: $('.outcome-gradebook'),
      learningMastery: this,
    })

    this.data = {
      currentSectionId: currentSectionIdFromSettings(options.settings),
      sections: normalizeSections(options),
    }
  }

  getSections() {
    return this.data.sections
  }

  getCurrentSectionId() {
    return this.data.currentSectionId
  }

  updateCurrentSectionId(_sectionId) {
    // As of this writing, the section filter returns '0' for "All Sections"
    const sectionId = _sectionId === '0' ? null : _sectionId
    const currentSectionId = this.getCurrentSectionId()

    if (currentSectionId !== sectionId) {
      this._setCurrentSectionId(sectionId)
      this.saveSettings()
    }
  }

  renderPagination(page = 0, pageCount = 0) {
    const loadPage = this.view.loadPage.bind(this.view)
    ReactDOM.render(
      <Paginator page={page} pageCount={pageCount} loadPage={loadPage} />,
      document.getElementById('outcome-gradebook-paginator')
    )
  }

  saveSettings() {
    const data = {
      gradebook_settings: {
        filter_rows_by: {
          section_id: this.getCurrentSectionId(),
        },
      },
    }

    $.ajaxJSON(this.options.settings_update_url, 'PUT', data)
  }

  start() {
    this.view.render()
    this._renderGradebookMenu()
    this.renderPagination()
    this.view.onShow()
  }

  destroy() {
    this.view.remove()
    ReactDOM.unmountComponentAtNode(document.querySelector('[data-component="GradebookMenu"]'))
    ReactDOM.unmountComponentAtNode(document.getElementById('outcome-gradebook-paginator'))
  }

  // PRIVATE

  _renderGradebookMenu() {
    // This only needs to render once.
    const $container = document.querySelector('[data-component="GradebookMenu"]')
    const props = {
      courseUrl: this.options.context_url,
      learningMasteryEnabled: true,
      enhancedIndividualGradebookEnabled: Boolean(
        ENV.GRADEBOOK_OPTIONS.individual_gradebook_enhancements
      ),
      variant: 'DefaultGradebookLearningMastery',
    }
    ReactDOM.render(<GradebookMenu {...props} />, $container)
  }

  _setCurrentSectionId(sectionId) {
    this.data.currentSectionId = sectionId
  }
}
