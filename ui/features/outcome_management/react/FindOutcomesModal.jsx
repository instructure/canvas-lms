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

import React, {useState, useRef, useEffect} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TreeBrowser from './Management/TreeBrowser'
import FindOutcomesBillboard from './FindOutcomesBillboard'
import FindOutcomesView from './FindOutcomesView'
import {showImportConfirmBox} from './ImportConfirmBox'
import {useFindOutcomeModal} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'
import useResize from '@canvas/outcomes/react/hooks/useResize'
import useBoolean from '@canvas/outcomes/react/hooks/useBoolean'
import {FIND_GROUP_OUTCOMES} from '@canvas/outcomes/graphql/Management'
import GroupActionDrillDown from './shared/GroupActionDrillDown'
import {isEmpty} from 'lodash'
import useOutcomesImport, {
  IMPORT_COMPLETED,
  ROOT_GROUP,
} from '@canvas/outcomes/react/hooks/useOutcomesImport'
import {getOutcomeGroupAncestorsWithSelf} from '../helpers/getOutcomeGroupAncestorsWithSelf'

const I18n = useI18nScope('FindOutcomesModal')

const FindOutcomesModal = ({
  open,
  onCloseHandler,
  targetGroup,
  importsTargetGroup,
  setImportsTargetGroup,
  setTargetGroupIdsToRefetch,
}) => {
  const {isMobileView, isCourse, rootOutcomeGroup, rootIds} = useCanvasContext()
  const [showOutcomesView, setShowOutcomesView] = useState(false)
  const [scrollContainer, setScrollContainer] = useState(null)
  const [importedGroupIds, setImportedGroupIds] = useState([])
  const [importedOutcomesIds, setImportedOutcomesIds] = useState([])
  const [importedGroupAncestors, setImportedGroupAncestors] = useState({})
  const [rhsGroupIdsToRefetch, setRhsGroupIdsToRefetch] = useState([])
  const {
    rootId,
    isLoading,
    collections,
    selectedGroupId,
    toggleGroupId,
    searchString,
    debouncedSearchString,
    updateSearch,
    clearSearch,
    error,
    loadedGroups,
  } = useFindOutcomeModal(open)

  const {group, loading, loadMore, refetchLearningOutcome} = useGroupDetail({
    id: selectedGroupId,
    query: FIND_GROUP_OUTCOMES,
    loadOutcomesIsImported: true,
    searchString: debouncedSearchString,
    targetGroupId: rootOutcomeGroup?.id,
    rhsGroupIdsToRefetch,
  })

  useEffect(() => {
    if (!open) {
      setShowOutcomesView(false)
    }
  }, [open])

  const {setContainerRef, setLeftColumnRef, setDelimiterRef, setRightColumnRef, onKeyDownHandler} =
    useResize()

  const {
    importOutcomes,
    importGroupsStatus,
    importOutcomesStatus,
    hasAddedOutcomes,
    setHasAddedOutcomes,
  } = useOutcomesImport()

  const onCloseModalHandler = () => {
    onCloseHandler(hasAddedOutcomes)
  }

  const [isConfirmBoxOpen, openConfirmBox, closeConfirmBox] = useBoolean()
  const [shouldFocusAddAllBtn, focusAddAllBtn, blurAddAllBtn] = useBoolean()
  const [shouldFocusDoneBtn, focusDoneBtn, blurDoneBtn] = useBoolean()
  const doneBtnRef = useRef()

  useEffect(() => {
    if (shouldFocusDoneBtn) doneBtnRef.current?.focus()
  }, [shouldFocusDoneBtn])

  useEffect(() => {
    if (open) {
      setHasAddedOutcomes(false)
    }
  }, [open, setHasAddedOutcomes])

  useEffect(() => {
    // after group is imported add all of its ancestors to the refetch array
    const newlyImportedGroupIds = new Set(
      Object.entries(importGroupsStatus).reduce(
        (acc, [gid, importStatus]) => (importStatus === IMPORT_COMPLETED ? [...acc, gid] : acc),
        []
      )
    )
    for (const importedGroupId of importedGroupIds) {
      newlyImportedGroupIds.delete(importedGroupId)
    }

    if (newlyImportedGroupIds.size > 0) {
      setImportedGroupIds(importedGids => [...new Set([...importedGids, ...newlyImportedGroupIds])])

      const newRhsGroupIdsToRefetch = [...newlyImportedGroupIds].reduce(
        (acc, groupId) =>
          importedGroupAncestors[groupId] ? [...acc, ...importedGroupAncestors[groupId]] : acc,
        []
      )

      setTargetGroupIdsToRefetch([
        ...new Set([...newlyImportedGroupIds].map(gid => importsTargetGroup[gid])),
      ])
      setRhsGroupIdsToRefetch(gidsToRefetch => [
        ...new Set([...gidsToRefetch, ...newRhsGroupIdsToRefetch]),
      ])
    }
  }, [importGroupsStatus]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    // after outcomes are imported set the target group to be refetched
    const newlyImportedOutcomesIds = new Set(
      Object.entries(importOutcomesStatus).reduce(
        (acc, [oid, importStatus]) => (importStatus === IMPORT_COMPLETED ? [...acc, oid] : acc),
        []
      )
    )
    for (const importedOutcomeId of importedOutcomesIds) {
      newlyImportedOutcomesIds.delete(importedOutcomeId)
    }

    if (newlyImportedOutcomesIds.size > 0) {
      const targetGroupIdsToRefetch = new Set(
        Object.entries(importsTargetGroup).reduce(
          (acc, [oid, targetGroupId]) =>
            newlyImportedOutcomesIds.has(oid) ? [...acc, targetGroupId] : acc,
          []
        )
      )
      setImportedOutcomesIds(importedOids => [
        ...new Set([...importedOids, ...newlyImportedOutcomesIds]),
      ])
      setTargetGroupIdsToRefetch([...targetGroupIdsToRefetch])
    }
    if (
      !isEmpty(importOutcomesStatus) &&
      Object.values(importOutcomesStatus).every(importStatus => importStatus === IMPORT_COMPLETED)
    ) {
      refetchLearningOutcome()
    }
  }, [importOutcomesStatus]) // eslint-disable-line react-hooks/exhaustive-deps

  const onAddAllHandler = () => {
    const callImportApiToGroup = () => {
      importOutcomes({
        targetGroupId: targetGroup?._id,
        targetGroupTitle: targetGroup?.title,
        outcomeOrGroupId: selectedGroupId,
        groupTitle: group.title,
      })
      setImportedGroupAncestors({
        ...importedGroupAncestors,
        [selectedGroupId]: getOutcomeGroupAncestorsWithSelf(collections, selectedGroupId),
      })
      setImportsTargetGroup({
        ...importsTargetGroup,
        [selectedGroupId]: targetGroup ? targetGroup._id : ROOT_GROUP,
      })
    }

    if (isCourse && !isConfirmBoxOpen && group.outcomesCount > 50) {
      blurAddAllBtn()
      blurDoneBtn()
      openConfirmBox()
      showImportConfirmBox({
        count: group.outcomesCount,
        onImportHandler: () => {
          callImportApiToGroup()
          closeConfirmBox()
          focusDoneBtn()
        },
        onCloseHandler: () => {
          closeConfirmBox()
          focusAddAllBtn()
        },
      })
    } else {
      callImportApiToGroup()
    }
  }

  const importSingleOutcomeHandler = (outcomeId, sourceContextId, sourceContextType) => {
    importOutcomes({
      outcomeOrGroupId: outcomeId,
      isGroup: false,
      targetGroupId: targetGroup?._id,
      targetGroupTitle: targetGroup?.title,
      sourceContextId,
      sourceContextType,
    })
    setImportsTargetGroup({
      ...importsTargetGroup,
      [outcomeId]: targetGroup ? targetGroup._id : ROOT_GROUP,
    })
  }

  const modalLabel = targetGroup
    ? I18n.t('Add Outcomes to "%{groupName}"', {
        groupName: targetGroup.title,
      })
    : isCourse
    ? I18n.t('Add Outcomes to Course')
    : I18n.t('Add Outcomes to Account')

  const selfOrParentBeingImported =
    getOutcomeGroupAncestorsWithSelf(collections, selectedGroupId).find(
      gid => importGroupsStatus[gid]
    ) || selectedGroupId

  const findOutcomesView = (
    <FindOutcomesView
      outcomesGroup={group}
      collection={collections[selectedGroupId]}
      searchString={searchString}
      onChangeHandler={updateSearch}
      onClearHandler={clearSearch}
      disableAddAllButton={isConfirmBoxOpen}
      importGroupStatus={importGroupsStatus[selfOrParentBeingImported]}
      onAddAllHandler={onAddAllHandler}
      loading={loading}
      loadMore={loadMore}
      mobileScrollContainer={scrollContainer}
      importOutcomesStatus={importOutcomesStatus}
      importOutcomeHandler={importSingleOutcomeHandler}
      shouldFocusAddAllBtn={shouldFocusAddAllBtn}
    />
  )

  const renderGroupNavigation = (
    <View as="div" padding={isMobileView ? 'small small x-small' : '0'}>
      {isLoading ? (
        <div style={{textAlign: 'center', paddingTop: '2rem'}}>
          <Spinner renderTitle={I18n.t('Loading')} size="large" />
        </div>
      ) : error && Object.keys(collections).length === 0 ? (
        <Text color="danger">
          {isCourse
            ? I18n.t('An error occurred while loading course outcomes: %{error}', {
                error,
              })
            : I18n.t('An error occurred while loading account outcomes: %{error}', {
                error,
              })}
        </Text>
      ) : isMobileView ? (
        <GroupActionDrillDown
          isLoadingGroupDetail={loading}
          outcomesCount={group?.outcomesCount}
          onCollectionClick={toggleGroupId}
          collections={collections}
          rootId={rootId}
          loadedGroups={loadedGroups}
          setShowOutcomesView={setShowOutcomesView}
        />
      ) : (
        <TreeBrowser onCollectionToggle={toggleGroupId} collections={collections} rootId={rootId} />
      )}
    </View>
  )

  return (
    <Modal
      open={open}
      onDismiss={onCloseModalHandler}
      shouldReturnFocus={true}
      size="fullscreen"
      label={modalLabel}
      shouldCloseOnDocumentClick={false}
      data-testid="find-outcomes-modal"
    >
      <Modal.Body padding={isMobileView ? '0' : '0 small small'}>
        {!isMobileView ? (
          <Flex elementRef={setContainerRef}>
            <Flex.Item
              as="div"
              position="relative"
              width="25%"
              height="calc(100vh - 10.25rem)"
              overflowY="visible"
              overflowX="auto"
              data-testid="groupsColumnRef"
              elementRef={setLeftColumnRef}
            >
              <View as="div" padding="small x-small none x-small">
                <div style={{paddingBottom: '6px'}}>
                  <Heading level="h3">
                    <Text size="large" weight="light" fontStyle="normal">
                      {I18n.t('Outcome Groups')}
                    </Text>
                  </Heading>
                </div>
                {renderGroupNavigation}
              </View>
            </Flex.Item>
            <Flex.Item
              as="div"
              position="relative"
              width="1%"
              height="calc(100vh - 8.75rem)"
              tabIndex="0"
              role="separator"
              aria-orientation="vertical"
              onKeyDown={onKeyDownHandler}
              elementRef={setDelimiterRef}
            >
              <div
                style={{
                  width: '1vw',
                  height: '100%',
                  cursor: 'col-resize',
                  background:
                    '#EEEEEE url("/images/splitpane_handle-ew.gif") no-repeat scroll 50% 50%',
                }}
              />
            </Flex.Item>
            <Flex.Item
              as="div"
              position="relative"
              width="74%"
              height="calc(100vh - 10.25rem)"
              overflowY="visible"
              overflowX="auto"
              elementRef={setRightColumnRef}
            >
              {selectedGroupId && !rootIds.includes(selectedGroupId) ? (
                findOutcomesView
              ) : (
                <FindOutcomesBillboard />
              )}
            </Flex.Item>
          </Flex>
        ) : (
          <div style={{height: '100%', display: 'flex', flexDirection: 'column', overflow: 'auto'}}>
            <div
              style={{
                flex: '1 0 24rem',
                position: 'relative',
                overflow: 'auto',
                height: '100%',
              }}
              ref={setScrollContainer}
            >
              {renderGroupNavigation}
              {showOutcomesView ? findOutcomesView : isLoading ? null : <FindOutcomesBillboard />}
            </div>
          </div>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          type="button"
          color="primary"
          margin="0 x-small 0 0"
          ref={doneBtnRef}
          onClick={onCloseModalHandler}
        >
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

FindOutcomesModal.propTypes = {
  open: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  targetGroup: PropTypes.shape({
    _id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
  }),
  setTargetGroupIdsToRefetch: PropTypes.func.isRequired,
  importsTargetGroup: PropTypes.object.isRequired,
  setImportsTargetGroup: PropTypes.func.isRequired,
}

export default FindOutcomesModal
