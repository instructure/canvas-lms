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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-file-drop'
import SVGWrapper from '@canvas/svg-wrapper'
import useStore from '../stores'

import {useScope as createI18nScope} from '@canvas/i18n'
import type {RubricAssessmentImportResponse} from '../queries/Queries'
import {RubricAssessmentImportTable} from './RubricAssessmentImportTable'

const I18n = createI18nScope('rubrics-import')

type RubricAssessmentImportTrayProps = {
  currentImports: RubricAssessmentImportResponse[]
  onClickImport: (rubricImport: any) => void
  onImport: (file: File) => void
}

export const RubricAssessmentImportTray = ({
  currentImports,
  onClickImport,
  onImport,
}: RubricAssessmentImportTrayProps) => {
  const {rubricAssessmentImportTrayProps, toggleRubricAssessmentImportTray} = useStore()

  const {isOpen, assignment} = rubricAssessmentImportTrayProps

  const closeTray = () => {
    toggleRubricAssessmentImportTray(false)
  }

  if (!assignment) {
    return null
  }

  return (
    <Tray
      label={I18n.t('Import Rubrics')}
      open={isOpen}
      onDismiss={closeTray}
      placement="end"
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" margin="mediumSmall 0 0 medium" data-testid="import-rubric-tray">
        <Heading level="h3">{I18n.t('Import Rubrics')}</Heading>
      </View>
      <View as="div" margin="medium medium 0 0">
        <CloseButton
          size="medium"
          placement="end"
          onClick={closeTray}
          screenReaderLabel={I18n.t('Close')}
        />
      </View>
      <View as="div" margin="large small 0">
        <Text>
          {I18n.t('Import rubric assessments to ')}
          <Text weight="bold">&quot;{assignment.name}&quot;</Text>
        </Text>
      </View>
      <View as="div" height="410px" margin="large small 0">
        <FileDrop
          height="100%"
          width="100%"
          display="inline-block"
          accept=".csv"
          onDropAccepted={accepted => {
            onImport(accepted[0] as File)
          }}
          renderLabel={
            <View
              as="div"
              padding="small"
              margin="large small 0"
              textAlign="center"
              background="primary"
              data-testid="rubric-import-file-drop"
            >
              <View as="div" margin="x-large">
                <SVGWrapper url="/images/UploadFile.svg" />
              </View>
              <View as="div">
                <Text size="large" lineHeight="double">
                  {I18n.t('Drag a file here, or')}
                </Text>
              </View>
              <View as="div">
                <Text size="medium" color="brand" lineHeight="double">
                  {I18n.t('Choose a file to upload')}
                </Text>
              </View>
            </View>
          }
        />
      </View>
      {currentImports.length > 0 && (
        <View as="div" margin="medium xx-small 0">
          <RubricAssessmentImportTable
            importsInProgress={currentImports}
            onClickImport={onClickImport}
          />
        </View>
      )}
    </Tray>
  )
}
