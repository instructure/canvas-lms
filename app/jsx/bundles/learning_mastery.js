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

import Gradebook from 'compiled/gradebook/Gradebook'
import OutcomeGradebookView from 'compiled/views/gradebook/OutcomeGradebookView'
import Paginator from '../shared/components/Paginator'

import('jsx/context_cards/StudentContextCardTrigger')

const gradebook = new Gradebook({
  ...ENV.GRADEBOOK_OPTIONS,
  currentUserId: ENV.current_user_id,
  locale: ENV.LOCALE
})
gradebook.initialize()

const outcome = new OutcomeGradebookView({
  el: $('.outcome-gradebook'),
  gradebook,
  router: {
    renderPagination
  }
})

outcome.render()
renderPagination(0, 0)
outcome.onShow()

function renderPagination(page, pageCount) {
  ReactDOM.render(
    <Paginator page={page} pageCount={pageCount} loadPage={p => outcome.loadPage(p)} />,
    document.getElementById('outcome-gradebook-paginator')
  )
}
