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

import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import AlignmentSummaryHeader from './AlignmentSummaryHeader'
import AlignmentOutcomeItemList from './AlignmentOutcomeItemList'
import useSearch from '@canvas/outcomes/react/hooks/useSearch'

// Sample data - remove after integration with graphql
import {
  totalOutcomes,
  alignedOutcomes,
  totalAlignments,
  totalArtifacts,
  alignedArtifacts,
  generateOutcomes
} from './__tests__/testData'

const AlignmentSummary = () => {
  const {search, onChangeHandler, onClearHandler} = useSearch()
  const [scrollContainer, setScrollContainer] = useState(null)

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
              searchString={search}
              updateSearchHandler={onChangeHandler}
              clearSearchHandler={onClearHandler}
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
        height="40vh"
        elementRef={el => setScrollContainer(el)}
      >
        <AlignmentOutcomeItemList
          outcomes={generateOutcomes(5)}
          scrollContainer={scrollContainer}
        />
      </View>
    </View>
  )
}

export default AlignmentSummary
