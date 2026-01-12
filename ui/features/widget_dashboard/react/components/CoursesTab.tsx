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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {createDashboardCards} from '../../../../shared/dashboard-card/loadCardDashboard'
import DashboardCard from '../../../../shared/dashboard-card/react/DashboardCard'
import DashboardCardBackgroundStore from '../../../../shared/dashboard-card/react/DashboardCardBackgroundStore'
import type {Card} from '../../../../shared/dashboard-card/types'

const I18n = createI18nScope('widget_dashboard')

const CoursesTab: React.FC = () => {
  const [dashboardCards, setDashboardCards] = useState<Card[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const loadDashboardCards = async () => {
      try {
        const response = await fetch('/api/v1/dashboard/dashboard_cards')
        if (!response.ok) {
          throw new Error('Failed to fetch dashboard cards')
        }
        const cards = await response.json()
        setDashboardCards(cards)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error occurred')
      } finally {
        setLoading(false)
      }
    }

    loadDashboardCards()
  }, [])

  useEffect(() => {
    if (dashboardCards.length > 0 && containerRef.current) {
      try {
        const courseAssetStrings = dashboardCards.map(card => card.assetString)
        DashboardCardBackgroundStore.setDefaultColors(courseAssetStrings)

        const dashboardCardsElement = createDashboardCards(dashboardCards, DashboardCard, {})

        containerRef.current.innerHTML = ''
        if (React.isValidElement(dashboardCardsElement)) {
          import('@canvas/react').then(({render}) => {
            render(dashboardCardsElement, containerRef.current!)
          })
        }
      } catch (err) {
        console.error('Error rendering dashboard cards:', err)
        setError("Cards couldn't load")
      }
    }
  }, [dashboardCards])

  if (loading) {
    return (
      <View as="div" padding="medium" data-testid="courses-tab-content">
        <Heading level="h2" margin="0 0 medium" data-testid="courses-tab-heading">
          {I18n.t('Courses')}
        </Heading>
        <View as="div" textAlign="center" margin="large 0">
          <Spinner renderTitle={I18n.t('Loading courses')} size="large" />
        </View>
      </View>
    )
  }

  if (error) {
    return (
      <View as="div" padding="medium" data-testid="courses-tab-content">
        <Heading level="h2" margin="0 0 medium" data-testid="courses-tab-heading">
          {I18n.t('Courses')}
        </Heading>
        <Text color="danger">{I18n.t("Courses couldn't load right now")}</Text>
      </View>
    )
  }

  if (dashboardCards.length === 0) {
    return (
      <View as="div" padding="medium" data-testid="courses-tab-content">
        <Text data-testid="no-courses-message">{I18n.t("You don't have any courses yet")}</Text>
      </View>
    )
  }

  return (
    <View as="div" padding="medium" data-testid="courses-tab-content">
      <View as="div" margin="medium 0 0">
        <div ref={containerRef} />
      </View>
    </View>
  )
}

export default CoursesTab
