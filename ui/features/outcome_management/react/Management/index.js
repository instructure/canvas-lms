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

import React, {useCallback, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!OutcomeManagement'
import ManageOutcomesView from './ManageOutcomesView'
import ManageOutcomesFooter from './ManageOutcomesFooter'
import useSearch from '@canvas/outcomes/react/hooks/useSearch'
import TreeBrowser from './TreeBrowser'
import {useManageOutcomes} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import useModal from '@canvas/outcomes/react/hooks/useModal'
import useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'
import useResize from '@canvas/outcomes/react/hooks/useResize'
import useSelectedOutcomes from '@canvas/outcomes/react/hooks/useSelectedOutcomes'
import GroupMoveModal from './GroupMoveModal'
import GroupEditModal from './GroupEditModal'
import GroupDescriptionModal from './GroupDescriptionModal'
import GroupRemoveModal from './GroupRemoveModal'
import OutcomeRemoveModal from './OutcomeRemoveModal'
import OutcomeEditModal from './OutcomeEditModal'
import OutcomeMoveModal from './OutcomeMoveModal'
import ManageOutcomesBillboard from './ManageOutcomesBillboard'
import GroupActionDrillDown from '../shared/GroupActionDrillDown'

const OutcomeManagementPanel = () => {
  const {isCourse, isMobileView, canManage} = useCanvasContext()
  const {
    search: searchString,
    debouncedSearch: debouncedSearchString,
    onChangeHandler: onSearchChangeHandler,
    onClearHandler: onSearchClearHandler
  } = useSearch()
  const {setContainerRef, setLeftColumnRef, setDelimiterRef, setRightColumnRef, onKeyDownHandler} =
    useResize()
  const [scrollContainer, setScrollContainer] = useState(null)
  const {selectedOutcomes, selectedOutcomesCount, toggleSelectedOutcomes, clearSelectedOutcomes} =
    useSelectedOutcomes()
  const {
    error,
    isLoading,
    collections,
    queryCollections,
    rootId,
    selectedGroupId,
    selectedParentGroupId,
    removeGroup,
    loadedGroups,
    createGroup
  } = useManageOutcomes('OutcomeManagementPanel')

  const {group, loading, loadMore, removeLearningOutcomes} = useGroupDetail({
    id: selectedGroupId,
    searchString: debouncedSearchString
  })

  const [isGroupMoveModalOpen, openGroupMoveModal, closeGroupMoveModal] = useModal()
  const [isGroupRemoveModalOpen, openGroupRemoveModal, closeGroupRemoveModal] = useModal()
  const [isGroupEditModalOpen, openGroupEditModal, closeGroupEditModal] = useModal()
  const [isOutcomeEditModalOpen, openOutcomeEditModal, closeOutcomeEditModal] = useModal()
  const [isOutcomeRemoveModalOpen, openOutcomeRemoveModal, closeOutcomeRemoveModal] = useModal()
  const [isOutcomesRemoveModalOpen, openOutcomesRemoveModal, closeOutcomesRemoveModal] = useModal()
  const [isOutcomeMoveModalOpen, openOutcomeMoveModal, closeOutcomeMoveModal] = useModal()
  const [isOutcomesMoveModalOpen, openOutcomesMoveModal, closeOutcomesMoveModal] = useModal()
  const [isGroupDescriptionModalOpen, openGroupDescriptionModal, closeGroupDescriptionModal] =
    useModal()
  const [selectedOutcome, setSelectedOutcome] = useState(null)
  const selectedOutcomeObj = selectedOutcome ? {[selectedOutcome.linkId]: selectedOutcome} : {}
  const onCloseOutcomeRemoveModal = () => {
    closeOutcomeRemoveModal()
    setSelectedOutcome(null)
  }
  const onCloseOutcomesRemoveModal = () => {
    closeOutcomesRemoveModal()
    clearSelectedOutcomes()
  }
  const onCloseOutcomeMoveModal = () => {
    closeOutcomeMoveModal()
    setSelectedOutcome(null)
  }
  const onCloseOutcomesMoveModal = () => {
    closeOutcomesMoveModal()
    clearSelectedOutcomes()
  }
  const onCloseOutcomeEditModal = () => {
    closeOutcomeEditModal()
    setSelectedOutcome(null)
  }
  const onSucessGroupRemove = () => {
    if (selectedParentGroupId) {
      queryCollections({id: selectedParentGroupId})
    }
    removeGroup(selectedGroupId)
  }

  const groupMenuHandler = useCallback(
    (_arg, action) => {
      if (action === 'move') {
        openGroupMoveModal()
      } else if (action === 'remove') {
        openGroupRemoveModal()
      } else if (action === 'edit') {
        openGroupEditModal()
      } else if (action === 'description') {
        openGroupDescriptionModal()
      }
    },
    [openGroupDescriptionModal, openGroupEditModal, openGroupMoveModal, openGroupRemoveModal]
  )

  const outcomeMenuHandler = useCallback(
    (linkId, action) => {
      const edge = group.outcomes.edges.find(edgeEl => edgeEl._id === linkId)
      setSelectedOutcome({linkId, canUnlink: edge.canUnlink, ...edge.node})
      if (action === 'remove') {
        openOutcomeRemoveModal()
      } else if (action === 'edit') {
        openOutcomeEditModal()
      } else if (action === 'move') {
        openOutcomeMoveModal()
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [group]
  )

  // After move outcomes, remove from list if the target group isn't
  // the selected group or isn't children of the selected group
  const onSuccessMoveOutcomes = ({movedOutcomeLinkIds, targetAncestorsIds}) => {
    if (!targetAncestorsIds.includes(selectedGroupId)) {
      removeLearningOutcomes(movedOutcomeLinkIds, false)
    }
  }

  if (isLoading) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }

  if (error && Object.keys(collections).length === 0) {
    return (
      <Text color="danger">
        {isCourse
          ? I18n.t('An error occurred while loading course outcomes: %{error}', {error})
          : I18n.t('An error occurred while loading account outcomes: %{error}', {error})}
      </Text>
    )
  }

  return (
    <div className="management-panel" data-testid="outcomeManagementPanel">
      {isMobileView ? (
        <View
          as="div"
          width="100%"
          display="inline-block"
          position="relative"
          height="60vh"
          overflowY="visible"
          overflowX="auto"
          padding="small 0 0"
        >
          <View as="div" padding="x-small x-small none">
            {/* TODO: Add ManageView in OUT-4183  */}
            <GroupActionDrillDown
              onCollectionClick={queryCollections}
              collections={collections}
              rootId={rootId}
              loadedGroups={loadedGroups}
              setShowOutcomesView={() => {}}
              isLoadingGroupDetail={loading}
              outcomesCount={group?.outcomesCount}
              showActionLinkForRoot
            />
            <ManageOutcomesBillboard />
          </View>
        </View>
      ) : (
        <Flex elementRef={setContainerRef}>
          <Flex.Item
            width="33%"
            display="inline-block"
            position="relative"
            height="60vh"
            as="div"
            overflowY="auto"
            overflowX="hidden"
            elementRef={setLeftColumnRef}
          >
            <View as="div" padding="small x-small none x-small">
              <Text size="large" weight="light" fontStyle="normal">
                {I18n.t('Outcome Groups')}
              </Text>
              <View data-testid="outcomes-management-tree-browser">
                <TreeBrowser
                  onCollectionToggle={queryCollections}
                  collections={collections}
                  rootId={rootId}
                  showRootCollection
                  defaultExpandedIds={[rootId]}
                  onCreateGroup={createGroup}
                  loadedGroups={loadedGroups}
                />
              </View>
            </View>
          </Flex.Item>
          <Flex.Item
            as="div"
            position="relative"
            width="1%"
            height="60vh"
            margin="small none none none"
            padding="small none large none"
            display="inline-block"
          >
            {/* eslint-disable jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-noninteractive-tabindex */}
            <div
              tabIndex="0"
              role="separator"
              aria-orientation="vertical"
              onKeyDown={onKeyDownHandler}
              ref={setDelimiterRef}
              style={{
                width: '1vw',
                height: '100%',
                cursor: 'col-resize',
                background:
                  '#EEEEEE url("/images/splitpane_handle-ew.gif") no-repeat scroll 50% 50%'
              }}
            />
            {/* eslint-enable jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-noninteractive-tabindex */}
          </Flex.Item>
          <Flex.Item
            as="div"
            width="66%"
            display="inline-block"
            position="relative"
            height="60vh"
            overflowY="visible"
            overflowX="auto"
            elementRef={el => {
              setRightColumnRef(el)
              setScrollContainer(el)
            }}
          >
            <View as="div" padding="x-small none none x-small">
              {selectedGroupId && (
                <ManageOutcomesView
                  key={selectedGroupId}
                  outcomeGroup={group}
                  loading={loading}
                  selectedOutcomes={selectedOutcomes}
                  searchString={searchString}
                  onSelectOutcomesHandler={toggleSelectedOutcomes}
                  onOutcomeGroupMenuHandler={groupMenuHandler}
                  onOutcomeMenuHandler={outcomeMenuHandler}
                  onSearchChangeHandler={onSearchChangeHandler}
                  onSearchClearHandler={onSearchClearHandler}
                  loadMore={loadMore}
                  scrollContainer={scrollContainer}
                  isRootGroup={collections[selectedGroupId]?.isRootGroup}
                />
              )}
            </View>
          </Flex.Item>
        </Flex>
      )}
      <hr style={{margin: '0 0 7px'}} />
      {canManage && (
        <ManageOutcomesFooter
          selected={selectedOutcomes}
          selectedCount={selectedOutcomesCount}
          onRemoveHandler={openOutcomesRemoveModal}
          onMoveHandler={openOutcomesMoveModal}
          onClearHandler={clearSelectedOutcomes}
        />
      )}
      {selectedGroupId && (
        <>
          <GroupRemoveModal
            groupId={selectedGroupId}
            isOpen={isGroupRemoveModalOpen}
            onCloseHandler={closeGroupRemoveModal}
            onCollectionToggle={queryCollections}
            onSuccess={onSucessGroupRemove}
          />
          {!loading && selectedParentGroupId && (
            <GroupMoveModal
              groupId={selectedGroupId}
              groupTitle={group?.title}
              parentGroupId={selectedParentGroupId}
              isOpen={isGroupMoveModalOpen}
              onCloseHandler={closeGroupMoveModal}
              onSuccess={() => {
                queryCollections({
                  id: selectedParentGroupId
                })
              }}
              rootGroup={collections[rootId]}
            />
          )}
          {selectedOutcome && (
            <>
              <OutcomeRemoveModal
                outcomes={selectedOutcomeObj}
                isOpen={isOutcomeRemoveModalOpen}
                onCloseHandler={onCloseOutcomeRemoveModal}
                onCleanupHandler={onCloseOutcomeRemoveModal}
                onRemoveLearningOutcomesHandler={removeLearningOutcomes}
              />
              <OutcomeEditModal
                outcome={selectedOutcome}
                isOpen={isOutcomeEditModalOpen}
                onCloseHandler={onCloseOutcomeEditModal}
              />
              <OutcomeMoveModal
                outcomes={selectedOutcomeObj}
                isOpen={isOutcomeMoveModalOpen}
                onCloseHandler={onCloseOutcomeMoveModal}
                onCleanupHandler={onCloseOutcomeMoveModal}
                onSuccess={onSuccessMoveOutcomes}
                rootGroup={collections[rootId]}
              />
            </>
          )}
        </>
      )}
      {group && (
        <>
          <GroupEditModal
            outcomeGroup={group}
            isOpen={isGroupEditModalOpen}
            onCloseHandler={closeGroupEditModal}
          />
          <GroupDescriptionModal
            outcomeGroup={group}
            isOpen={isGroupDescriptionModalOpen}
            onCloseHandler={closeGroupDescriptionModal}
          />
        </>
      )}
      {selectedOutcomesCount > 0 && (
        <>
          <OutcomeRemoveModal
            outcomes={selectedOutcomes}
            isOpen={isOutcomesRemoveModalOpen}
            onCloseHandler={closeOutcomesRemoveModal}
            onCleanupHandler={onCloseOutcomesRemoveModal}
            onRemoveLearningOutcomesHandler={removeLearningOutcomes}
          />
          <OutcomeMoveModal
            outcomes={selectedOutcomes}
            isOpen={isOutcomesMoveModalOpen}
            onCloseHandler={closeOutcomesMoveModal}
            onCleanupHandler={onCloseOutcomesMoveModal}
            onSuccess={onSuccessMoveOutcomes}
            rootGroup={collections[rootId]}
          />
        </>
      )}
    </div>
  )
}

export default OutcomeManagementPanel
