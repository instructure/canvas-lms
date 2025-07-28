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

import React, {lazy, Suspense} from 'react'
import {AUPLayout} from '../layouts/AUPLayout'
import {Route} from 'react-router-dom'
import {Spinner} from '@instructure/ui-spinner'

const AcceptableUsePolicy = lazy(() => import('../components/AcceptableUsePolicy'))

export const AUPRoutes = (
  <Route
    path="/acceptable_use_policy"
    element={
      <AUPLayout>
        <Suspense fallback={<Spinner renderTitle="Loading page" />}>
          <AcceptableUsePolicy />
        </Suspense>
      </AUPLayout>
    }
  />
)
