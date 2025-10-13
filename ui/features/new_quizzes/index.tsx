/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {createRoot} from 'react-dom/client'
import ready from '@instructure/ready'
import {NewQuizzesApp} from './app/NewQuizzesApp'
import {createBrowserRouter, RouterProvider} from 'react-router-dom'
import {NewQuizzesLayout} from './layout/NewQuizzesLayout'

// Define constants for DOM element IDs
const NEW_QUIZZES_CONTAINER_ID = 'new-quizzes-root'

const NewQuizzesRoute = [
  {
    path: '*',
    element: <NewQuizzesApp />,
  },
]

const router = createBrowserRouter([
  {
    path: '/',
    element: <NewQuizzesLayout />,
    children: [...NewQuizzesRoute],
  },
])

// Start the initialization process
ready(() => {
  const root = createRoot(document.getElementById(NEW_QUIZZES_CONTAINER_ID)!)
  root.render(<RouterProvider router={router} />)
})
