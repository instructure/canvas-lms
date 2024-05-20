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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import OutcomeGroupHeader from './OutcomeGroupHeader'
import ManageOutcomeItem from './ManageOutcomeItem'
import OutcomeSearchBar from './OutcomeSearchBar'
import SearchBreadcrumb from '../shared/SearchBreadcrumb'
import InfiniteScroll from '@canvas/infinite-scroll'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import SVGWrapper from '@canvas/svg-wrapper'
import {ratingsShape} from './shapes'

const I18n = useI18nScope('OutcomeManagement')

const ManageOutcomesView = ({
  outcomeGroup,
  selectedOutcomes,
  searchString,
  onSelectOutcomesHandler,
  onOutcomeGroupMenuHandler,
  onOutcomeMenuHandler,
  onSearchChangeHandler,
  onSearchClearHandler,
  loading,
  loadMore,
  removeOutcomesStatus,
  scrollContainer,
  isRootGroup,
  hideOutcomesView,
}) => {
  const {canManage, isMobileView} = useCanvasContext()
  const groupTitle = outcomeGroup?.title
  const groupDescription = outcomeGroup?.description
  const outcomes = outcomeGroup?.outcomes
  const outcomesCount = outcomeGroup?.outcomesCount

  const [isEnhanced, setIsEnhanced] = useState(false)

  useEffect(() => {
    // for rendering math equations in outcome descriptions
    setIsEnhanced(!isEnhanced)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [outcomes, selectedOutcomes])

  if (loading && !outcomeGroup) {
    return (
      <div style={{textAlign: 'center'}} data-testid="loading">
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }

  if (!outcomeGroup) return null

  return (
    <View
      as="div"
      padding={isMobileView ? '0' : '0 small'}
      minWidth={isMobileView ? '' : '300px'}
      data-testid="outcome-group-container"
    >
      <InfiniteScroll
        hasMore={outcomes?.pageInfo?.hasNextPage}
        loadMore={loadMore}
        loader={<p>{I18n.t('Loading')} ...</p>}
        scrollContainer={scrollContainer}
      >
        <OutcomeGroupHeader
          title={groupTitle}
          description={groupDescription}
          canManage={isRootGroup ? false : canManage}
          minWidth="calc(50% + 4.125rem)"
          onMenuHandler={onOutcomeGroupMenuHandler}
          hideOutcomesView={hideOutcomesView}
        />
        <View
          as="div"
          padding={isMobileView ? 'small 0 xx-small' : 'medium 0 xx-small'}
          margin={isMobileView ? '0' : 'x-small 0 0'}
        >
          <OutcomeSearchBar
            enabled={outcomesCount > 0 || searchString.length > 0}
            placeholder={I18n.t('Search within %{groupTitle}', {groupTitle})}
            searchString={searchString}
            onChangeHandler={onSearchChangeHandler}
            onClearHandler={onSearchClearHandler}
          />
        </View>
        <View as="div" padding={isMobileView ? 'small 0 0' : 'small 0'} borderWidth="0 0 small">
          <Flex as="div" alignItems="center" justifyItems="space-between" wrap="wrap">
            <Flex.Item size="50%" shouldGrow={true}>
              <SearchBreadcrumb
                groupTitle={groupTitle}
                searchString={searchString}
                loading={loading}
              />
            </Flex.Item>
            <Flex.Item as="div" padding="xx-small 0">
              <Text size="medium" weight="bold">
                {I18n.t(
                  {
                    one: '%{count} Outcome',
                    other: '%{count} Outcomes',
                  },
                  {
                    count: outcomesCount || 0,
                  }
                )}
              </Text>
            </Flex.Item>
          </Flex>
        </View>
        <View as="div" data-testid="outcome-items-list">
          {outcomes?.edges?.length === 0 &&
            !loading &&
            (searchString ? (
              <View as="div" textAlign="center" margin="small 0 0">
                <Text color="primary">{I18n.t('The search returned no results.')}</Text>
              </View>
            ) : (
              <View as="div" textAlign="center" margin="large 0 0">
                <PresentationContent>
                  <div data-testid="no-outcomes-svg">
                    <SVGWrapper url="/images/outcomes/no_outcomes.svg" />
                  </div>
                </PresentationContent>
                <View as="div" padding="small 0 0">
                  <Text color="primary">{I18n.t('There are no outcomes in this group.')}</Text>
                </View>
              </View>
            ))}
          {outcomes?.edges?.map(
            ({
              canUnlink,
              _id: linkId,
              node: {
                _id,
                title,
                description,
                calculationMethod,
                calculationInt,
                masteryPoints,
                ratings,
                friendlyDescription,
                contextType,
                contextId,
                canArchive,
              },
            }) => (
              <ManageOutcomeItem
                key={linkId}
                _id={_id}
                linkId={linkId}
                title={title}
                description={description}
                calculationMethod={calculationMethod}
                calculationInt={calculationInt}
                masteryPoints={masteryPoints}
                ratings={ratings}
                friendlyDescription={friendlyDescription?.description}
                outcomeContextType={contextType}
                outcomeContextId={contextId}
                canUnlink={canUnlink}
                isChecked={!!selectedOutcomes[linkId]}
                removeOutcomeStatus={removeOutcomesStatus[linkId]}
                onMenuHandler={onOutcomeMenuHandler}
                onCheckboxHandler={onSelectOutcomesHandler}
                isEnhanced={isEnhanced}
                canArchive={canArchive}
              />
            )
          )}
        </View>
      </InfiniteScroll>
    </View>
  )
}

ManageOutcomesView.defaultProps = {
  hideOutcomesView: () => {},
}

ManageOutcomesView.propTypes = {
  outcomeGroup: PropTypes.shape({
    _id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    description: PropTypes.string,
    outcomesCount: PropTypes.number.isRequired,
    outcomes: PropTypes.shape({
      edges: PropTypes.arrayOf(
        PropTypes.shape({
          _id: PropTypes.string.isRequired,
          canUnlink: PropTypes.bool.isRequired,
          node: PropTypes.shape({
            _id: PropTypes.string.isRequired,
            title: PropTypes.string.isRequired,
            description: PropTypes.string,
            calculationMethod: PropTypes.string,
            calculationInt: PropTypes.number,
            masteryPoints: PropTypes.number,
            ratings: ratingsShape,
            canEdit: PropTypes.bool.isRequired,
            contextType: PropTypes.string,
            contextId: PropTypes.string,
            canArchive: PropTypes.bool,
          }),
        })
      ),
      pageInfo: PropTypes.shape({
        endCursor: PropTypes.string,
        hasNextPage: PropTypes.bool.isRequired,
      }),
    }).isRequired,
  }),
  loading: PropTypes.bool.isRequired,
  selectedOutcomes: PropTypes.object.isRequired,
  searchString: PropTypes.string.isRequired,
  onSelectOutcomesHandler: PropTypes.func.isRequired,
  onOutcomeGroupMenuHandler: PropTypes.func.isRequired,
  onOutcomeMenuHandler: PropTypes.func.isRequired,
  onSearchChangeHandler: PropTypes.func.isRequired,
  onSearchClearHandler: PropTypes.func.isRequired,
  loadMore: PropTypes.func.isRequired,
  removeOutcomesStatus: PropTypes.object.isRequired,
  scrollContainer: PropTypes.instanceOf(Element),
  isRootGroup: PropTypes.bool.isRequired,
  hideOutcomesView: PropTypes.func,
}

export default ManageOutcomesView
