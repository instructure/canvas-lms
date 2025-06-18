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

import DashboardHeader, {observerMode} from './DashboardHeader'

import {useFetchDashboardCards} from '../../../shared/dashboard-card/dashboardCardQueries'

import {handleDashboardCardError} from '../../../shared/dashboard-card/util/dashboardUtils'
import type {Card} from '@canvas/dashboard-card/types'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'

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
  const [cards, setCards] = useState<Card[]>([])

  const observedUserID =
    // @ts-expect-error
    observerMode() && ENV.OBSERVED_USERS_LIST.length > 0 ? savedObservedId(userID) : null

  const {
    data: dashCardData,
    isSuccess: dashCardSuccess,
    isError: isDashCardError,
    error: dashCardError,
    refetch: refetchDashboardCards,
  } = useFetchDashboardCards(userID, observedUserID ?? null)

  useEffect(() => {
    if (dashCardSuccess && dashCardData) {
      try {
        setCards(dashCardData)
        setIsReady(true)
      } catch (err) {
        handleDashboardCardError(err as Error)
      }
    } else if (isDashCardError) {
      handleDashboardCardError(dashCardError as Error)
    }
  }, [isDashCardError, dashCardData, dashCardError, dashCardSuccess])

  if (!isReady) {
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
      preloadedCards={cards}
      refetchDashboardCards={refetchDashboardCards}
    />
  )
}

export default DashboardWrapper
