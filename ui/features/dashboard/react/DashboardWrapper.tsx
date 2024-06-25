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

import React, {useEffect, useState} from 'react'
// eslint-disable-next-line import/no-named-as-default
import DashboardHeader, {observerMode} from './DashboardHeader'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

import {observedUserId} from '../../../shared/planner/utilities/apiUtils'
import {useFetchDashboardCards} from '../../../shared/dashboard-card/dashboardCardQueries'

import {mapDashboardResponseToCard} from '../../../shared/dashboard-card/util/dashboardUtils'
import type {Card} from '@canvas/dashboard-card/types'

const I18n = useI18nScope('load_card_dashboard')

// TODO: update types from any to something more specific
interface DashboardWrapperProps {
  dashboard_view: string
  allowElementaryDashboard: boolean
  isElementaryUser: boolean
  planner_enabled: boolean
  flashError: any
  flashMessage: any
  screenReaderFlashMessage: any
  env: any
  props: any
}

const DashboardWrapper = ({
  dashboard_view,
  allowElementaryDashboard,
  isElementaryUser,
  planner_enabled,
  flashError,
  flashMessage,
  screenReaderFlashMessage,
  env,
  props,
}: DashboardWrapperProps) => {
  const userID = ENV.current_user_id
  const [isReady, setIsReady] = useState(false)
  const [mappedCards, setMappedCards] = useState<Card[]>([])

  const observedUserID = observerMode() ? observedUserId() : null

  const {
    data: dashCardData,
    isFetching: dashCardFetching,
    isError: isDashCardError,
    error: dashCardError,
  } = useFetchDashboardCards(userID, observedUserID)

  const handleError = (e: Error) => {
    showFlashAlert({message: I18n.t('Failed loading course cards'), err: e, type: 'error'})
  }

  useEffect(() => {
    if (!dashCardFetching && !isDashCardError && dashCardData) {
      try {
        const mapped = mapDashboardResponseToCard(dashCardData)
        setMappedCards(mapped)
        setIsReady(true)
      } catch (err) {
        handleError(err)
      }
    } else if (isDashCardError && dashCardError instanceof Error) {
      handleError(dashCardError)
    }
  }, [dashCardFetching, isDashCardError, dashCardData, dashCardError])

  if (!isReady || !mappedCards.length) {
    return null
  }

  return (
    <DashboardHeader
      dashboard_view={dashboard_view}
      allowElementaryDashboard={allowElementaryDashboard}
      isElementaryUser={isElementaryUser}
      planner_enabled={planner_enabled}
      flashError={flashError}
      flashMessage={flashMessage}
      screenReaderFlashMessage={screenReaderFlashMessage}
      env={env}
      {...props}
      preloadedCards={mappedCards}
    />
  )
}

export default DashboardWrapper
