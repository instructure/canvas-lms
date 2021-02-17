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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!MoveOutcomesModal'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import Modal from '../../shared/components/InstuiModal'
import TreeBrowser from './TreeBrowser'
import {useGroupMoveModal} from 'jsx/outcomes/shared/treeBrowser'
import {useCanvasContext} from '../shared/hooks'

const noop = () => {}

const MoveModal = ({title, type, isOpen, onCloseHandler}) => {
  const {error, isLoading, collections, queryCollections, rootId} = useGroupMoveModal()
  const {contextType} = useCanvasContext()

  return (
    <Modal
      open={isOpen}
      onDismiss={onCloseHandler}
      shouldReturnFocus
      size="medium"
      overflow="scroll"
      label={I18n.t('Move "%{title}"', {title})}
    >
      <Modal.Body>
        <View as="div" maxHeight="450px" height="450px" position="static">
          <Text size="medium" weight="bold">
            {type === 'outcome'
              ? I18n.t('Where would you like to move this outcome?')
              : I18n.t('Where would you like to move this group?')}
          </Text>
          <View as="div">
            {isLoading ? (
              <div style={{textAlign: 'center'}}>
                <Spinner renderTitle={I18n.t('Loading')} size="large" />
              </div>
            ) : error ? (
              <Text color="danger">
                {contextType === 'Course'
                  ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
                  : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
              </Text>
            ) : (
              <TreeBrowser
                onCollectionToggle={queryCollections}
                collections={collections}
                rootId={rootId}
              />
            )}
          </View>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Cancel')}
        </Button>
        <Button type="button" color="primary" margin="0 x-small 0 0" onClick={noop}>
          {I18n.t('Move')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

MoveModal.propTypes = {
  title: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default MoveModal
