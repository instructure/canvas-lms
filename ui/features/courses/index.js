/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import ready from '@instructure/ready'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {Pill} from '@instructure/ui-pill'
import {clearDashboardCache} from '../../shared/dashboard-card/dashboardCardQueries'

const I18n = createI18nScope('courses.show')

ready(() => {
  const params = new URLSearchParams(window.location.search)
  const sortingTable = params.get('focus')
  if (sortingTable) {
    const sortingCol = params.get(sortingTable + '_sort')
    const focusedHeader = document.querySelector('a#' + sortingTable + '_' + sortingCol)
    if (focusedHeader) focusedHeader.focus()
  }
  if (ENV?.FEATURES?.dashboard_graphql_integration) {
    addFavoriteClickListener()
  }

  if (ENV?.FEATURES?.accessibility_tab_enable) {
    renderAccessibilityCells()
  }
})

function addFavoriteClickListener() {
  document
    .querySelectorAll('.course-list-favoritable, .course-list-favorite-course')
    .forEach(element => {
      element.addEventListener('click', handleFavoriteCourseClick)
    })
}

function handleFavoriteCourseClick() {
  clearDashboardCache()
}

function renderAccessibilityCells() {
  // Issue count pills
  document.querySelectorAll('.status-pill').forEach(element => {
    createRoot(element).render(
      React.createElement(
        Pill,
        {
          color: 'warning',
          themeOverride: componentTheme => {
            return {
              background: componentTheme.warningColor,
              warningColor: 'white',
            }
          },
        },
        [element.textContent],
      ),
    )
  })

  // Accessibility checking spinners
  document.querySelectorAll('.course-list-checking-spinner').forEach(element => {
    createRoot(element).render(
      React.createElement(
        PresentationContent,
        null,
        React.createElement(Spinner, {
          as: 'div',
          renderTitle: I18n.t('Checking course accessibility...'),
          size: 'x-small',
        }),
      ),
    )
  })
}
