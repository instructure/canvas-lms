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
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AlignmentStatItem from './AlignmentStatItem'
import OutcomeSearchBar from '../Management/OutcomeSearchBar'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentSummaryHeader = ({
  totalOutcomes,
  alignedOutcomes,
  totalAlignments,
  totalArtifacts,
  alignedArtifacts,
  searchString,
  updateSearchHandler,
  clearSearchHandler
}) => {
  const [selectedFilter, setSelectedFilter] = useState('all_outcomes')
  const percentCoverage = totalOutcomes !== 0 ? alignedOutcomes / totalOutcomes : 0
  const avgPerOutcome = totalOutcomes !== 0 ? totalAlignments / totalOutcomes : 0
  const percentWithAlignments = totalArtifacts !== 0 ? alignedArtifacts / totalArtifacts : 0
  const avgPerArtifact = totalArtifacts !== 0 ? totalAlignments / totalArtifacts : 0
  const withAlignments = totalOutcomes !== 0 ? alignedOutcomes : 0
  const withoutAlignments = totalOutcomes !== 0 ? totalOutcomes - alignedOutcomes : 0

  const handleFilterChange = (_event, {id}) => setSelectedFilter(id)

  const renderFilter = () => {
    const filterOptions = {
      all_outcomes: {
        label: I18n.t('All Outcomes'),
        value: totalOutcomes || 0
      },
      with_alignments: {
        label: I18n.t('With Alignments'),
        value: withAlignments
      },
      without_alignments: {
        label: I18n.t('Without Alignments'),
        value: withoutAlignments
      }
    }

    return (
      <SimpleSelect
        renderLabel={<ScreenReaderContent>{I18n.t('Filter Outcomes')}</ScreenReaderContent>}
        value={filterOptions[selectedFilter].label}
        onChange={handleFilterChange}
      >
        {Object.keys(filterOptions).map(key => (
          <SimpleSelect.Option key={key} id={key} value={filterOptions[key].label}>
            {`${filterOptions[key].label} (${filterOptions[key].value})`}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    )
  }

  return (
    <Flex
      as="div"
      direction="column"
      position="relative"
      data-testid="outcome-alignment-summary-header"
    >
      <Flex.Item as="div">
        <Flex as="div" wrap="wrap">
          <Flex.Item size="28rem" padding="x-small small x-small x-small">
            <AlignmentStatItem
              type="outcome"
              count={totalOutcomes}
              percent={percentCoverage}
              average={avgPerOutcome}
            />
          </Flex.Item>
          <Flex.Item size="28rem" padding="x-small small x-small x-small">
            <AlignmentStatItem
              type="artifact"
              count={totalArtifacts}
              percent={percentWithAlignments}
              average={avgPerArtifact}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item as="div" padding="small 0 0">
        <Flex as="div" wrap="wrap">
          <Flex.Item padding="x-small small x-small x-small" size="17rem">
            {renderFilter()}
          </Flex.Item>
          <Flex.Item padding="x-small" size="28rem" shouldGrow>
            <OutcomeSearchBar
              placeholder={I18n.t('Search...')}
              searchString={searchString}
              onChangeHandler={updateSearchHandler}
              onClearHandler={clearSearchHandler}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

AlignmentSummaryHeader.propTypes = {
  totalOutcomes: PropTypes.number.isRequired,
  alignedOutcomes: PropTypes.number.isRequired,
  totalAlignments: PropTypes.number.isRequired,
  totalArtifacts: PropTypes.number.isRequired,
  alignedArtifacts: PropTypes.number.isRequired,
  searchString: PropTypes.string,
  updateSearchHandler: PropTypes.func.isRequired,
  clearSearchHandler: PropTypes.func.isRequired
}

export default AlignmentSummaryHeader
