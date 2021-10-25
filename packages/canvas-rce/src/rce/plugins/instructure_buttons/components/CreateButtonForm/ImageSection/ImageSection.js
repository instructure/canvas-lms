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

import React, {useReducer, useState} from 'react'

import formatMessage from '../../../../../../format-message'
import reducer, {initialState, modes} from '../../../reducers/imageSection'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Group} from '../Group'
import ModeSelect from './ModeSelect'
import Course from './Course'
import PreviewIcon from '../../../../shared/PreviewIcon'
import {ImageCropper} from '../ImageCropper'
import {IconCropSolid} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton} from '@instructure/ui-buttons'

export const ImageSection = () => {
  const [openCropModal, setOpenCropModal] = useState(false)
  const [state, dispatch] = useReducer(reducer, initialState)
  const allowedModes = {[modes.courseImages.type]: Course}

  return (
    <Group as="section" defaultExpanded summary={formatMessage('Image')}>
      <Flex direction="column" margin="small">
        <Flex.Item>
          <Text weight="bold">{formatMessage('Current Image')}</Text>
        </Flex.Item>
        <Flex.Item>
          <Flex>
            <Flex.Item shouldGrow>
              <Flex>
                <Flex.Item margin="0 small 0 0">
                  <PreviewIcon variant="large" testId="selected-image-preview" />
                </Flex.Item>
                <Flex.Item>
                  <Text>{!state.currentImage && formatMessage('None Selected')}</Text>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item>
              <ModeSelect dispatch={dispatch} />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          {!!allowedModes[state.mode] && React.createElement(allowedModes[state.mode])}
        </Flex.Item>
        <Flex.Item>
          <Button
            renderIcon={IconCropSolid}
            onClick={() => {
              setOpenCropModal(true)
            }}
          />
          {openCropModal && (
            <Modal
              size="large"
              open={openCropModal}
              onDismiss={() => {
                setOpenCropModal(false)
              }}
              shouldCloseOnDocumentClick={false}
            >
              <Modal.Header>
                <CloseButton
                  placement="end"
                  offset="small"
                  onClick={() => {
                    setOpenCropModal(false)
                  }}
                  screenReaderLabel="Close"
                />
                <Heading>{formatMessage('Crop Image')}</Heading>
              </Modal.Header>
              <Modal.Body>
                <ImageCropper />
              </Modal.Body>
              <Modal.Footer>
                <Button
                  onClick={() => {
                    setOpenCropModal(false)
                  }}
                  margin="0 x-small 0 0"
                >
                  {formatMessage('Cancel')}
                </Button>
                <Button color="primary" type="submit">
                  {formatMessage('Save')}
                </Button>
              </Modal.Footer>
            </Modal>
          )}
        </Flex.Item>
      </Flex>
    </Group>
  )
}
