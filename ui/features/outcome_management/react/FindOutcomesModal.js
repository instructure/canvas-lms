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
import I18n from 'i18n!FindOutcomesModal'
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
import useOutcomesImport from '@canvas/outcomes/react/hooks/useOutcomesImport'

const FindOutcomesModal = ({open, onCloseHandler, targetGroup}) => {
  const {isMobileView, isCourse, rootOutcomeGroup, rootIds} = useCanvasContext()
  const [showOutcomesView, setShowOutcomesView] = useState(false)
  const [scrollContainer, setScrollContainer] = useState(null)
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
    loadedGroups
  } = useFindOutcomeModal(open)

  const {group, loading, loadMore} = useGroupDetail({
    id: selectedGroupId,
    query: FIND_GROUP_OUTCOMES,
    loadOutcomesIsImported: true,
    searchString: debouncedSearchString,
    targetGroupId: rootOutcomeGroup?.id
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
    clearGroupsStatus,
    clearOutcomesStatus,
    hasAddedOutcomes,
    setHasAddedOutcomes
  } = useOutcomesImport()

  const onCloseModalHandler = () => {
    clearGroupsStatus()
    clearOutcomesStatus()
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

  const onAddAllHandler = () => {
    const callImportApiToGroup = () => {
      importOutcomes({
        targetGroupId: targetGroup?._id,
        targetGroupTitle: targetGroup?.title,
        outcomeOrGroupId: selectedGroupId,
        groupTitle: group.title
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
        }
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
      sourceContextType
    })
  }

  const modalLabel = targetGroup
    ? I18n.t('Add Outcomes to "%{groupName}"', {
        groupName: targetGroup.title
      })
    : isCourse
    ? I18n.t('Add Outcomes to Course')
    : I18n.t('Add Outcomes to Account')

  const findOutcomesView = (
    <FindOutcomesView
      outcomesGroup={group}
      collection={collections[selectedGroupId]}
      searchString={searchString}
      onChangeHandler={updateSearch}
      onClearHandler={clearSearch}
      disableAddAllButton={isConfirmBoxOpen}
      importGroupStatus={importGroupsStatus[selectedGroupId]}
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
                error
              })
            : I18n.t('An error occurred while loading account outcomes: %{error}', {
                error
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
      shouldReturnFocus
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
              aria-hidden="true"
              onKeyDown={onKeyDownHandler}
              elementRef={setDelimiterRef}
            >
              <div
                style={{
                  width: '1vw',
                  height: '100%',
                  cursor: 'col-resize',
                  background:
                    '#EEEEEE url("/images/splitpane_handle-ew.gif") no-repeat scroll 50% 50%'
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
                height: '100%'
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
    title: PropTypes.string.isRequired
  })
}

export default FindOutcomesModal
