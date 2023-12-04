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

export const LearnerPassportRoutes = (
  <Route path="/users/:userId/passport" lazy={() => import('../pages/LearnerPassportLayout')}>
    <Route path="" element={<Navigate to="achievements" replace={true} />} />
    <Route
      path="achievements"
      lazy={() => import('../pages/Achievements')}
      loader={({params}) => {
        return fetch(`/users/${params.userId}/passport/data/achievements`)
      }}
    />

    <Route path="portfolios" lazy={() => import('../pages/Portfolios')}>
      <Route
        path="dashboard"
        lazy={() => import('../pages/PortfolioDashboard')}
        loader={async ({params}) => {
          return fetch(`/users/${params.userId}/passport/data/portfolios`)
        }}
      >
        <Route
          path="duplicate/:portfolioId"
          loader={async ({params}) => {
            await fetch(`/users/${params.userId}/passport/data/portfolios/duplicate`, {
              method: 'PUT',
              cache: 'no-cache',
              headers: {
                'X-CSRF-Token': getCookie('_csrf_token'),
                'Content-type': 'application/json',
              },
              body: JSON.stringify({portfolio_id: params.portfolioId}),
            })
            return redirect('..')
          }}
        />
        <Route
          path="delete/:portfolioId"
          loader={async ({params}) => {
            await fetch(`/users/${params.userId}/passport/data/portfolios/delete`, {
              method: 'PUT',
              cache: 'no-cache',
              headers: {
                'X-CSRF-Token': getCookie('_csrf_token'),
                'Content-type': 'application/json',
              },
              body: JSON.stringify({portfolio_id: params.portfolioId}),
            })
            return redirect('..')
          }}
        />
        <Route
          path="create"
          action={async ({request}) => {
            const formData = await request.formData()
            const response = await fetch(
              `/users/${formData.get('userId')}/passport/data/portfolios/create`,
              {
                method: 'PUT',
                cache: 'no-cache',
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                  'Content-type': 'application/json',
                },
                body: JSON.stringify({title: formData.get('title')}),
              }
            )
            const json = await response.json()
            return redirect(`../../edit/${json.id}`)
          }}
        />
        <Route
          path="rename"
          action={async ({request}) => {
            const formData = await request.formData()
            await fetch(
              `/users/${formData.get('userId')}/passport/data/portfolios/${formData.get('id')}`,
              {
                method: 'POST',
                cache: 'no-cache',
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                  'Content-type': 'application/json',
                },
                body: JSON.stringify({title: formData.get('title')}),
              }
            )
            return redirect('..')
          }}
        />
      </Route>
      <Route
        path="view/:portfolioId"
        loader={async ({params}) => {
          return fetch(
            `/users/${params.userId}/passport/data/portfolios/show/${params.portfolioId}`
          )
        }}
        lazy={() => import('../pages/PortfolioView')}
      />
      <Route
        path="edit/:portfolioId"
        loader={async ({params}) => {
          const p1 = fetch(`/users/${params.userId}/passport/data/achievements`).then(res =>
            res.json()
          )
          const p2 = fetch(
            `/users/${params.userId}/passport/data/portfolios/show/${params.portfolioId}`
          ).then(res => res.json())
          const [achievements, portfolio] = await Promise.all([p1, p2])
          return {achievements, portfolio}
        }}
        action={async ({request, params}) => {
          const formData = await request.formData()
          const response = await fetch(
            `/users/${params.userId}/passport/data/portfolios/${params.portfolioId}`,
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
          return redirect(`../view/${json.id}`)
        }}
        lazy={() => import('../pages/PortfolioEdit')}
      />
    </Route>

    <Route path="projects" lazy={() => import('../pages/Projects')}>
      <Route
        path="dashboard"
        lazy={() => import('../pages/ProjectDashboard')}
        loader={async ({params}) => {
          return fetch(`/users/${params.userId}/passport/data/projects`)
        }}
      >
        <Route
          path="duplicate/:projectId"
          loader={async ({params}) => {
            await fetch(`/users/${params.userId}/passport/data/projects/duplicate`, {
              method: 'PUT',
              cache: 'no-cache',
              headers: {
                'X-CSRF-Token': getCookie('_csrf_token'),
                'Content-type': 'application/json',
              },
              body: JSON.stringify({project_id: params.projectId}),
            })
            return redirect('..')
          }}
        />
        <Route
          path="delete/:projectId"
          loader={async ({params}) => {
            await fetch(`/users/${params.userId}/passport/data/projects/delete`, {
              method: 'PUT',
              cache: 'no-cache',
              headers: {
                'X-CSRF-Token': getCookie('_csrf_token'),
                'Content-type': 'application/json',
              },
              body: JSON.stringify({project_id: params.projectId}),
            })
            return redirect('..')
          }}
        />
        <Route
          path="create"
          action={async ({request}) => {
            const formData = await request.formData()
            const response = await fetch(
              `/users/${formData.get('userId')}/passport/data/projects/create`,
              {
                method: 'PUT',
                cache: 'no-cache',
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                  'Content-type': 'application/json',
                },
                body: JSON.stringify({title: formData.get('title')}),
              }
            )
            const json = await response.json()
            return redirect(`../../edit/${json.id}`)
          }}
        />
        <Route
          path="rename"
          action={async ({request}) => {
            const formData = await request.formData()
            await fetch(
              `/users/${formData.get('userId')}/passport/data/projects/${formData.get('id')}`,
              {
                method: 'POST',
                cache: 'no-cache',
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                  'Content-type': 'application/json',
                },
                body: JSON.stringify({title: formData.get('title')}),
              }
            )
            return redirect('..')
          }}
        />
      </Route>
      <Route
        path="view/:projectId"
        loader={async ({params}) => {
          return fetch(`/users/${params.userId}/passport/data/projects/show/${params.projectId}`)
        }}
        lazy={() => import('../pages/ProjectView')}
      />
      <Route
        path="edit/:projectId"
        loader={async ({params}) => {
          const p1 = fetch(`/users/${params.userId}/passport/data/achievements`).then(res =>
            res.json()
          )
          const p2 = fetch(
            `/users/${params.userId}/passport/data/projects/show/${params.projectId}`
          ).then(res => res.json())
          const [achievements, project] = await Promise.all([p1, p2])
          return {achievements, project}
        }}
        action={async ({request, params}) => {
          const formData = await request.formData()
          const response = await fetch(
            `/users/${params.userId}/passport/data/projects/${params.projectId}`,
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
          return redirect(`../view/${json.id}`)
        }}
        lazy={() => import('../pages/ProjectEdit')}
      />
    </Route>
  </Route>
)
