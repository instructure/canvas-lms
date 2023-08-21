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

import React, {useState, useEffect} from 'react'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
// @ts-expect-error
import {IconModuleSolid} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export interface DifferentiatedModulesTrayProps {
  open: boolean
  onDismiss: () => void
  initialTab?: 'settings' | 'assign-to'
  assignOnly?: boolean
}

const SettingsPanel = React.lazy(() => import('./SettingsPanel'))
const AssignToPanel = React.lazy(() => import('./AssignToPanel'))

export default function DifferentiatedModulesTray({
  open,
  onDismiss,
  initialTab = 'assign-to',
  assignOnly = true,
}: DifferentiatedModulesTrayProps) {
  const [selectedTab, setSelectedTab] = useState(initialTab)

  useEffect(() => {
    if (!open) setSelectedTab(initialTab)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  function Header() {
    return (
      <View as="div" padding="small">
        <Flex as="div" margin="0 0 medium 0">
          <FlexItem>
            <CloseButton onClick={onDismiss} screenReaderLabel={I18n.t('Close')} placement="end" />
          </FlexItem>
          <FlexItem>
            <IconModuleSolid size="x-small" />
          </FlexItem>
          <FlexItem margin="0 0 0 small">
            <Heading as="h3">{I18n.t('Edit Module Settings')}</Heading>
          </FlexItem>
        </Flex>
      </View>
    )
  }

  function Fallback() {
    return (
      <View as="div" textAlign="center" size="large">
        <Spinner renderTitle={I18n.t('Loading...')} />
      </View>
    )
  }

  function Body() {
    return (
      <React.Suspense fallback={<Fallback />}>
        {assignOnly ? (
          <AssignToPanel />
        ) : (
          <Tabs
            onRequestTabChange={(_e: Event, {id}: {id: 'settings' | 'assign-to'}) =>
              setSelectedTab(id)
            }
          >
            <Tabs.Panel
              id="settings"
              data-testid="settings-panel"
              renderTitle={I18n.t('Settings')}
              isSelected={selectedTab === 'settings'}
            >
              <SettingsPanel />
            </Tabs.Panel>
            <Tabs.Panel
              id="assign-to"
              data-testid="assign-to-panel"
              renderTitle={I18n.t('Assign To')}
              isSelected={selectedTab === 'assign-to'}
            >
              <AssignToPanel />
            </Tabs.Panel>
          </Tabs>
        )}
      </React.Suspense>
    )
  }

  return (
    <Tray open={open} label={I18n.t('Edit Module Settings')} placement="end" size="regular">
      <Header />
      <Body />
    </Tray>
  )
}
