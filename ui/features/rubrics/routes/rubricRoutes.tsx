/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Route} from 'react-router-dom'

export const RubricRoutes = (
  <>
    <Route path="/accounts/:accountId/rubrics" lazy={() => import('../pages/ViewRubrics')} />,
    <Route path="/accounts/:accountId/rubrics/create" lazy={() => import('../pages/RubricForm')} />,
    <Route
      path="/accounts/:accountId/rubrics/:rubricId"
      lazy={() => import('../pages/RubricForm')}
    />
    <Route path="/courses/:courseId/rubrics" lazy={() => import('../pages/ViewRubrics')} />,
    <Route path="/courses/:courseId/rubrics/create" lazy={() => import('../pages/RubricForm')} />,
    <Route path="/courses/:courseId/rubrics/:rubricId" lazy={() => import('../pages/RubricForm')} />
  </>
)
