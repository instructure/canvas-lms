/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import AlignmentOutcomeItem from './AlignmentOutcomeItem'
import InfiniteScroll from '@canvas/infinite-scroll'
import SVGWrapper from '@canvas/svg-wrapper'
import {groupDataShape} from './propTypeShapes'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentOutcomeItemList = ({rootGroup, loading, loadMore, scrollContainer}) => {
  const outcomes = rootGroup?.outcomes
  const hasOutcomes = outcomes?.edges?.length > 0
  const hasMoreOutcomes = outcomes?.pageInfo?.hasNextPage

  const renderSearchLoader = () => (
    <div style={{textAlign: 'center'}} data-testid="outcome-item-list-loader">
      <Spinner renderTitle={I18n.t('Loading')} size="large" />
    </div>
  )

  const renderInfiniteScrollLoader = () => (
    <div style={{paddingTop: '0.75rem', textAlign: 'center'}}>
      <Spinner renderTitle={I18n.t('Loading')} size="small" />
    </div>
  )

  const renderNoSearchResults = () => (
    <View as="div" textAlign="center" margin="large 0 0">
      <PresentationContent>
        <View as="div" data-testid="no-outcomes-icon">
          <SVGWrapper url="/images/outcomes/no_outcomes.svg" />
        </View>
      </PresentationContent>
      <View as="div" padding="small 0 0">
        <Text color="primary">{I18n.t('Your search returned no results.')}</Text>
      </View>
    </View>
  )

  if (loading) return renderSearchLoader()

  return (
    <View as="div" minWidth="260px" data-testid="alignment-items-list-container">
      {hasOutcomes ? (
        <InfiniteScroll
          hasMore={hasMoreOutcomes}
          loadMore={loadMore}
          loader={renderInfiniteScrollLoader()}
          scrollContainer={scrollContainer}
        >
          <View as="div" data-testid="alignment-items-list">
            {(outcomes?.edges || []).map(({node: {_id, title, description, alignments}}) => (
              <AlignmentOutcomeItem
                key={_id}
                title={title}
                description={description}
                alignments={alignments}
              />
            ))}
          </View>
        </InfiniteScroll>
      ) : (
        renderNoSearchResults()
      )}
    </View>
  )
}

AlignmentOutcomeItemList.defaultProps = {
  loadMore: () => {},
}

AlignmentOutcomeItemList.propTypes = {
  rootGroup: groupDataShape,
  scrollContainer: PropTypes.instanceOf(Element),
  loading: PropTypes.bool,
  loadMore: PropTypes.func,
}

export default AlignmentOutcomeItemList
