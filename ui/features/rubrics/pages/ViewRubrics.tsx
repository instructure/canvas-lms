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

import React, {useRef, useState} from 'react'
import {useParams} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import ProficiencyTable from '@canvas/rubrics/react/components/ProficiencyTable'
import {Portal} from '@instructure/ui-portal'
import {Tabs} from '@instructure/ui-tabs'
import {ViewRubrics} from '../components/ViewRubrics'
import {ApolloProvider, createClient} from '@canvas/apollo'
import {RubricBreadcrumbs} from '../components/RubricBreadcrumbs'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('ViewRubrics')

export const Component = () => {
  const [breadcrumbMountPoint] = React.useState(
    document.querySelector('.ic-app-crumbs-enhanced-rubrics')
  )
  const {accountId} = useParams()

  React.useEffect(() => {
    if (breadcrumbMountPoint) {
      breadcrumbMountPoint.innerHTML = ''
    }
  }, [breadcrumbMountPoint])

  const mountPoint: HTMLElement | null = document.querySelector('#content')
  if (!mountPoint) {
    return null
  }

  const showTabbedView = () => {
    return (
      ENV.FEATURES.non_scoring_rubrics &&
      ENV.PERMISSIONS?.manage_outcomes &&
      !ENV.FEATURES.account_level_mastery_scales
    )
  }

  return (
    <>
      <Portal open={true} mountNode={breadcrumbMountPoint}>
        <RubricBreadcrumbs breadcrumbs={ENV.breadcrumbs} />
      </Portal>
      <Portal open={true} mountNode={mountPoint}>
        <ApolloProvider client={createClient()}>
          {!!accountId && showTabbedView() ? (
            <>
              <Heading level="h1" themeOverride={{h1FontWeight: 700}} margin="medium 0 large 0">
                {I18n.t('Rubrics')}
              </Heading>
              <TabbedView accountId={accountId} />
            </>
          ) : (
            <ViewRubrics canManageRubrics={ENV.PERMISSIONS?.manage_rubrics} />
          )}
        </ApolloProvider>
      </Portal>
    </>
  )
}

type TabbedViewProps = {
  accountId: string
}
const TabbedView = ({accountId}: TabbedViewProps) => {
  const [tab, setTab] = useState('tab-panel-rubrics')
  const masteryTab = useRef<HTMLElement>()

  const handleTabChange = (id?: string) => {
    setTab(id ?? 'tab-panel-rubrics')
  }

  const focusMasteryTab = () => {
    if (masteryTab.current) masteryTab.current.focus()
  }

  return (
    <Tabs onRequestTabChange={(_event: any, {id}) => handleTabChange(id)}>
      <Tabs.Panel
        renderTitle={I18n.t('Account Rubrics')}
        id="tab-panel-rubrics"
        isSelected={tab === 'tab-panel-rubrics'}
      >
        <View as="div" margin="small 0 0 0">
          <ViewRubrics canManageRubrics={ENV.PERMISSIONS?.manage_rubrics} showHeader={false} />
        </View>
      </Tabs.Panel>
      <Tabs.Panel
        renderTitle={I18n.t('Learning Mastery')}
        id="tab-panel-mastery"
        isSelected={tab === 'tab-panel-mastery'}
        elementRef={ref => {
          if (ref instanceof HTMLElement) {
            masteryTab.current = ref
          }
        }}
      >
        <ProficiencyTable focusTab={focusMasteryTab} accountId={accountId} />
      </Tabs.Panel>
    </Tabs>
  )
}
