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
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import AlignmentStatItem from './AlignmentStatItem'
import OutcomeSearchBar from '../Management/OutcomeSearchBar'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('AlignmentSummary')

const AlignmentSummaryHeader = ({
  totalOutcomes,
  alignedOutcomes,
  totalAlignments,
  totalArtifacts,
  alignedArtifacts,
  artifactAlignments,
  searchString,
  updateSearchHandler,
  clearSearchHandler,
  updateFilterHandler,
}) => {
  const [selectedFilter, setSelectedFilter] = useState('ALL_OUTCOMES')
  const {isMobileView} = useCanvasContext()
  const percentCoverage = totalOutcomes !== 0 ? alignedOutcomes / totalOutcomes : 0
  const avgPerOutcome = totalOutcomes !== 0 ? totalAlignments / totalOutcomes : 0
  const percentWithAlignments = totalArtifacts !== 0 ? alignedArtifacts / totalArtifacts : 0
  const avgPerArtifact = totalArtifacts !== 0 ? artifactAlignments / totalArtifacts : 0
  const withAlignments = totalOutcomes !== 0 ? alignedOutcomes : 0
  const withoutAlignments = totalOutcomes !== 0 ? totalOutcomes - alignedOutcomes : 0
  const [showStats, setShowStats] = useState(false)
  const toggleStats = () => setShowStats(prevState => !prevState)

  const handleFilterChange = (_event, {id}) => {
    setSelectedFilter(id)
    updateFilterHandler(id)
  }

  const renderFilter = () => {
    const filterOptions = {
      ALL_OUTCOMES: {
        label: I18n.t('All Outcomes'),
        value: totalOutcomes || 0,
      },
      WITH_ALIGNMENTS: {
        label: I18n.t('With Alignments'),
        value: withAlignments,
      },
      NO_ALIGNMENTS: {
        label: I18n.t('Without Alignments'),
        value: withoutAlignments,
      },
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

  const renderAlignmentStats = () => (
    <div
      style={{
        display: 'flex',
        flexWrap: 'wrap',
        overflow: isMobileView ? 'hidden' : 'auto',
        justifyItems: 'start',
      }}
    >
      <Flex.Item
        as="div"
        size={isMobileView ? '100%' : '31rem'}
        padding={isMobileView ? 'xx-small x-small x-small' : 'x-small small x-small x-small'}
        shouldGrow={!!isMobileView}
      >
        <AlignmentStatItem
          type="outcome"
          count={totalOutcomes}
          percent={percentCoverage}
          average={avgPerOutcome}
        />
      </Flex.Item>
      <Flex.Item
        as="div"
        size={isMobileView ? '100%' : '31rem'}
        padding={isMobileView ? 'xx-small x-small x-small' : 'x-small small x-small x-small'}
        shouldGrow={!!isMobileView}
      >
        <AlignmentStatItem
          type="artifact"
          count={totalArtifacts}
          percent={percentWithAlignments}
          average={avgPerArtifact}
        />
      </Flex.Item>
    </div>
  )

  const renderResponsiveAlignmentStats = () => {
    const showStatsMsg = I18n.t('Show Outcomes Statistics')
    const hideStatsMsg = I18n.t('Hide Outcomes Statistics')

    return (
      <Flex as="div" direction="column">
        <Flex as="div">
          <Flex.Item as="div" size="2.5rem">
            <Flex as="div" alignItems="start" justifyItems="center">
              <Flex.Item>
                <div style={{padding: '0.3125rem 0'}}>
                  <IconButton
                    size="small"
                    screenReaderLabel={showStats ? hideStatsMsg : showStatsMsg}
                    withBackground={false}
                    withBorder={false}
                    interaction="enabled"
                    onClick={toggleStats}
                    data-testid="alignment-summary-outcome-expand-toggle"
                  >
                    <div style={{display: 'flex', alignSelf: 'center', fontSize: '0.875rem'}}>
                      {!showStats ? (
                        <IconArrowOpenEndLine data-testid="alignment-summary-icon-arrow-right" />
                      ) : (
                        <IconArrowOpenDownLine data-testid="alignment-summary-icon-arrow-down" />
                      )}
                    </div>
                  </IconButton>
                </div>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item size="50%" shouldGrow={true}>
            <div style={{padding: '0.625rem 0'}}>
              <Text>{showStats ? hideStatsMsg : showStatsMsg}</Text>
            </div>
          </Flex.Item>
        </Flex>
        {showStats && renderAlignmentStats()}
      </Flex>
    )
  }

  return (
    <Flex
      as="div"
      direction="column"
      position="relative"
      data-testid="outcome-alignment-summary-header"
    >
      <Flex.Item
        as="div"
        overflowX={isMobileView ? 'hidden' : 'auto'}
        overflowY={isMobileView ? 'hidden' : 'auto'}
      >
        {isMobileView ? renderResponsiveAlignmentStats() : renderAlignmentStats()}
      </Flex.Item>
      <Flex.Item as="div" padding="xx-small 0 0">
        <Flex as="div" wrap="wrap" direction={isMobileView ? 'column' : 'row'}>
          <Flex.Item
            as="div"
            padding={isMobileView ? 'xx-small xx-small xx-small' : 'x-small small x-small x-small'}
            size={isMobileView ? '100%' : '17rem'}
          >
            {renderFilter()}
          </Flex.Item>
          <Flex.Item
            as="div"
            padding={isMobileView ? 'xx-small xx-small small' : 'x-small'}
            size={isMobileView ? '100%' : '17rem'}
            shouldGrow={true}
          >
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

AlignmentSummaryHeader.defaultProps = {
  totalOutcomes: 0,
  alignedOutcomes: 0,
  totalAlignments: 0,
  totalArtifacts: 0,
  alignedArtifacts: 0,
  searchString: '',
}

AlignmentSummaryHeader.propTypes = {
  totalOutcomes: PropTypes.number,
  alignedOutcomes: PropTypes.number,
  totalAlignments: PropTypes.number,
  totalArtifacts: PropTypes.number,
  alignedArtifacts: PropTypes.number,
  artifactAlignments: PropTypes.number,
  searchString: PropTypes.string,
  updateSearchHandler: PropTypes.func.isRequired,
  clearSearchHandler: PropTypes.func.isRequired,
  updateFilterHandler: PropTypes.func.isRequired,
}

export default AlignmentSummaryHeader
