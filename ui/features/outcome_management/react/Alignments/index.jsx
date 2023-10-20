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

import React, {useEffect, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import AlignmentSummaryHeader from './AlignmentSummaryHeader'
import AlignmentOutcomeItemList from './AlignmentOutcomeItemList'
import useCourseAlignmentStats from '@canvas/outcomes/react/hooks/useCourseAlignmentStats'
import useCourseAlignments from '@canvas/outcomes/react/hooks/useCourseAlignments'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentSummary = () => {
  const [scrollContainer, setScrollContainer] = useState(null)
  const {data: alignmentStatsData, loading: loadingAlignmentStats} = useCourseAlignmentStats()
  const courseAlignmentStats = alignmentStatsData?.course?.outcomeAlignmentStats || {}
  const {
    totalOutcomes,
    alignedOutcomes,
    totalAlignments,
    totalArtifacts,
    alignedArtifacts,
    artifactAlignments,
  } = courseAlignmentStats

  const {
    rootGroup,
    loading: loadingOutcomes,
    loadMore: loadMoreOutcomes,
    searchString,
    onSearchChangeHandler: updateSearch,
    onSearchClearHandler: clearSearch,
    onFilterChangeHandler: updateFilter,
  } = useCourseAlignments(loadingAlignmentStats)

  const [showSingleLoader, setShowSingleLoader] = useState(true)

  useEffect(() => {
    showSingleLoader && !loadingAlignmentStats && !loadingOutcomes && setShowSingleLoader(false)
  }, [showSingleLoader, loadingAlignmentStats, loadingOutcomes, setShowSingleLoader])

  const renderAlignmentSummaryLoader = () => (
    <div style={{textAlign: 'center'}} data-testid="outcome-alignment-summary-loader">
      <Spinner renderTitle={I18n.t('Loading')} size="large" />
    </div>
  )

  if (showSingleLoader) return renderAlignmentSummaryLoader()

  return (
    <View data-testid="outcome-alignment-summary">
      <View as="div" padding="0 0 small" borderWidth="0 0 small">
        <Flex>
          <Flex.Item as="div" size="100%" position="relative">
            <AlignmentSummaryHeader
              totalOutcomes={totalOutcomes}
              alignedOutcomes={alignedOutcomes}
              totalAlignments={totalAlignments}
              totalArtifacts={totalArtifacts}
              alignedArtifacts={alignedArtifacts}
              artifactAlignments={artifactAlignments}
              searchString={searchString}
              updateSearchHandler={updateSearch}
              clearSearchHandler={clearSearch}
              updateFilterHandler={updateFilter}
            />
          </Flex.Item>
        </Flex>
      </View>
      <View
        as="div"
        overflowY="visible"
        overflowX="auto"
        width="100%"
        display="inline-block"
        position="relative"
        height="50vh"
        elementRef={el => setScrollContainer(el)}
      >
        <AlignmentOutcomeItemList
          rootGroup={rootGroup}
          loading={loadingOutcomes}
          loadMore={loadMoreOutcomes}
          scrollContainer={scrollContainer}
        />
      </View>
    </View>
  )
}

export default AlignmentSummary
