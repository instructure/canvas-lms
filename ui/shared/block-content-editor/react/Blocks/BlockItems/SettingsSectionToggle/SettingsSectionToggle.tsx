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

import {ToggleGroup} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import './settings-section-toggle.css'

export type SettingsSectionToggleProps = {
  title: string
  defaultExpanded?: boolean
  includeSeparator: boolean
  children: React.ReactNode
}

export const SettingsSectionToggle = ({
  title,
  defaultExpanded,
  includeSeparator,
  children,
}: SettingsSectionToggleProps) => {
  return (
    <>
      <ToggleGroup
        defaultExpanded={defaultExpanded}
        border={false}
        transition={false}
        toggleLabel={title}
        summary={
          <Heading variant="titleCardMini" level="h3">
            {title}
          </Heading>
        }
        data-settingssectiontoggle
        themeOverride={{
          borderColor: 'transparent',
        }}
      >
        <View as="div" padding="small 0 0 0">
          {children}
        </View>
      </ToggleGroup>
      {includeSeparator && <View as="hr" borderWidth="0 0 small 0" />}
    </>
  )
}
