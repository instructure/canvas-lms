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
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconDownloadSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import DownloadSubmissionsDialog from './downloadSubmissionsDialog'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  downloadSubmissionsUrl: string
}
export default function SubmissionDownloadModal({downloadSubmissionsUrl}: Props) {
  const startDownload = () => {
    DownloadSubmissionsDialog(downloadSubmissionsUrl, () => {})
  }

  return (
    <>
      <Button
        color="secondary"
        onClick={startDownload}
        data-testid="download-all-submissions-button"
      >
        {I18n.t('Download all submissions')}
      </Button>
      <div id="download_submissions_dialog" style={{display: 'none'}}>
        <IconDownloadSolid />
        <View as="span" margin="0 0 0 xx-small">
          <Text weight="bold">{I18n.t('Your student submissions are being gathered')} </Text>
          {I18n.t(
            'and compressed into a zip file. This may take some time, depending on the size and number of submission files.'
          )}
        </View>
        <View as="div" className="progress" margin="small" />
        <View as="div" className="status_box" textAlign="center">
          {I18n.t('Loading')}
          <View as="span" margin="0 0 0 xx-small" className="status">
            {I18n.t('Gathering Files...')}
          </View>
        </View>
      </div>
    </>
  )
}
