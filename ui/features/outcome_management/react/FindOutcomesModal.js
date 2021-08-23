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
import {useFindOutcomeModal, ACCOUNT_FOLDER_ID} from '@canvas/outcomes/react/treeBrowser'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'
import useResize from '@canvas/outcomes/react/hooks/useResize'
import useModal from '@canvas/outcomes/react/hooks/useModal'
import {FIND_GROUP_OUTCOMES} from '@canvas/outcomes/graphql/Management'
import GroupActionDrillDown from './shared/GroupActionDrillDown'
import useOutcomesImport from '@canvas/outcomes/react/hooks/useOutcomesImport'

const FindOutcomesModal = ({open, onCloseHandler}) => {
  const {isMobileView, isCourse} = useCanvasContext()
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
    searchString: debouncedSearchString
  })

  const {setContainerRef, setLeftColumnRef, setDelimiterRef, setRightColumnRef, onKeyDownHandler} =
    useResize()
  const [isConfirmBoxOpen, openConfirmBox, closeConfirmBox] = useModal()

  const {
    importOutcomes,
    importGroupsStatus,
    importOutcomesStatus,
    clearGroupsStatus,
    clearOutcomesStatus
  } = useOutcomesImport()

  const onCloseModalHandler = () => {
    clearGroupsStatus()
    clearOutcomesStatus()
    onCloseHandler()
  }

  const onAddAllHandler = () => {
    if (isCourse && !isConfirmBoxOpen && group.outcomesCount > 50) {
      openConfirmBox()
      showImportConfirmBox({
        count: group.outcomesCount,
        onImportHandler: () => importOutcomes(selectedGroupId),
        onCloseHandler: closeConfirmBox
      })
    } else {
      importOutcomes(selectedGroupId)
    }
  }

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
      importOutcomeHandler={importOutcomes}
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
      label={isCourse ? I18n.t('Add Outcomes to Course') : I18n.t('Add Outcomes to Account')}
      shouldCloseOnDocumentClick={false}
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
                <Heading level="h3">
                  <Text size="large" weight="light" fontStyle="normal">
                    {I18n.t('Outcome Groups')}
                  </Text>
                </Heading>
                {renderGroupNavigation}
              </View>
            </Flex.Item>
            <Flex.Item
              as="div"
              position="relative"
              width="1%"
              height="calc(100vh - 10.25rem)"
              margin="xxx-small 0 0"
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
              position="relative"
              width="74%"
              height="calc(100vh - 10.25rem)"
              overflowY="visible"
              overflowX="auto"
              elementRef={setRightColumnRef}
            >
              {selectedGroupId && selectedGroupId !== ACCOUNT_FOLDER_ID ? (
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
        <Button type="button" color="primary" margin="0 x-small 0 0" onClick={onCloseModalHandler}>
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
