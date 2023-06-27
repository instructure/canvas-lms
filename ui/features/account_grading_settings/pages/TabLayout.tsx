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
import {Outlet, useNavigate, useMatch} from 'react-router-dom'
import {Tabs} from '@instructure/ui-tabs'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradingCourseTabContainer')
const {Panel: TabsPanel} = Tabs as any

export const TabLayout = () => {
  const navigate = useNavigate()

  const pathMatch = useMatch('/accounts/:accountId/grading_settings/:tabPath/*')
  const selectedTab = pathMatch?.params?.tabPath

  const handleTabChange = (index: number) => {
    if (index === 0) {
      navigate('periods')
    } else if (index === 1) {
      navigate('schemes')
    }
  }
  if (!selectedTab) {
    // Outlet is required in order for react router to load the '/' path.
    // This oddness is due to inst-ui's approach to tabs, which requires
    // conditional inclusion of <Outlet> on only the active Tab.Panel.
    return <Outlet />
  }
  return (
    <>
      <h1>{I18n.t('Account Grading Settings')}</h1>
      <Tabs
        margin="large auto"
        padding="medium"
        onRequestTabChange={(
          event: React.MouseEvent<HTMLButtonElement, MouseEvent>,
          {index}: {index: number}
        ) => handleTabChange(index)}
      >
        <TabsPanel
          id="gradingPeriodTab"
          renderTitle={I18n.t('Grading Periods')}
          selected={selectedTab === 'periods'}
        >
          {selectedTab === 'periods' ? (
            <>
              <Outlet />
            </>
          ) : (
            <></>
          )}
        </TabsPanel>
        <TabsPanel
          id="gradingSchemeTab"
          renderTitle={I18n.t('Schemes')}
          isSelected={selectedTab === 'schemes'}
        >
          {selectedTab === 'schemes' ? (
            <>
              <Outlet />
            </>
          ) : (
            <></>
          )}
        </TabsPanel>
      </Tabs>
    </>
  )
}
