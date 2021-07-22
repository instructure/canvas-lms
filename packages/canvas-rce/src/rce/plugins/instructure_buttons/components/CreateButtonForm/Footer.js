/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import formatMessage from '../../../../../format-message'
import {StoreConsumer} from '../../../shared/StoreContext'
import {buildSvg} from '../../svg'

export const Footer = ({settings}) => {
  const [uploadInProgress, setUploadInProgress] = useState(false)

  return (
    <StoreConsumer>
      {storeProps => (
        <View as="div" padding="0 small">
          <Flex justifyItems="end">
            <Flex.Item>
              <Button
                disabled={uploadInProgress}
                color="primary"
                onClick={() => {
                  const svg = buildSvg(settings, {isPreview: false})
                  setUploadInProgress(true)

                  storeProps
                    .startButtonsAndIconsUpload({name: 'placeholder_name.svg', domElement: svg})
                    .then(() => {
                      setUploadInProgress(false)
                    })
                    .catch(() => {
                      setUploadInProgress(false)
                    })
                }}
              >
                {formatMessage('Apply')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>
      )}
    </StoreConsumer>
  )
}
