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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {IconDownloadLine} from '@instructure/ui-icons'
import {FileDrop} from '@instructure/ui-file-drop'
import {Alert} from '@instructure/ui-alerts'
import SVGWrapper from '@canvas/svg-wrapper'

import {useScope as createI18nScope} from '@canvas/i18n'
import {ImportTable} from '@canvas/rubrics/react/RubricImport'
import {type RubricImport} from '@canvas/rubrics/react/types/rubric'

const I18n = createI18nScope('rubrics-import')

type ImportRubricTrayProps = {
  currentImports: RubricImport[]
  isOpen: boolean
  onClickImport: (rubricImport: RubricImport) => void
  onClose: () => void
  onImport: (file: File) => void
}

export const ImportRubricTray = ({
  currentImports,
  isOpen,
  onClickImport,
  onClose,
  onImport,
}: ImportRubricTrayProps) => {
  const handleDownloadTemplate = () => {
    const link = document.createElement('a')
    link.href = '/api/v1/rubrics/upload_template'
    link.click()
  }

  return (
    <Tray
      label={I18n.t('Import Rubrics Tray')}
      open={isOpen}
      onDismiss={onClose}
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
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
      </View>
      <View as="div" margin="small small 0">
        <Alert variant="info">
          {I18n.t('This feature requires the use of our rubric template.')}
        </Alert>
      </View>
      <View
        as="div"
        margin="medium xx-large 0"
        textAlign="center"
        overflowX="hidden"
        overflowY="hidden"
      >
        <Button
          // @ts-expect-error
          renderIcon={IconDownloadLine}
          color="secondary"
          data-testid="download-template"
          onClick={handleDownloadTemplate}
        >
          {I18n.t('Download Template')}
        </Button>
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
          <ImportTable importsInProgress={currentImports} onClickImport={onClickImport} />
        </View>
      )}
    </Tray>
  )
}
