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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {InstUISettingsProvider} from '@instructure/emotion'
import {colors} from '@instructure/canvas-theme'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownSolid, IconSettingsLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import GradebookMenu from '@canvas/gradebook-menu/react/GradebookMenu'
import {View} from '@instructure/ui-view'
import {ExportCSVButton} from './ExportCSVButton'
import {SettingsTray} from './SettingsTray'
import {GradebookSettings} from '@canvas/outcomes/react/utils/constants'
import {mapSettingsToFilters} from '@canvas/outcomes/react/utils/filter'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('LearningMasteryGradebook')

const componentOverrides = {
  Link: {
    color: colors.contrasts.grey125125,
  },
}

export interface ToolbarProps {
  courseId: string
  contextURL?: string
  showDataDependentControls?: boolean
  gradebookSettings: GradebookSettings
  setGradebookSettings: (settings: GradebookSettings) => Promise<{success: boolean}>
  isSavingSettings?: boolean
  hideHeading?: boolean
}

export const Toolbar: React.FC<ToolbarProps> = ({
  courseId,
  contextURL,
  showDataDependentControls,
  gradebookSettings,
  setGradebookSettings,
  isSavingSettings,
  hideHeading,
}) => {
  const [isSettingsTrayOpen, setSettingsTrayOpen] = useState<boolean>(false)

  return (
    <InstUISettingsProvider theme={{componentOverrides}}>
      <Flex
        height="100%"
        display="flex"
        alignItems="center"
        justifyItems="space-between"
        padding="medium 0 0 0"
        data-testid="lmgb-menu-and-settings"
        wrap="wrap"
      >
        <Flex alignItems="center" data-testid="lmgb-gradebook-menu">
          {!hideHeading && <Heading level="h1">{I18n.t('Learning Mastery Gradebook')}</Heading>}
          <View padding="xx-small">
            <GradebookMenu
              courseUrl={contextURL ?? ''}
              learningMasteryEnabled={true}
              variant="DefaultGradebookLearningMastery"
              customTrigger={
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  screenReaderLabel={I18n.t('Gradebook Menu Dropdown')}
                >
                  <IconArrowOpenDownSolid size="x-small" />
                </IconButton>
              }
            />
          </View>
        </Flex>
        {showDataDependentControls && (
          <Flex gap="small" alignItems="stretch" direction="row">
            <ExportCSVButton
              courseId={courseId}
              gradebookFilters={mapSettingsToFilters(gradebookSettings)}
            />
            <View as="div" borderWidth="none small none none" width="0px" />
            <IconButton
              withBorder={false}
              withBackground={false}
              screenReaderLabel={I18n.t('Settings')}
              data-testid="lmgb-settings-button"
              onClick={() => setSettingsTrayOpen(true)}
            >
              <IconSettingsLine size="x-small" />
            </IconButton>
            <SettingsTray
              open={isSettingsTrayOpen}
              onDismiss={() => setSettingsTrayOpen(false)}
              gradebookSettings={gradebookSettings}
              setGradebookSettings={setGradebookSettings}
              isSavingSettings={isSavingSettings}
            />
          </Flex>
        )}
      </Flex>
    </InstUISettingsProvider>
  )
}
