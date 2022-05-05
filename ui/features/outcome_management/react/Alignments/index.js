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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import AlignmentSummaryHeader from './AlignmentSummaryHeader'
import AlignmentOutcomeItem from './AlignmentOutcomeItem'
import useSearch from '@canvas/outcomes/react/hooks/useSearch'

const AlignmentSummary = () => {
  const {search, onChangeHandler, onClearHandler} = useSearch()

  // Sample data; remove after integration with backend
  const totalOutcomes = 4200
  const alignedOutcomes = 3900
  const totalAlignments = 6800
  const totalArtifacts = 2400
  const alignedArtifacts = 2000
  const title = 'Outcome 123 '.repeat(3)
  const description = 'Outcome description '.repeat(10)
  const alignmentCount = 15

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
      <View as="div">
        <AlignmentOutcomeItem
          title={title}
          description={description}
          alignmentCount={alignmentCount}
        />
      </View>
    </View>
  )
}

export default AlignmentSummary
