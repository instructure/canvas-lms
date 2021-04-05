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

import React, {useState} from 'react'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Billboard} from '@instructure/ui-billboard'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!OutcomeManagement'
import SVGWrapper from '@canvas/svg-wrapper'
import ManageOutcomesView from './ManageOutcomesView'
import ManageOutcomesFooter from './ManageOutcomesFooter'
import useSearch from '@canvas/outcomes/react/hooks/useSearch'
import TreeBrowser from './TreeBrowser'
import {useManageOutcomes} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import useModal from '@canvas/outcomes/react/hooks/useModal'
import useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'
import MoveModal from './MoveModal'
import EditGroupModal from './EditGroupModal'
import GroupRemoveModal from './GroupRemoveModal'
import OutcomeRemoveModal from './OutcomeRemoveModal'
import OutcomeEditModal from './OutcomeEditModal'
import {moveOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const NoOutcomesBillboard = () => {
  const {contextType} = useCanvasContext()
  const isCourse = contextType === 'Course'

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      <Billboard
        size="large"
        headingLevel="h3"
        heading={
          isCourse
            ? I18n.t('Outcomes have not been added to this course yet.')
            : I18n.t('Outcomes have not been added to this account yet.')
        }
        message={
          isCourse
            ? I18n.t('Get started by finding, importing or creating your course outcomes.')
            : I18n.t('Get started by finding, importing or creating your account outcomes.')
        }
        hero={
          <div>
            <PresentationContent>
              <SVGWrapper url="/images/magnifying_glass.svg" />
            </PresentationContent>
          </div>
        }
      />
    </div>
  )
}

