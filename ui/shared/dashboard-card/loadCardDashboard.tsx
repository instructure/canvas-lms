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
import getDroppableDashboardCardBox from './react/getDroppableDashboardCardBox'
import DashboardCard from './react/DashboardCard'
import axios from '@canvas/axios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {asJson, checkStatus, getPrefetchedXHR} from '@canvas/util/xhr'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Card} from './types'

const I18n = useI18nScope('load_card_dashboard')

export function createDashboardCards(
  dashboardCards: Card[],
  cardComponent = DashboardCard,
  extraProps: any
) {
  const Box = getDroppableDashboardCardBox()

  // Decide which dashboard to show based on role
  const isTeacher = dashboardCards.some((card: Card) => card.enrollmentType === 'TeacherEnrollment')

  return (
    <Box
      showSplitDashboardView={isTeacher}
      courseCards={dashboardCards}
      hideColorOverlays={window.ENV?.PREFERENCES?.hide_dashcard_color_overlays}
      cardComponent={cardComponent}
      {...extraProps}
    />
  )
}
export class CardDashboardLoader {
  static observedUsersDashboardCards: Record<string, Card[]> = {}

  errorShown = false

  observedUserId?: string = undefined

  promiseToGetDashboardCards?: Promise<Card[]> = undefined

  renderIntoDOM = (dashboardCards: Card[]) => {
    const dashboardContainer = document.getElementById('DashboardCard_Container')
    ReactDOM.render(
      createDashboardCards(dashboardCards, DashboardCard, {observedUserId: this.observedUserId}),
      dashboardContainer
    )
  }

  loadCardDashboard(renderFn = this.renderIntoDOM, observedUserId: string) {
    if (observedUserId) {
      this.observedUserId = observedUserId
    }

    if (observedUserId && CardDashboardLoader.observedUsersDashboardCards[observedUserId]) {
      // @ts-expect-error
      renderFn(CardDashboardLoader.observedUsersDashboardCards[observedUserId], true)
    } else if (this.promiseToGetDashboardCards) {
      this.promiseToGetDashboardCards
        .then(cards => {
          // @ts-expect-error
          renderFn(cards, true)
        })
        .catch(e => {
          this.showError(e)
        })
    } else {
      let xhrHasReturned = false
      let sessionStorageTimeout: number
      const sessionStorageKey = `dashcards_for_user_${ENV && ENV.current_user_id}`
      const urlPrefix = '/api/v1/dashboard/dashboard_cards'
      const url = new URL(urlPrefix, window.location.origin)
      if (observedUserId) {
        url.searchParams.append('observed_user_id', observedUserId)
      }
      const urlString = url.toString()
      this.promiseToGetDashboardCards =
        asJson(getPrefetchedXHR(urlString)) ||
        axios
          .get(urlString)
          // @ts-expect-error
          .then(checkStatus)
          // @ts-expect-error
          .then(({data}) => data)
          .catch(e => {
            this.showError(e)
          })
      this.promiseToGetDashboardCards
        .then(() => (xhrHasReturned = true))
        .catch(e => {
          this.showError(e)
        })

      // Because we use prefetch_xhr to prefetch this xhr request from our rails erb, there is a
      // chance that the XHR to get the latest dashcard data has already come back before we get
      // to this point. So if the XHR is ready, there's no need to render twice, just render
      // once with the newest data.
      // Otherwise, render with the cached stuff from session storage now, then render again
      // when the xhr comes back with the latest data.
      const promiseToGetCardsFromSessionStorage = new Promise(resolve => {
        sessionStorageTimeout = setTimeout(() => {
          const cachedCards = sessionStorage.getItem(sessionStorageKey)
          if (cachedCards) resolve(JSON.parse(cachedCards))
        }, 1) as unknown as number
      })
      Promise.race([this.promiseToGetDashboardCards, promiseToGetCardsFromSessionStorage])
        .then(dashboardCards => {
          clearTimeout(sessionStorageTimeout)
          // calling the renderFn with `false` indicates to consumers that we're still waiting
          // on the follow-up xhr request to complete.
          // @ts-expect-error
          renderFn(dashboardCards, xhrHasReturned)
          // calling it with `true` indicates that all outstanding card promises have settled.
          if (!xhrHasReturned && this.promiseToGetDashboardCards)
            // @ts-expect-error
            return this.promiseToGetDashboardCards.then((cards: Card[]) => renderFn(cards, true))
        })
        .catch(e => {
          this.showError(e)
        })

      // Cache the fetched dashcards in sessionStorage so we can render instantly next
      // time they come to their dashboard (while still fetching the most current data)
      // Also save the observed user's cards if observing so observer can switch between students
      // without any delay
      this.promiseToGetDashboardCards
        .then((dashboardCards: Card[]) => {
          try {
            sessionStorage.setItem(sessionStorageKey, JSON.stringify(dashboardCards))
          } catch (_e) {
            // If saving the cards to session storage fails, we can just ignore the exception; the cards
            // will still be fetched and displayed on the next load. Telling the user probably doesn't
            // make sense since it doesn't change the way the app works, nor does it make sense to log
            // the error since it could happen in normal circumstances (like using Safari in private mode).
          }
          if (observedUserId) {
            CardDashboardLoader.observedUsersDashboardCards[observedUserId] = dashboardCards
          }
        })
        .catch((e: Error) => {
          this.showError(e)
        })
    }
  }

  showError(e: Error) {
    if (!this.errorShown) {
      this.errorShown = true
      showFlashAlert({message: I18n.t('Failed loading course cards'), err: e, type: 'error'})
    }
  }
}

// Clears the cache for use in test suites
export function resetCardCache() {
  CardDashboardLoader.observedUsersDashboardCards = {}
}
