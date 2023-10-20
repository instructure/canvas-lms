/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {BrowserRouter, HashRouter, Routes, Route} from 'react-router-dom'

import AnswerMatrixRoute from './routes/answer_matrix'
import AppRoute from './routes/app'
import EventStreamRoute from './routes/event_stream'
import QuestionRoute from './routes/question'

export default function App(props) {
  const matches = window.location.pathname.match(/(.*\/log)/)
  const baseUrl = (matches && matches[0]) || ''
  const Router = props.useHashRouter ? HashRouter : BrowserRouter

  return (
    <Router basename={baseUrl}>
      <Routes>
        <Route
          path="/questions/:id"
          element={
            <AppRoute>
              <QuestionRoute {...props} />
            </AppRoute>
          }
        />

        <Route
          path="/answer_matrix"
          element={
            <AppRoute>
              <AnswerMatrixRoute {...props} />
            </AppRoute>
          }
        />

        <Route
          path="/"
          element={
            <AppRoute>
              <EventStreamRoute {...props} />
            </AppRoute>
          }
        />

        <Route path="*" element={<AppRoute />} />
      </Routes>
    </Router>
  )
}
