/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import * as apiClient from './apiClient'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import ReactDOM from 'react-dom'
import SVGWrapper from '@canvas/svg-wrapper'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import {Billboard} from '@instructure/ui-billboard'
import {FileDrop} from '@instructure/ui-file-drop'
import {Link} from '@instructure/ui-link'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('groups')

export default function ImportGroupsModal(props) {
  const [messages, setMessages] = useState([])

  const hide = () => {
    if (props.parent) ReactDOM.unmountComponentAtNode(props.parent)
  }

  const beginUpload = file => {
    if (file !== null) {
      apiClient
        .createImport(props.groupCategoryId, file)
        .then(resp => {
          props.setProgress(resp.data)
        })
        .catch(() => {
          showFlashAlert({
            type: 'error',
            message: I18n.t('There was an error uploading your file. Please try again.'),
          })
        })
    }
  }

  const onSelection = (accepted, rejected) => {
    if (accepted.length > 0) {
      beginUpload(accepted[0])
      hide()
    } else if (rejected.length > 0) {
      setMessages([{text: I18n.t('Invalid file type'), type: 'error'}])
    }
  }

  const styles = {
    width: '10rem',
    margin: '0 auto',
  }

  return (
    <CanvasModal size="fullscreen" label={I18n.t('Import Groups')} open={true} onDismiss={hide}>
      <FileDrop
        accept=".csv"
        onDrop={(acceptedFile, rejectedFile) => onSelection(acceptedFile, rejectedFile)}
        messages={messages}
        renderLabel={
          <div>
            <Billboard
              size="medium"
              heading={I18n.t('Upload CSV File')}
              headingLevel="h2"
              message={I18n.t('Drag and drop or click to browse your computer')}
              hero={
                <div style={styles}>
                  <PresentationContent>
                    <SVGWrapper url="/images/upload_rocket.svg" />
                  </PresentationContent>
                </div>
              }
            />
          </div>
        }
      />
      <View as="div" margin="large auto xx-small auto" textAlign="center">
        <Link href={`/api/v1/group_categories/${props.groupCategoryId}/export`}>
          {I18n.t('Download Course Roster CSV')}
        </Link>
      </View>
      <View as="div" textAlign="center">
        <Text>
          {I18n.t('To assign students to a group, enter group names in the "group_name" column.')}
        </Text>
      </View>
      <View as="div" margin="large auto" textAlign="center">
        <Link href="/doc/api/file.group_category_csv.html" target="_blank">
          {I18n.t('Group Import API Documentation')}
        </Link>
      </View>
    </CanvasModal>
  )
}
