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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import I18n from 'i18n!OutcomeManagement'
import {isRTL} from '@canvas/i18n/rtlHelper'
import FindOutcomeItem from './FindOutcomeItem'
import OutcomeSearchBar from './Management/OutcomeSearchBar'
import InfiniteScroll from '@canvas/infinite-scroll'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {IconArrowOpenEndSolid} from '@instructure/ui-icons'
import {outcomeGroupShape, groupCollectionShape} from './Management/shapes'
import {IMPORT_NOT_STARTED, IMPORT_FAILED} from '@canvas/outcomes/react/hooks/useOutcomesImport'

const FindOutcomesView = ({
  outcomesGroup,
  collection,
  loading,
  loadMore,
  searchString,
  disableAddAllButton,
  onChangeHandler,
  onClearHandler,
  onAddAllHandler,
  mobileScrollContainer,
  importGroupStatus,
  importOutcomesStatus,
  importOutcomeHandler
}) => {
  const groupTitle = collection?.name || I18n.t('Outcome Group')
  const isRootGroup = collection?.isRootGroup
  const outcomesCount = outcomesGroup?.outcomesCount || 0
  const outcomes = outcomesGroup?.outcomes
  const enabled =
    !!outcomesCount &&
    outcomesCount > 0 &&
    [IMPORT_NOT_STARTED, IMPORT_FAILED].includes(importGroupStatus)
  const [scrollContainer, setScrollContainer] = useState(null)
  const {isMobileView} = useCanvasContext()

  const countAndAddButton = (
    <Flex.Item>
      <Flex
        as="div"
        alignItems="center"
        justifyItems={isMobileView ? 'space-between' : 'start'}
        width={isMobileView ? '100vw' : ''}
        wrap="wrap"
      >
        <Flex.Item
          as="div"
          padding={
            isMobileView
              ? 'x-small 0'
              : isRootGroup
              ? 'x-small 0'
              : searchString.length === 0
              ? 'x-small medium x-small 0'
              : 'x-small 0'
          }
        >
          <Text size="medium">
            {I18n.t(
              {
                one: '%{count} Outcome',
                other: '%{count} Outcomes'
              },
              {
                count: outcomesCount || 0
              }
            )}
          </Text>
        </Flex.Item>
        {searchString.length === 0 && !isRootGroup && (
          <Flex.Item>
            <Button
              margin="x-small 0"
              interaction={
                enabled && !searchString && !disableAddAllButton ? 'enabled' : 'disabled'
              }
              onClick={onAddAllHandler}
            >
              {I18n.t('Add All Outcomes')}
            </Button>
          </Flex.Item>
        )}
      </Flex>
    </Flex.Item>
  )

  const searchAndSelectContainer = (
    <View as="div" padding="0 0 x-small" borderWidth="0 0 small">
      {!isMobileView && (
        <View as="div" padding={isMobileView ? 'x-small 0 0' : 'small 0 0'}>
          <Heading level="h2" as="h3">
            <Text wrap="break-word" weight={isMobileView ? 'bold' : 'normal'}>
              {addZeroWidthSpace(groupTitle)}
            </Text>
          </Heading>
        </View>
      )}
      <View as="div" padding={isMobileView ? 'x-small 0' : 'large 0 medium'}>
        <OutcomeSearchBar
          enabled={enabled || searchString.length > 0}
          placeholder={I18n.t('Search within %{groupTitle}', {groupTitle})}
          searchString={searchString}
          onChangeHandler={onChangeHandler}
          onClearHandler={onClearHandler}
        />
      </View>
      <View as="div" position="relative" padding={isMobileView ? '0 0 0 xx-small' : '0 0 small'}>
        <Flex as="div" alignItems="center" justifyItems="space-between" wrap="wrap">
          <Flex.Item size="50%" shouldGrow>
            <Heading level="h4">
              {searchString ? (
                <Flex>
                  <Flex.Item shouldShrink>
                    <div
                      style={{
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        padding: '0.375rem 0'
                      }}
                    >
                      <View data-testid="group-name-ltr">
                        {isRTL() ? searchString : groupTitle}
                      </View>
                      <div
                        style={{
                          display: 'inline-block',
                          transform: 'scale(0.6)',
                          height: '1em'
                        }}
                      >
                        <IconArrowOpenEndSolid title={I18n.t('search results for')} />
                      </div>
                      <View data-testid="search-string-ltr">
                        {isRTL() ? groupTitle : searchString}
                      </View>
                    </div>
                  </Flex.Item>
                  <Flex.Item size="2.5rem">
                    {loading && (
                      <Spinner
                        renderTitle={I18n.t('Loading')}
                        size="x-small"
                        margin="0 0 0 x-small"
                        data-testid="search-loading"
                      />
                    )}
                  </Flex.Item>
                </Flex>
              ) : (
                <View as="div" padding="xx-small 0">
                  <Text wrap="break-word">
                    {I18n.t('All %{groupTitle} Outcomes', {
                      groupTitle: addZeroWidthSpace(groupTitle)
                    })}
                  </Text>
                </View>
              )}
            </Heading>
          </Flex.Item>
          {countAndAddButton}
        </Flex>
      </View>
    </View>
  )
  if (loading && !outcomes) {
    return (
      <View as="div" padding="xx-large 0" textAlign="center" margin="0 auto" data-testid="loading">
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </View>
    )
  }

  return (
    <View
      as="div"
      height="100%"
      minWidth="300px"
      padding={isMobileView ? '0 small' : '0 x-large 0 medium'}
      data-testid="find-outcome-container"
    >
      <div
        style={
          isMobileView
            ? {}
            : {height: '100%', display: 'flex', flexDirection: 'column', overflow: 'auto'}
        }
      >
        {!isMobileView && searchAndSelectContainer}
        <div
          style={isMobileView ? {} : {flex: '1 0 24rem', position: 'relative', overflow: 'auto'}}
          ref={setScrollContainer}
        >
          <InfiniteScroll
            hasMore={outcomes?.pageInfo?.hasNextPage}
            loadMore={loadMore}
            scrollContainer={mobileScrollContainer || scrollContainer}
            loader={
              <Flex
                as="div"
                justifyItems="center"
                alignItems="center"
                padding="medium 0 small"
                shouldGrow
              >
                <Flex.Item>
                  {loading ? (
                    <View as="div" data-testid="load-more-loading">
                      <Spinner renderTitle={I18n.t('Loading')} size="small" />
                    </View>
                  ) : (
                    <Button type="button" color="primary" margin="0 x-small 0 0" onClick={loadMore}>
                      {I18n.t('Load More')}
                    </Button>
                  )}
                </Flex.Item>
              </Flex>
            }
          >
            {isMobileView && searchAndSelectContainer}
            <View as="div" data-testid="find-outcome-items-list">
              {outcomes?.edges?.length === 0 && searchString && !loading && (
                <View as="div" textAlign="center" margin="small 0 0">
                  <Text color="primary">{I18n.t('The search returned no results.')}</Text>
                </View>
              )}
              {outcomes?.edges?.map(
                ({_id: linkId, node: {_id, title, description, isImported}}, index) => (
                  <FindOutcomeItem
                    key={linkId}
                    id={_id}
                    title={title}
                    description={description}
                    isFirst={index === 0}
                    importOutcomeStatus={importOutcomesStatus?.[_id]}
                    isImported={isImported}
                    importGroupStatus={importGroupStatus}
                    sourceContextId={String(outcomesGroup.contextId)}
                    sourceContextType={outcomesGroup.contextType}
                    importOutcomeHandler={importOutcomeHandler}
                  />
                )
              )}
            </View>
          </InfiniteScroll>
        </div>
      </div>
    </View>
  )
}

FindOutcomesView.defaultProps = {
  collection: {
    id: '0',
    name: '',
    isRootGroup: false
  },
  importGroupStatus: IMPORT_NOT_STARTED,
  mobileScrollContainer: null
}

FindOutcomesView.propTypes = {
  collection: groupCollectionShape,
  outcomesGroup: outcomeGroupShape,
  searchString: PropTypes.string.isRequired,
  disableAddAllButton: PropTypes.bool,
  onChangeHandler: PropTypes.func.isRequired,
  onClearHandler: PropTypes.func.isRequired,
  onAddAllHandler: PropTypes.func.isRequired,
  loading: PropTypes.bool.isRequired,
  loadMore: PropTypes.func.isRequired,
  mobileScrollContainer: PropTypes.instanceOf(Element),
  importGroupStatus: PropTypes.string,
  importOutcomesStatus: PropTypes.object.isRequired,
  importOutcomeHandler: PropTypes.func.isRequired
}

export default FindOutcomesView
