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
import {Navigate, Route, redirect} from 'react-router-dom'
import getCookie from '@instructure/get-cookie'

export const LearnerPassportAdminRoutes = (
  <Route path="/users/:userId/passport">
    <Route path="admin" lazy={() => import('../pages/admin/AdminLayout')}>
      <Route path="" element={<Navigate to="pathways" replace={true} />} />
      <Route path="pathways">
        <Route path="" element={<Navigate to="dashboard" replace={true} />} />
        <Route
          path="dashboard"
          lazy={() => import('../pages/admin/PathwayDashboard')}
          loader={async ({params}) => {
            return fetch(`/users/${params.userId}/passport/data/pathways`)
          }}
        />
        <Route
          path="view/:pathwayId"
          loader={async ({params}) => {
            return fetch(
              `/users/${params.userId}/passport/data/pathways/show/${params.pathwayId}?include=all`
            )
          }}
          lazy={() => import('../pages/admin/PathwayView')}
        />
        <Route
          path="edit/:pathwayId"
          loader={async ({params}) => {
            const p1 = fetch(`/users/${params.userId}/passport/data/pathways/badges`).then(res =>
              res.json()
            )
            const p2 = fetch(`/users/${params.userId}/passport/data/pathways/learner_groups`).then(
              res => res.json()
            )
            const p3 = fetch(
              `/users/${params.userId}/passport/data/pathways/show/${params.pathwayId}`
            ).then(res => res.json())

            const [badges, learner_groups, pathway] = await Promise.all([p1, p2, p3])
            return {badges, learner_groups, pathway}
          }}
          action={async ({request, params}) => {
            const formData = await request.formData()
            const response = await fetch(
              `/users/${params.userId}/passport/data/pathways/${params.pathwayId}`,
              {
                method: 'POST',
                cache: 'no-cache',
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                },
                body: formData,
              }
            )
            const json = await response.json()
            if (formData.get('draft') === 'true') {
              return redirect('.')
            } else {
              return redirect(`../view/${json.id}`)
            }
          }}
          lazy={() => import('../pages/admin/PathwayEdit')}
        />
      </Route>
      <Route
        path="achievements/dashboard"
        lazy={() => import('../pages/admin/AchievementsDashboard')}
      />
      <Route
        path="learner_records/dashboard"
        lazy={() => import('../pages/admin/LearnerRecordsDashboard')}
      />
      <Route
        path="institution_settings/dashboard"
        lazy={() => import('../pages/admin/InstitutionSettingsDashboard')}
      />
    </Route>
  </Route>
)
