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

import React, {useCallback, useState} from 'react'
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

const FindOutcomesView = ({
  collection,
  outcomesCount,
  outcomes,
  loading,
  loadMore,
  searchString,
  onChangeHandler,
  onClearHandler,
  onAddAllHandler
}) => {
  const groupTitle = collection?.name || I18n.t('Outcome Group')
  const enabled = !!outcomesCount && outcomesCount > 0
  const [scrollContainer, setScrollContainer] = useState(null)
  const {isMobileView} = useCanvasContext()

  const onSelectOutcomesHandler = useCallback(_id => {
    // TODO: OUT-4154
  }, [])

  const countAndAddButton = (
    <Flex.Item>
      <Flex
        as="div"
        alignItems="center"
        justifyItems={isMobileView ? 'space-between' : 'start'}
        width={isMobileView ? '100vw' : ''}
        wrap="wrap"
      >
        <Flex.Item as="div" padding={isMobileView ? 'x-small 0' : 'x-small medium x-small 0'}>
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
        <Flex.Item>
          <Button
            margin="x-small 0"
            interaction={enabled && !searchString ? 'enabled' : 'disabled'}
            onClick={onAddAllHandler}
          >
            {I18n.t('Add All Outcomes')}
          </Button>
        </Flex.Item>
      </Flex>
    </Flex.Item>
  )

  const searchAndSelectContainer = (
    <View as="div" padding="0 0 x-small" borderWidth="0 0 small">
      <View as="div" padding={isMobileView ? 'x-small 0 0' : 'small 0 0'}>
        <Heading level="h2" as="h3">
          <Text wrap="break-word" weight={isMobileView ? 'bold' : 'normal'}>
            {addZeroWidthSpace(groupTitle)}
          </Text>
        </Heading>
      </View>
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
      padding={!isMobileView ? '0 x-large 0 medium' : '0'}
      data-testid="find-outcome-container"
    >
      <div style={{height: '100%', display: 'flex', flexDirection: 'column'}}>
        {!isMobileView && searchAndSelectContainer}
        <div
          style={{
            flex: '1 0 24rem',
            overflow: isMobileView ? 'visible' : 'auto',
            position: 'relative'
          }}
          ref={setScrollContainer}
        >
          <InfiniteScroll
            hasMore={outcomes?.pageInfo?.hasNextPage}
            loadMore={loadMore}
            scrollContainer={scrollContainer}
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
                  <Text color="secondary">{I18n.t('The search returned no results')}</Text>
                </View>
              )}

              {outcomes?.edges?.map(({node: {_id, title, description, isImported}}, index) => (
                <FindOutcomeItem
                  key={_id}
                  id={_id}
                  title={title}
                  description={description}
                  isFirst={index === 0}
                  isChecked={isImported}
                  onCheckboxHandler={onSelectOutcomesHandler}
                />
              ))}
            </View>
          </InfiniteScroll>
        </div>
      </div>
    </View>
  )
}

FindOutcomesView.propTypes = {
  collection: PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired
  }).isRequired,
  outcomesCount: PropTypes.number.isRequired,
  outcomes: PropTypes.shape({
    edges: PropTypes.arrayOf(
      PropTypes.shape({
        node: PropTypes.shape({
          _id: PropTypes.string.isRequired,
          title: PropTypes.string.isRequired,
          isImported: PropTypes.bool.isRequired,
          description: PropTypes.string
        })
      })
    ),
    pageInfo: PropTypes.shape({
      endCursor: PropTypes.string,
      hasNextPage: PropTypes.bool.isRequired
    })
  }),
  searchString: PropTypes.string.isRequired,
  onChangeHandler: PropTypes.func.isRequired,
  onClearHandler: PropTypes.func.isRequired,
  onAddAllHandler: PropTypes.func.isRequired,
  loading: PropTypes.bool.isRequired,
  loadMore: PropTypes.func.isRequired
}

export default FindOutcomesView
