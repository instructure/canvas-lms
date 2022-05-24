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
import {outcomeWithAlignmentShape} from './propTypeShapes'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentOutcomeItemList = ({outcomes, loading, hasMore, loadMore, scrollContainer}) => {
  const outcomesCount = outcomes?.length || 0

  const renderSearchLoader = () => (
    <div style={{textAlign: 'center'}} data-testid="loading">
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
    <View as="div" minWidth="300px" data-testid="alignment-items-list-container">
      {outcomesCount === 0 ? (
        renderNoSearchResults()
      ) : (
        <InfiniteScroll
          hasMore={hasMore}
          loadMore={loadMore}
          loader={renderInfiniteScrollLoader()}
          scrollContainer={scrollContainer}
        >
          <View as="div" data-testid="alignment-items-list">
            {outcomes?.map(({id, title, description, alignments}) => (
              <AlignmentOutcomeItem
                key={id}
                title={title}
                description={description}
                alignments={alignments}
              />
            ))}
          </View>
        </InfiniteScroll>
      )}
    </View>
  )
}

AlignmentOutcomeItemList.defaultProps = {
  hasMore: true,
  loadMore: () => {}
}

AlignmentOutcomeItemList.propTypes = {
  outcomes: PropTypes.arrayOf(outcomeWithAlignmentShape),
  scrollContainer: PropTypes.instanceOf(Element),
  hasMore: PropTypes.bool,
  loading: PropTypes.bool,
  loadMore: PropTypes.func
}

export default AlignmentOutcomeItemList
