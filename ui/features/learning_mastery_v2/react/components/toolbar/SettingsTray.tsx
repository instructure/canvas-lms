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

import React, {useCallback, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {GradebookSettings} from '../../utils/constants'
import {SecondaryInfoSelector} from './SecondaryInfoSelector'
import {DisplayFilterSelector} from './DisplayFilterSelector'
import {ScoreDisplayFormatSelector} from './ScoreDisplayFormatSelector'
import {OutcomeArrangementSelector} from './OutcomeArrangementSelector'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface SettingsTrayProps {
  open: boolean
  onDismiss: () => void
  gradebookSettings: GradebookSettings
  setGradebookSettings: (settings: GradebookSettings) => Promise<{success: boolean}>
  isSavingSettings?: boolean
}

export const SettingsTray: React.FC<SettingsTrayProps> = ({
  open,
  onDismiss,
  gradebookSettings,
  setGradebookSettings,
  isSavingSettings = false,
}) => {
  const [secondaryInfoDisplay, setSecondaryInfoDisplay] = useState(
    gradebookSettings.secondaryInfoDisplay,
  )
  const [displayFilters, setDisplayFilters] = useState(gradebookSettings.displayFilters)
  const [scoreDisplayFormat, setScoreDisplayFormat] = useState(gradebookSettings.scoreDisplayFormat)
  const [outcomeArrangement, setOutcomeArrangement] = useState(gradebookSettings.outcomeArrangement)

  const resetForm = useCallback(() => {
    setSecondaryInfoDisplay(gradebookSettings.secondaryInfoDisplay)
    setDisplayFilters(gradebookSettings.displayFilters)
    setScoreDisplayFormat(gradebookSettings.scoreDisplayFormat)
    setOutcomeArrangement(gradebookSettings.outcomeArrangement)
  }, [
    gradebookSettings.secondaryInfoDisplay,
    gradebookSettings.displayFilters,
    gradebookSettings.scoreDisplayFormat,
    gradebookSettings.outcomeArrangement,
  ])

  const saveSettings = async () => {
    const newSettings = {
      ...gradebookSettings,
      secondaryInfoDisplay,
      displayFilters,
      scoreDisplayFormat,
      outcomeArrangement,
    }

    const result = await setGradebookSettings(newSettings)

    if (result?.success) {
      onDismiss()
      showFlashAlert({type: 'success', message: I18n.t('Your settings have been saved.')})
    } else {
      resetForm()
      showFlashAlert({
        type: 'error',
        message: I18n.t('There was an error saving your settings. Please try again.'),
      })
    }
  }

  return (
    <Tray
      label={I18n.t('Settings Tray')}
      placement="end"
      size="small"
      open={open}
      onDismiss={onDismiss}
      data-testid="lmgb-settings-tray"
    >
      <Flex direction="column" padding="medium">
        <Flex alignItems="center" justifyItems="space-between" data-testid="lmgb-settings-header">
          <Text size="x-large" weight="bold">
            {I18n.t('Settings')}
          </Text>
          <CloseButton
            size="medium"
            screenReaderLabel={I18n.t('Close Settings Tray')}
            onClick={onDismiss}
            data-testid="lmgb-close-settings-button"
          />
        </Flex>
        <hr style={{marginBottom: '0', marginTop: '16px'}} />
      </Flex>
      <Flex direction="column" padding="small medium" alignItems="stretch" gap="medium">
        <SecondaryInfoSelector
          value={secondaryInfoDisplay}
          onChange={info => setSecondaryInfoDisplay(info)}
        />
        <DisplayFilterSelector
          values={displayFilters}
          onChange={filters => setDisplayFilters(filters)}
        />
        <ScoreDisplayFormatSelector
          value={scoreDisplayFormat}
          onChange={format => setScoreDisplayFormat(format)}
        />
        <OutcomeArrangementSelector
          value={outcomeArrangement}
          onChange={arrangement => setOutcomeArrangement(arrangement)}
        />
        <Flex gap="small" alignItems="stretch" direction="column">
          <Button color="primary" onClick={saveSettings} disabled={isSavingSettings}>
            {I18n.t('Apply')}
          </Button>
          <Button
            withBackground={false}
            onClick={() => {
              resetForm()
              onDismiss()
            }}
            themeOverride={{borderWidth: '0px'}}
          >
            {I18n.t('Cancel')}
          </Button>
        </Flex>
      </Flex>
    </Tray>
  )
}
