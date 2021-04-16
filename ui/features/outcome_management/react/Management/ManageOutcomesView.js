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

import React from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!OutcomeManagement'
import OutcomeGroupHeader from './OutcomeGroupHeader'
import {Spinner} from '@instructure/ui-spinner'
import ManageOutcomeItem from './ManageOutcomeItem'
import OutcomeSearchBar from './OutcomeSearchBar'
import {addZeroWidthSpace} from '@canvas/outcomes/addZeroWidthSpace'
import InfiniteScroll from '@canvas/infinite-scroll'

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
  loadMore
}) => {
  const groupTitle = outcomeGroup?.title
  const groupDescription = outcomeGroup?.description
  const outcomes = outcomeGroup?.outcomes
  const numOutcomes = outcomeGroup?.outcomesCount
  const canManageGroup = outcomeGroup?.canEdit

  if (loading && !outcomeGroup) {
    return (
      <div style={{textAlign: 'center'}} data-testid="loading">
        <Spinner renderTitle={I18n.t('Loading')} size="large" />
      </div>
    )
  }

  if (!outcomeGroup) return null

  return (
    <View as="div" padding="0 small" minWidth="300px" data-testid="outcome-group-container">
      <InfiniteScroll
        hasMore={outcomes?.pageInfo?.hasNextPage}
        loadMore={loadMore}
        loader={<p>{I18n.t('Loading')} ...</p>}
      >
        <OutcomeGroupHeader
          title={groupTitle}
          description={groupDescription}
          canManage={canManageGroup}
          minWidth="calc(50% + 4.125rem)"
          onMenuHandler={onOutcomeGroupMenuHandler}
        />
        <View as="div" padding="medium 0 xx-small" margin="x-small 0 0">
          <OutcomeSearchBar
            enabled={numOutcomes > 0}
            placeholder={I18n.t('Search within %{groupTitle}', {groupTitle})}
            searchString={searchString}
            onChangeHandler={onSearchChangeHandler}
            onClearHandler={onSearchClearHandler}
          />
        </View>
        <View as="div" padding="small 0">
          <Heading level="h4">
            <div style={{overflowWrap: 'break-word'}}>
              {I18n.t(
                {
                  one: '1 "%{groupTitle}" Outcome',
                  other: '%{count} "%{groupTitle}" Outcomes'
                },
                {
                  count: numOutcomes,
                  groupTitle: addZeroWidthSpace(groupTitle)
                }
              )}
            </div>
          </Heading>
        </View>
        <View as="div" data-testid="outcome-items-list">
          {outcomes?.edges?.map(({canUnlink, node: {_id, title, description, canEdit}}, index) => (
            <ManageOutcomeItem
              key={_id}
              id={_id}
              title={title}
              description={description}
              canManageOutcome={canEdit}
              canUnlink={canUnlink}
              isFirst={index === 0}
              isChecked={!!selectedOutcomes[_id]}
              onMenuHandler={onOutcomeMenuHandler}
              onCheckboxHandler={onSelectOutcomesHandler}
            />
          ))}
        </View>
      </InfiniteScroll>
    </View>
  )
}

ManageOutcomesView.propTypes = {
  outcomeGroup: PropTypes.shape({
    _id: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    description: PropTypes.string,
    outcomesCount: PropTypes.number.isRequired,
    canEdit: PropTypes.bool.isRequired,
    outcomes: PropTypes.shape({
      edges: PropTypes.arrayOf(
        PropTypes.shape({
          canUnlink: PropTypes.bool.isRequired,
          node: PropTypes.shape({
            _id: PropTypes.string.isRequired,
            title: PropTypes.string.isRequired,
            description: PropTypes.string,
            canEdit: PropTypes.bool.isRequired,
            contextType: PropTypes.string,
            contextId: PropTypes.number
          })
        })
      ),
      pageInfo: PropTypes.shape({
        endCursor: PropTypes.string,
        hasNextPage: PropTypes.bool.isRequired
      })
    }).isRequired
  }),
  loading: PropTypes.bool.isRequired,
  selectedOutcomes: PropTypes.object.isRequired,
  searchString: PropTypes.string.isRequired,
  onSelectOutcomesHandler: PropTypes.func.isRequired,
  onOutcomeGroupMenuHandler: PropTypes.func.isRequired,
  onOutcomeMenuHandler: PropTypes.func.isRequired,
  onSearchChangeHandler: PropTypes.func.isRequired,
  onSearchClearHandler: PropTypes.func.isRequired,
  loadMore: PropTypes.func.isRequired
}

export default ManageOutcomesView