const OutcomeManagementPanel = () => {
  const {contextType, contextId} = useCanvasContext()
  const [searchString, onSearchChangeHandler, onSearchClearHandler] = useSearch()
  const [selectedOutcomes, setSelectedOutcomes] = useState({})
  const selected = Object.keys(selectedOutcomes).length
  const onSelectOutcomesHandler = id =>
    setSelectedOutcomes(prevState => {
      const updatedState = {...prevState}
      prevState[id] ? delete updatedState[id] : (updatedState[id] = true)
      return updatedState
    })
  const noop = () => {}
  const {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId,
    selectedParentGroupId
  } = useManageOutcomes()
  const {loading, group, loadMore} = useGroupDetail(selectedGroupId)
  const [isMoveGroupModalOpen, openMoveGroupModal, closeMoveGroupModal] = useModal()
  const [isGroupRemoveModalOpen, openGroupRemoveModal, closeGroupRemoveModal] = useModal()
  const [isEditGroupModalOpen, openEditGroupModal, closeEditGroupModal] = useModal()
  const [isOutcomeEditModalOpen, openOutcomeEditModal, closeOutcomeEditModal] = useModal()
  const [isOutcomeRemoveModalOpen, openOutcomeRemoveModal, closeOutcomeRemoveModal] = useModal()
  const [selectedOutcome, setSelectedOutcome] = useState(null)
  const onCloseOutcomeRemoveModal = () => {
    closeOutcomeRemoveModal()
    setSelectedOutcome(null)
  }
  const onCloseOutcomeEditModal = () => {
    closeOutcomeEditModal()
    setSelectedOutcome(null)
  }
  const groupMenuHandler = (_, action) => {
    if (action === 'move') {
      openMoveGroupModal()
    } else if (action === 'remove') {
      openGroupRemoveModal()
    } else if (action === 'edit') {
      openEditGroupModal()
    }
  }
  const outcomeMenuHandler = (id, action) => {
    setSelectedOutcome(group.outcomes.nodes.find(outcome => outcome._id === id))
    if (action === 'remove') {
      openOutcomeRemoveModal()
    } else if (action === 'edit') {
      openOutcomeEditModal()
    }
  }

  const onMoveHandler = async newParentGroup => {
    closeMoveGroupModal()
    try {
      if (!group) {
        return
      }
      await moveOutcomeGroup(contextType, contextId, group._id, newParentGroup.id)
      showFlashAlert({
        message: I18n.t('"%{title}" has been moved to "%{newGroupTitle}".', {
          title: group.title,
          newGroupTitle: newParentGroup.name
        }),
        type: 'success'
      })
    } catch (err) {
      showFlashAlert({
        message: err.message
          ? I18n.t('An error occurred moving group "%{title}": %{message}', {
              title: group.title,
              message: err.message
            })
          : I18n.t('An error occurred moving group "%{title}"', {
              title: group.title
            }),
        type: 'error'
      })
    }
  }

  if (isLoading) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }

  if (error) {
    return (
      <Text color="danger">
        {contextType === 'Course'
          ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
          : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
      </Text>
    )
  }

  // Currently we're checking the presence of outcomes by checking the presence of folders
  // we need to implement the correct behavior later
  // https://gerrit.instructure.com/c/canvas-lms/+/255898/8/app/jsx/outcomes/Management/index.js#235
  const hasOutcomes = Object.keys(collections).length > 1

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      {!hasOutcomes ? (
        <NoOutcomesBillboard />
      ) : (
        <>
          <Flex>
            <Flex.Item
              width="33%"
              display="inline-block"
              position="relative"
              height="60vh"
              as="div"
            >
              <View as="div" padding="small none none x-small">
                <Text size="large" weight="light" fontStyle="normal">
                  {I18n.t('Outcome Groups')}
                </Text>
                <TreeBrowser
                  onCollectionToggle={queryCollections}
                  collections={collections}
                  rootId={rootId}
                />
              </View>
            </Flex.Item>
            <Flex.Item
              width="1%"
              display="inline-block"
              position="relative"
              padding="small none large none"
              margin="small none none none"
              borderWidth="none small none none"
              height="60vh"
              as="div"
            />
            <Flex.Item
              as="div"
              width="66%"
              display="inline-block"
              position="relative"
              height="60vh"
              overflowY="visible"
              overflowX="auto"
            >
              <View as="div" padding="x-small none none x-small">
                {selectedGroupId && (
                  <ManageOutcomesView
                    key={selectedGroupId}
                    outcomeGroup={group}
                    loading={loading}
                    selectedOutcomes={selectedOutcomes}
                    searchString={searchString}
                    onSelectOutcomesHandler={onSelectOutcomesHandler}
                    onOutcomeGroupMenuHandler={groupMenuHandler}
                    onOutcomeMenuHandler={outcomeMenuHandler}
                    onSearchChangeHandler={onSearchChangeHandler}
                    onSearchClearHandler={onSearchClearHandler}
                    loadMore={loadMore}
                  />
                )}
              </View>
            </Flex.Item>
          </Flex>
          <hr />
          {selectedGroupId && (
            <>
              <ManageOutcomesFooter
                selected={selected}
                onRemoveHandler={noop}
                onMoveHandler={noop}
              />

              <MoveModal
                title={loading ? '' : group.title}
                groupId={selectedGroupId}
                parentGroupId={selectedParentGroupId}
                type="group"
                isOpen={isMoveGroupModalOpen}
                onCloseHandler={closeMoveGroupModal}
                onMoveHandler={onMoveHandler}
              />

              <GroupRemoveModal
                groupId={selectedGroupId}
                isOpen={isGroupRemoveModalOpen}
                onCloseHandler={closeGroupRemoveModal}
              />
            </>
          )}
          {selectedGroupId && selectedOutcome && (
            <>
              <OutcomeRemoveModal
                groupId={selectedGroupId}
                outcomeId={selectedOutcome._id}
                isOpen={isOutcomeRemoveModalOpen}
                onCloseHandler={onCloseOutcomeRemoveModal}
              />
              <OutcomeEditModal
                outcome={selectedOutcome}
                isOpen={isOutcomeEditModalOpen}
                onCloseHandler={onCloseOutcomeEditModal}
              />
            </>
          )}
          {group && (
            <EditGroupModal
              outcomeGroup={group}
              isOpen={isEditGroupModalOpen}
              onCloseHandler={closeEditGroupModal}
            />
          )}
        </>
      )}
    </div>
  )
}

export default OutcomeManagementPanel
