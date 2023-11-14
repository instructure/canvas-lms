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

import React, {useCallback, useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as useI18nScope} from '@canvas/i18n'
import ManageOutcomesView from './ManageOutcomesView'
import ManageOutcomesFooter from './ManageOutcomesFooter'
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
import useLhsTreeBrowserSelectParentGroup from '@canvas/outcomes/react/hooks/useLhsTreeBrowserSelectParentGroup'
import FindOutcomesModal from '../FindOutcomesModal'
import {showImportOutcomesModal} from '@canvas/outcomes/react/ImportOutcomesModal'
import useOutcomesRemove from '@canvas/outcomes/react/hooks/useOutcomesRemove'
import {getOutcomeGroupAncestorsWithSelf} from '../../helpers/getOutcomeGroupAncestorsWithSelf'
import {ROOT_GROUP} from '@canvas/outcomes/react/hooks/useOutcomesImport'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('OutcomeManagement')

const OutcomeManagementPanel = ({
  importNumber,
  createdOutcomeGroupIds,
  onLhsSelectedGroupIdChanged,
  lhsGroupId,
  handleFileDrop,
  targetGroupIdsToRefetch,
  setTargetGroupIdsToRefetch,
  importsTargetGroup,
  setImportsTargetGroup,
}) => {
  const {isCourse, isMobileView, canManage} = useCanvasContext()
  const {setContainerRef, setLeftColumnRef, setDelimiterRef, setRightColumnRef, onKeyDownHandler} =
    useResize()
  const [scrollContainer, setScrollContainer] = useState(null)
  const [rhsGroupIdsToRefetch, setRhsGroupIdsToRefetch] = useState([])
  const [lhsGroupIdsToRefetch, setLhsGroupIdsToRefetch] = useState([])
  const [parentsToUnload, setParentsToUnload] = useState([])
  const {
    selectedOutcomeIds,
    selectedOutcomesCount,
    toggleSelectedOutcomes,
    removeSelectedOutcome,
    clearSelectedOutcomes,
  } = useSelectedOutcomes()
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
    createGroup,
    searchString,
    debouncedSearchString,
    updateSearch: onSearchChangeHandler,
    clearSearch: onSearchClearHandler,
    clearCache,
  } = useManageOutcomes({
    collection: 'OutcomeManagementPanel',
    importNumber,
    lhsGroupIdsToRefetch,
    lhsGroupId,
    parentsToUnload,
  })

  useEffect(() => {
    return () => {
      clearCache()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (createdOutcomeGroupIds.length > 0 && Object.keys(collections).length > 0) {
      for (let i = createdOutcomeGroupIds.length - 1; i >= 0; i--) {
        if (collections[createdOutcomeGroupIds[i]]) {
          setParentsToUnload(
            getOutcomeGroupAncestorsWithSelf(collections, createdOutcomeGroupIds[i])
          )
          break
        }
      }
    }
    setRhsGroupIdsToRefetch(ids => [...new Set([...ids, ...createdOutcomeGroupIds])])
  }, [createdOutcomeGroupIds]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (targetGroupIdsToRefetch.length > 0) {
      const groupIdsToRefetch = new Set(
        targetGroupIdsToRefetch.reduce(
          (acc, targetGroupId) =>
            targetGroupId === ROOT_GROUP
              ? [...acc, rootId]
              : [...acc, ...getOutcomeGroupAncestorsWithSelf(collections, targetGroupId)],
          []
        )
      )
      const lhsTargetGroupIdsToRefetch = targetGroupIdsToRefetch.map(gid =>
        gid === ROOT_GROUP ? rootId : gid
      )
      setLhsGroupIdsToRefetch(lhsTargetGroupIdsToRefetch)
      setRhsGroupIdsToRefetch(ids => [...new Set([...ids, ...groupIdsToRefetch])])
      setTargetGroupIdsToRefetch([])
    }
  }, [targetGroupIdsToRefetch]) // eslint-disable-line react-hooks/exhaustive-deps

  const {
    group,
    loading,
    loadMore,
    removeLearningOutcomes,
    readLearningOutcomes,
    refetchLearningOutcome,
  } = useGroupDetail({
    id: selectedGroupId,
    searchString: debouncedSearchString,
    rhsGroupIdsToRefetch,
  })

  const {removeOutcomes, removeOutcomesStatus} = useOutcomesRemove()

  const selectedOutcomes = readLearningOutcomes(selectedOutcomeIds)
  const [showOutcomesView, setShowOutcomesView] = useState(false)
  const [showGroupOptions, setShowGroupOptions] = useState(false)

  useEffect(() => {
    if (onLhsSelectedGroupIdChanged) {
      onLhsSelectedGroupIdChanged(selectedGroupId)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedGroupId])

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
  const [isFindOutcomesModalOpen, openFindOutcomesModal, closeFindOutcomesModal] = useModal()
  const [selectedOutcome, setSelectedOutcome] = useState(null)
  const selectedOutcomeObj = selectedOutcome ? {[selectedOutcome.linkId]: selectedOutcome} : {}
  const onRemoveLearningOutcome = removableLinkIds => {
    removeLearningOutcomes(removableLinkIds)
    removeSelectedOutcome(selectedOutcome)
  }
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

  const {selectParentGroupInLhs, treeBrowserViewRef} = useLhsTreeBrowserSelectParentGroup({
    selectedParentGroupId,
    selectedGroupId,
    collections,
    queryCollections,
  })

  const onSuccessGroupRemove = () => {
    selectParentGroupInLhs()
    removeGroup(selectedGroupId)
    setParentsToUnload(getOutcomeGroupAncestorsWithSelf(collections, selectedParentGroupId))
    clearSelectedOutcomes()
  }

  const handleCloseFindOutcomesModal = _hasAddedOutcomes => {
    closeFindOutcomesModal()
  }

  const openImportOutcomesModal = useCallback(() => {
    showImportOutcomesModal({
      learningOutcomeGroup: group,
      learningOutcomeGroupAncestorIds: Object.keys(collections),
      onFileDrop: handleFileDrop,
    })
  }, [group, collections, handleFileDrop])

  const groupMenuHandler = useCallback(
    (_arg, action) => {
      const actions = {
        move: openGroupMoveModal,
        remove: openGroupRemoveModal,
        edit: openGroupEditModal,
        description: openGroupDescriptionModal,
        add_outcomes: openFindOutcomesModal,
        import_outcomes: openImportOutcomesModal,
      }

      const callback = actions[action] || function () {}
      callback()
    },
    [
      openFindOutcomesModal,
      openGroupDescriptionModal,
      openGroupEditModal,
      openGroupMoveModal,
      openGroupRemoveModal,
      openImportOutcomesModal,
    ]
  )

  const outcomeMenuHandler = useCallback(
    (linkId, action) => {
      const edge = group.outcomes.edges.find(edgeEl => edgeEl._id === linkId)
      const parentGroup = edge.group
      setSelectedOutcome({
        linkId,
        canUnlink: edge.canUnlink,
        parentGroupId: parentGroup._id,
        parentGroupTitle: parentGroup.title,
        ...edge.node,
      })
      if (action === 'remove') {
        openOutcomeRemoveModal()
      } else if (action === 'edit') {
        openOutcomeEditModal()
      } else if (action === 'move') {
        openOutcomeMoveModal()
      } else if (action === 'alignments') {
        // redirect to alignment details page for selected outcome
        window.open('outcomes/' + edge.node._id)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [group]
  )

  // set the initial target group as the lhs group
  let outcomeMoveInitialTargetGroup = collections[selectedGroupId]

  const singleOutcomeSelected =
    selectedOutcome || (selectedOutcomes.length === 1 && selectedOutcomes[0])

  const componentOverrides = {
    View: {
      paddingLarge: '1.9rem',
    },
  }

  // if only one outcome is selected (kebab or bulk action)
  if (singleOutcomeSelected) {
    // set the initial target group as the outcome parent group
    outcomeMoveInitialTargetGroup = {
      name: singleOutcomeSelected.parentGroupTitle,
      id: singleOutcomeSelected.parentGroupId,
    }
  }

  // After move outcomes, mark all loaded outcomes group to be refetch, since:
  // 1 - If moving to the group in the LHS or some child, it'll probably change
  //     its position, so refetch needed
  // 2 - If moving to a group "outside" the LHS group, we need to remove from the list
  //     So refetch is needed
  const onSuccessMoveOutcomes = () => {
    // we would clear the whole RHS cache.
    const AllLhsGroupIds = Object.keys(collections)
    setRhsGroupIdsToRefetch(AllLhsGroupIds)
  }

  const hideOutcomesViewHandler = () => {
    setShowOutcomesView(false)
    setShowGroupOptions(true)
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
          height="70vh"
          overflowY="visible"
          overflowX="auto"
          padding="small x-small 0"
          elementRef={el => {
            setRightColumnRef(el)
            setScrollContainer(el)
          }}
        >
          {showOutcomesView && selectedGroupId ? (
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
              removeOutcomesStatus={removeOutcomesStatus}
              scrollContainer={scrollContainer}
              isRootGroup={collections[selectedGroupId]?.isRootGroup}
              hideOutcomesView={hideOutcomesViewHandler}
            />
          ) : (
            <>
              <GroupActionDrillDown
                onCollectionClick={queryCollections}
                collections={collections}
                rootId={rootId}
                loadedGroups={loadedGroups}
                isLoadingGroupDetail={loading}
                outcomesCount={group?.outcomesCount}
                selectedGroupId={selectedGroupId}
                showActionLinkForRoot={true}
                showOptions={showGroupOptions}
                setShowOutcomesView={setShowOutcomesView}
              />
              <View as="div" padding="small 0 0">
                <ManageOutcomesBillboard />
              </View>
            </>
          )}
        </View>
      ) : (
        <InstUISettingsProvider theme={{componentOverrides}}>
          <Flex elementRef={setContainerRef}>
            <Flex.Item
              width="33%"
              display="inline-block"
              position="relative"
              as="div"
              overflowY="auto"
              overflowX="hidden"
              elementRef={setLeftColumnRef}
            >
              <View
                as="div"
                padding="large none none none"
                minHeight="calc(720px - 10.75rem)"
                height="calc(100vh - 16.35rem)"
              >
                <Heading level="h2">
                  <Text size="large" weight="bold" fontStyle="normal">
                    {I18n.t('Outcome Groups')}
                  </Text>
                </Heading>
                <View
                  data-testid="outcomes-management-tree-browser"
                  elementRef={el => (treeBrowserViewRef.current = el)}
                >
                  <TreeBrowser
                    onCollectionToggle={queryCollections}
                    collections={collections}
                    rootId={rootId}
                    showRootCollection={true}
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
              display="inline-block"
              tabIndex="0"
              role="separator"
              aria-orientation="vertical"
              onKeyDown={onKeyDownHandler}
              elementRef={setDelimiterRef}
            >
              <div
                style={{
                  width: '1vw',
                  cursor: 'col-resize',
                  minHeight: 'calc(720px - 10.5rem)',
                  height: 'calc(100vh - 16.35rem)',
                  background:
                    '#EEEEEE url("/images/splitpane_handle-ew.gif") no-repeat scroll 50% 50%',
                }}
              />
            </Flex.Item>
            <Flex.Item
              as="div"
              width="66%"
              display="inline-block"
              position="relative"
              overflowY="visible"
              overflowX="auto"
              elementRef={el => {
                setRightColumnRef(el)
                setScrollContainer(el)
              }}
            >
              <View
                as="div"
                padding="large none none none"
                minHeight="calc(720px - 10.75rem)"
                height="calc(100vh - 16.35rem)"
              >
                {selectedGroupId && (
                  <ManageOutcomesView
                    key={selectedGroupId}
                    outcomeGroup={group}
                    loading={loading}
                    removeOutcomesStatus={removeOutcomesStatus}
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
        </InstUISettingsProvider>
      )}
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
          {!loading && group && selectedParentGroupId && (
            <GroupMoveModal
              groupId={selectedGroupId}
              groupTitle={group.title}
              parentGroupId={selectedParentGroupId}
              isOpen={isGroupMoveModalOpen}
              onCloseHandler={closeGroupMoveModal}
              onSuccess={selectParentGroupInLhs}
              parentGroup={collections[selectedParentGroupId]}
            />
          )}
          {selectedOutcome && (
            <>
              <OutcomeRemoveModal
                outcomes={selectedOutcomeObj}
                isOpen={isOutcomeRemoveModalOpen}
                onCloseHandler={onCloseOutcomeRemoveModal}
                onCleanupHandler={onCloseOutcomeRemoveModal}
                removeOutcomes={removeOutcomes}
                onRemoveLearningOutcomesHandler={onRemoveLearningOutcome}
              />
              <OutcomeEditModal
                outcome={selectedOutcome}
                isOpen={isOutcomeEditModalOpen}
                onCloseHandler={onCloseOutcomeEditModal}
                onEditLearningOutcomeHandler={refetchLearningOutcome}
              />
              <OutcomeMoveModal
                outcomes={selectedOutcomeObj}
                isOpen={isOutcomeMoveModalOpen}
                onCloseHandler={onCloseOutcomeMoveModal}
                onCleanupHandler={onCloseOutcomeMoveModal}
                onSuccess={onSuccessMoveOutcomes}
                initialTargetGroup={outcomeMoveInitialTargetGroup}
              />
            </>
          )}
        </>
      )}
      {group && (
        <>
          <GroupRemoveModal
            groupId={selectedGroupId}
            groupTitle={group.title}
            isOpen={isGroupRemoveModalOpen}
            onCloseHandler={closeGroupRemoveModal}
            onCollectionToggle={queryCollections}
            onSuccess={onSuccessGroupRemove}
          />
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
          <FindOutcomesModal
            open={isFindOutcomesModalOpen}
            onCloseHandler={handleCloseFindOutcomesModal}
            targetGroup={group}
            setTargetGroupIdsToRefetch={setTargetGroupIdsToRefetch}
            importsTargetGroup={importsTargetGroup}
            setImportsTargetGroup={setImportsTargetGroup}
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
            removeOutcomes={removeOutcomes}
            onRemoveLearningOutcomesHandler={removeLearningOutcomes}
          />
          <OutcomeMoveModal
            outcomes={selectedOutcomes}
            isOpen={isOutcomesMoveModalOpen}
            onCloseHandler={closeOutcomesMoveModal}
            onCleanupHandler={onCloseOutcomesMoveModal}
            onSuccess={onSuccessMoveOutcomes}
            initialTargetGroup={outcomeMoveInitialTargetGroup}
          />
        </>
      )}
    </div>
  )
}

OutcomeManagementPanel.defaultProps = {
  createdOutcomeGroupIds: [],
}

OutcomeManagementPanel.propTypes = {
  createdOutcomeGroupIds: PropTypes.arrayOf(PropTypes.string),
  onLhsSelectedGroupIdChanged: PropTypes.func,
  lhsGroupId: PropTypes.string,
  importNumber: PropTypes.number,
  handleFileDrop: PropTypes.func,
  targetGroupIdsToRefetch: PropTypes.arrayOf(PropTypes.string).isRequired,
  setTargetGroupIdsToRefetch: PropTypes.func.isRequired,
  importsTargetGroup: PropTypes.object.isRequired,
  setImportsTargetGroup: PropTypes.func.isRequired,
}

export default OutcomeManagementPanel
