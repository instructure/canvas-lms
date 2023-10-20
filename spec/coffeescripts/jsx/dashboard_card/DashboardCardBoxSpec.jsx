/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {DragDropContext} from 'react-dnd'
import ReactDndTestBackend from 'react-dnd-test-backend'
import sinon from 'sinon'
import {waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import DashboardCard from '@canvas/dashboard-card/react/DashboardCard'
import getDroppableDashboardCardBox from '@canvas/dashboard-card/react/getDroppableDashboardCardBox'
import CourseActivitySummaryStore from '@canvas/dashboard-card/react/CourseActivitySummaryStore'
import fakeENV from 'helpers/fakeENV'

QUnit.module('DashboardCardBox', suiteHooks => {
  let $container
  let props
  let server

  suiteHooks.beforeEach(() => {
    fakeENV.setup()
    $container = document.createElement('div')
    document.body.appendChild($container)

    props = {
      cardComponent: DashboardCard,
      courseCards: [
        {
          id: '1',
          isFavorited: true,
          courseName: 'Bio 101',
          assetString: 'course_1',
        },
        {
          id: '2',
          isFavorited: true,
          courseName: 'Philosophy 201',
          assetString: 'course_1',
        },
      ],
    }

    fetchMock.put(/\/api\/v1\/users\/1\/colors\/.*/, {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: '',
    })

    server = sinon.fakeServer.create({respondImmediately: true})
    return sandbox.stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})
  })

  suiteHooks.afterEach(async () => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
    server.restore()
    fakeENV.teardown()
  })

  function mountComponent() {
    const Box = getDroppableDashboardCardBox(DragDropContext(ReactDndTestBackend))
    const CardBox = <Box connectDropTarget={el => el} ref={() => {}} {...props} />
    ReactDOM.render(CardBox, $container)
  }

  function getDashboardBoxElement() {
    return document.querySelector('.ic-DashboardCard__box')
  }

  function getSplitDashboardElement() {
    return document.querySelector('.unpublished_courses_redesign')
  }

  function getDashboardCardElements() {
    return [...getDashboardBoxElement().querySelectorAll('.ic-DashboardCard')]
  }

  function getDashboardBoxHeaders() {
    return [...document.querySelectorAll('.ic-DashboardCard__box__header')]
  }

  function getPopoverButton(card) {
    return card.querySelector('.icon-more')
  }

  function getMoveTab() {
    return [...document.querySelectorAll('[role="tab"]')].find($tab =>
      $tab.textContent.includes('Move')
    )
  }

  function getDashboardMenu() {
    return document.querySelector('[aria-label="Dashboard Card Movement Menu"]')
  }

  function getUnfavoriteButton() {
    return [...getDashboardMenu().querySelectorAll('.DashboardCardMenu__MovementItem')].find(
      $button => $button.textContent.includes('Unfavorite')
    )
  }

  function getModal() {
    return document.querySelector('[aria-label="Confirm unfavorite course"]')
  }

  function getSubmitButton() {
    return [...getModal().querySelectorAll('Button')].find($button =>
      $button.textContent.includes('Submit')
    )
  }

  function removeCardFromFavorites(card) {
    getPopoverButton(card).click()
    getMoveTab().click()
    getUnfavoriteButton().click()
    getSubmitButton().click()
  }

  async function getNoFavoritesAlert() {
    const noFavoritesAlert = await getDashboardBoxElement().querySelector(
      '.no-favorites-alert-container'
    )
    return noFavoritesAlert
  }

  QUnit.module('#render()', () => {
    test('should render div.ic-DashboardCard per provided courseCard', () => {
      mountComponent()
      const cards = getDashboardCardElements()
      strictEqual(cards.length, props.courseCards.length)
    })

    test('should render a header for both published/unpublished courses in split view', () => {
      props.showSplitDashboardView = true
      mountComponent()
      const headers = getDashboardBoxHeaders()
      strictEqual(headers.length, 2)
    })

    test('correctly splits course cards into published and unpublished in split view', () => {
      props.courseCards = [
        {...props.courseCards[0], published: false},
        {...props.courseCards[1], published: true},
      ]
      props.showSplitDashboardView = true
      mountComponent()
      const headers = getDashboardBoxHeaders()
      ok(headers[0].textContent.includes('Published Courses (1)'))
      ok(headers[1].textContent.includes('Unpublished Courses (1)'))
    })

    test('correctly renders empty headers in split view', () => {
      props.courseCards = []
      props.showSplitDashboardView = true
      mountComponent()
      const dashboardBox = getSplitDashboardElement()
      ok(dashboardBox.textContent.includes('No courses to display'))
    })
  })

  QUnit.module('#handleRerenderCards', () => {
    test('removes unfavorited card from dashboard cards', async () => {
      function waitForRerender(card) {
        if (!card.isFavorited) {
          return true
        }
      }

      mountComponent()
      const card = getDashboardCardElements()[0]
      const url = '/api/v1/users/self/favorites/courses/1'
      server.respondWith('DELETE', url, [200, {}, ''])
      server.respond()

      removeCardFromFavorites(card)
      await waitFor(() => waitForRerender(card))

      const rerendered = getDashboardCardElements()
      strictEqual(rerendered.length, 1)
    })

    test('shows no favorites alert when last course is unfavorited', () => {
      props.courseCards = [props.courseCards[0]]
      mountComponent()
      const card = getDashboardCardElements()[0]
      removeCardFromFavorites(card)
      ok(getNoFavoritesAlert())
    })
  })
})
