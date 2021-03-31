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
import I18n from 'i18n!FindOutcomesModal'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import Modal from '../shared/components/InstuiModal'
import TreeBrowser from './Management/TreeBrowser'
import FindOutcomesBillboard from './FindOutcomesBillboard'
import FindOutcomesView from './FindOutcomesView'
import {useFindOutcomeModal, ACCOUNT_FOLDER_ID} from './shared/treeBrowser'
import useCanvasContext from './shared/hooks/useCanvasContext'
import useGroupDetail from './shared/hooks/useGroupDetail'

const FindOutcomesModal = ({open, onCloseHandler}) => {
  const {contextType} = useCanvasContext()
  const {
    rootId,
    isLoading,
    collections,
    selectedGroupId,
    toggleGroupId,
    searchString,
    updateSearch,
    clearSearch
  } = useFindOutcomeModal(open)
  const {group, loading, loadMore} = useGroupDetail(selectedGroupId)

  return (
    <Modal
      open={open}
      onDismiss={onCloseHandler}
      shouldReturnFocus
      size="fullscreen"
      label={
        contextType === 'Course'
          ? I18n.t('Add Outcomes to Course')
          : I18n.t('Add Outcomes to Account')
      }
    >
      <Modal.Body padding="0 small small">
        <Flex>
          <Flex.Item
            as="div"
            position="relative"
            width="25%"
            height="calc(100vh - 10.25rem)"
            overflowY="visible"
            overflowX="auto"
          >
            <View as="div" padding="small x-small none x-small">
              <Heading level="h3">
                <Text size="large" weight="light" fontStyle="normal">
                  {I18n.t('Outcome Groups')}
                </Text>
              </Heading>
              <View>
                {isLoading ? (
                  <div style={{textAlign: 'center', paddingTop: '2rem'}}>
                    <Spinner renderTitle={I18n.t('Loading')} size="large" />
                  </div>
                ) : (
                  <TreeBrowser
                    onCollectionToggle={toggleGroupId}
                    collections={collections}
                    rootId={rootId}
                  />
                )}
              </View>
            </View>
          </Flex.Item>
          <Flex.Item
            as="div"
            position="relative"
            width="1%"
            height="calc(100vh - 10.25rem)"
            margin="xxx-small 0 0"
            borderWidth="0 small 0 0"
          />
          <Flex.Item
            as="div"
            position="relative"
            width="74%"
            height="calc(100vh - 10.25rem)"
            overflowY="visible"
            overflowX="auto"
          >
            {selectedGroupId && String(selectedGroupId) !== String(ACCOUNT_FOLDER_ID) ? (
              <FindOutcomesView
                collection={collections[selectedGroupId]}
                outcomes={group?.outcomes}
                searchString={searchString}
                onChangeHandler={updateSearch}
                onClearHandler={clearSearch}
                onAddAllHandler={() => {}}
                loading={loading}
                loadMore={loadMore}
              />
            ) : (
              <FindOutcomesBillboard />
            )}
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="primary" margin="0 x-small 0 0" onClick={onCloseHandler}>
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

FindOutcomesModal.propTypes = {
  open: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default FindOutcomesModal
