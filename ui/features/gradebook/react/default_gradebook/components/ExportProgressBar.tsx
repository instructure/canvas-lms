/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import GradebookExportManager from '../../shared/GradebookExportManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Transition} from '@instructure/ui-motion'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('gradebookExport')

export type ExportProgressBarProps = {
  exportState?: {
    filename?: string
    completion?: number
  }
  exportManager?: GradebookExportManager
}

export const ExportProgressBar = ({exportState, exportManager}: ExportProgressBarProps) => {
  const {completion, filename = ''} = exportState || {}

  const isOpen = () => {
    return completion !== undefined
  }

  const cancelExport = () => {
    if (exportManager) {
      exportManager.cancelExport()
      $.flashWarning(I18n.t('Your gradebook export has been cancelled'))
    }
  }

  const isCancelDisabled = () => {
    return (completion ?? 0) >= 100
  }

  return (
    <Transition in={isOpen()} type="scale" unmountOnExit={true}>
      <View as="div" padding="0 0 medium 0" data-testid="export-progress-bar">
        <Text weight="bold">{I18n.t('Exporting %{filename}', {filename})}</Text>
        <ProgressBar
          screenReaderLabel={I18n.t('Upload Percent Complete')}
          formatScreenReaderValue={({valueNow, valueMax}) => {
            const percentDone = Math.round((valueNow / valueMax) * 100)
            return I18n.t('%{percentDone} percent', {percentDone})
          }}
          valueMax={100}
          valueNow={completion || 0}
          renderValue={({valueNow, valueMax}) => {
            return (
              <Text weight="bold">
                {I18n.n(Math.round((valueNow / valueMax) * 100), {percentage: true})}
                <CloseButton
                  disabled={isCancelDisabled()}
                  size="medium"
                  screenReaderLabel={I18n.t('Close')}
                  onClick={cancelExport}
                />
              </Text>
            )
          }}
        />
      </View>
    </Transition>
  )
}
