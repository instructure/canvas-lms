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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tabs} from '@instructure/ui-tabs'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {ViewOwnProps} from '@instructure/ui-view'
import type {Breakpoints} from '@canvas/with-breakpoints'

const I18n = useI18nScope('discussion_create')

export enum Views {
  Details = 0,
  MasteryPaths = 1,
}

export const DiscussionTopicFormViewSelector = ({
  selectedView,
  setSelectedView,
  breakpoints,
  shouldMasteryPathsBeVisible,
  shouldMasteryPathsBeEnabled,
}: {
  selectedView: number
  setSelectedView: (view: number) => void
  breakpoints: Breakpoints
  shouldMasteryPathsBeVisible: boolean
  shouldMasteryPathsBeEnabled: boolean
}) => {
  const handleTabChange = (
    event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>,
    tabData: {index: number; id?: string}
  ) => {
    setSelectedView(tabData.index)
  }

  const renderTabs = () => {
    return (
      <Tabs onRequestTabChange={handleTabChange}>
        <Tabs.Panel
          isSelected={selectedView === Views.Details}
          renderTitle={I18n.t('Details')}
          textAlign="center"
        />
        {shouldMasteryPathsBeVisible && (
          <Tabs.Panel
            isSelected={selectedView === Views.MasteryPaths}
            renderTitle={I18n.t('Mastery Paths')}
            isDisabled={!shouldMasteryPathsBeEnabled}
            textAlign="center"
          />
        )}
      </Tabs>
    )
  }

  const renderSelect = () => {
    return (
      <Flex.Item margin="0 0 medium 0">
        <SimpleSelect
          value={selectedView}
          onChange={(e, {value}) => {
            if (Number.isInteger(value)) {
              setSelectedView(value as number)
            }
          }}
          renderLabel={<ScreenReaderContent>{I18n.t('Select View')}</ScreenReaderContent>}
          data-testid="view-select"
        >
          <SimpleSelect.Group renderLabel={I18n.t('View')} key="view-group">
            <SimpleSelect.Option id="details" key={Views.Details} value={Views.Details}>
              {I18n.t('Details')}
            </SimpleSelect.Option>
            {shouldMasteryPathsBeVisible ? (
              <SimpleSelect.Option
                id="mastery-paths"
                key={Views.MasteryPaths}
                value={Views.MasteryPaths}
                isDisabled={!shouldMasteryPathsBeEnabled}
              >
                {I18n.t('Mastery Paths')}
              </SimpleSelect.Option>
            ) : (
              <></>
            )}
          </SimpleSelect.Group>
        </SimpleSelect>
      </Flex.Item>
    )
  }

  return <>{breakpoints.mobileOnly ? renderSelect() : renderTabs()}</>
}
