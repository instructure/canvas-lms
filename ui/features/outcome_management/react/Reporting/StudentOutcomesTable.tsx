/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {useState, useMemo} from 'react'
import {View} from '@instructure/ui-view'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine, IconArrowOpenDownLine, IconArrowOpenEndLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import type {Outcome, SortColumn} from './types'
import MasteryBadge from './MasteryBadge'
import OutcomesTableRowExpansion from './OutcomesTableRowExpansion'

const I18n = createI18nScope('outcome_management')

const getAssessedText = (assessedCount: number, totalCount: number): string => {
  if (totalCount === 0) {
    return I18n.t('0 alignments')
  }
  return I18n.t('%{assessed} of %{total} alignments', {
    assessed: assessedCount,
    total: totalCount,
    defaultValue: '%{assessed} of %{total} alignments',
  })
}

/**
 * Comparator functions for sorting outcomes
 */
const sortComparators: Record<SortColumn, (a: Outcome, b: Outcome) => number> = {
  code: (a: Outcome, b: Outcome) => a.code.localeCompare(b.code),

  assessed: (a: Outcome, b: Outcome) => {
    // Outcomes with 0 total alignments come first in ascending order
    const zeroA = a.totalAlignmentsCount === 0
    const zeroB = b.totalAlignmentsCount === 0
    if (zeroA && zeroB) return 0
    if (zeroA) return -1
    if (zeroB) return 1

    const ratioA = a.assessedAlignmentsCount / a.totalAlignmentsCount
    const ratioB = b.assessedAlignmentsCount / b.totalAlignmentsCount
    return ratioA - ratioB
  },

  mastery: (a: Outcome, b: Outcome) => {
    const masteryA = a.masteryScore ?? -Infinity
    const masteryB = b.masteryScore ?? -Infinity
    return masteryA - masteryB
  },
}

interface OutcomesTableRowProps {
  outcome: Outcome
  isExpanded: boolean
  onToggleRowExpansion: (id: number | string) => void
}

const OutcomesTableRow = ({outcome, isExpanded, onToggleRowExpansion}: OutcomesTableRowProps) => {
  const {
    id,
    code,
    name,
    description,
    assessedAlignmentsCount,
    totalAlignmentsCount,
    masteryScore,
    masteryLevel,
  } = outcome
  const [isTooltipShown, setIsTooltipShown] = useState(false)

  return (
    <>
      <Table.Row
        themeOverride={{borderColor: isExpanded ? 'transparent' : undefined}}
        data-testid={`outcome-row-${id}`}
      >
        <Table.Cell themeOverride={{padding: '0'}}>
          <Flex direction="row">
            <View as="div" padding="x-small">
              <IconButton
                withBorder={false}
                withBackground={false}
                onClick={() => onToggleRowExpansion(id)}
                size="small"
                screenReaderLabel={
                  isExpanded
                    ? I18n.t('Collapse %{name}', {name: name})
                    : I18n.t('Expand %{name}', {name: name})
                }
                aria-expanded={isExpanded}
                data-testid={`outcome-expand-button-${id}`}
              >
                {isExpanded ? IconArrowOpenDownLine : IconArrowOpenEndLine}
              </IconButton>
            </View>
            <Flex gap="x-small" alignItems="center" padding="x-small 0">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Text weight="bold">{code}</Text> <Text>{name}</Text>
              </Flex.Item>
              <Flex.Item shouldShrink={false}>
                <Tooltip
                  renderTip={description}
                  placement="top"
                  on="click"
                  isShowingContent={isTooltipShown}
                  onShowContent={() => setIsTooltipShown(true)}
                >
                  <IconButton
                    size="small"
                    withBackground={false}
                    withBorder={false}
                    color="primary"
                    screenReaderLabel={I18n.t('Show outcome information')}
                    data-testid={`outcome-info-button-${id}`}
                    onBlur={() => {
                      setIsTooltipShown(false)
                    }}
                  >
                    <IconInfoLine />
                  </IconButton>
                </Tooltip>
              </Flex.Item>
            </Flex>
          </Flex>
        </Table.Cell>
        <Table.Cell>
          <View as="div" padding="x-small 0">
            <Text>{getAssessedText(assessedAlignmentsCount, totalAlignmentsCount)}</Text>
          </View>
        </Table.Cell>
        <Table.Cell>
          <View as="div" padding="x-small 0">
            <MasteryBadge masteryLevel={masteryLevel} score={masteryScore} />
          </View>
        </Table.Cell>
      </Table.Row>
      {isExpanded && (
        <Table.Row>
          <Table.Cell colSpan={3}>
            <OutcomesTableRowExpansion outcomeId={id} />
          </Table.Cell>
        </Table.Row>
      )}
    </>
  )
}

interface StudentOutcomesTableProps {
  outcomes: Outcome[]
}

const StudentOutcomesTable = ({outcomes = []}: StudentOutcomesTableProps) => {
  const [expandedRows, setExpandedRows] = useState<Set<number | string>>(new Set())
  const [sortColumn, setSortColumn] = useState<SortColumn>('code')
  const [sortDirection, setSortDirection] = useState<'ascending' | 'descending'>('ascending')

  const toggleRowExpansion = (id: number | string) => {
    setExpandedRows(prev => {
      const newSet = new Set(prev)
      if (newSet.has(id)) {
        newSet.delete(id)
      } else {
        newSet.add(id)
      }
      return newSet
    })
  }

  const handleSort = (column: SortColumn) => {
    if (sortColumn === column) {
      setSortDirection(prev => (prev === 'ascending' ? 'descending' : 'ascending'))
    } else {
      setSortColumn(column)
      setSortDirection('ascending')
    }
  }

  const sortedOutcomes = useMemo(() => {
    const comparator = sortComparators[sortColumn]
    return [...outcomes].sort((a, b) => {
      const comparison = comparator(a, b)
      return sortDirection === 'ascending' ? comparison : -comparison
    })
  }, [outcomes, sortColumn, sortDirection])

  return (
    <View as="div" padding="medium 0">
      <Table caption={I18n.t('Student Outcomes')}>
        <Table.Head renderSortLabel={I18n.t('Sort by')}>
          <Table.Row>
            <Table.ColHeader
              id="outcome"
              width="60%"
              stackedSortByLabel={I18n.t('Outcome')}
              sortDirection={sortColumn === 'code' ? sortDirection : 'none'}
              onRequestSort={() => handleSort('code')}
            >
              {I18n.t('Outcome')}
            </Table.ColHeader>
            <Table.ColHeader
              id="assessed"
              width="30%"
              stackedSortByLabel={I18n.t('Times Assessed')}
              sortDirection={sortColumn === 'assessed' ? sortDirection : 'none'}
              onRequestSort={() => handleSort('assessed')}
            >
              {I18n.t('Times Assessed')}
            </Table.ColHeader>
            <Table.ColHeader
              id="mastery"
              width="10%"
              stackedSortByLabel={I18n.t('Mastery')}
              sortDirection={sortColumn === 'mastery' ? sortDirection : 'none'}
              onRequestSort={() => handleSort('mastery')}
            >
              {I18n.t('Mastery')}
            </Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {sortedOutcomes.map(outcome => {
            const isExpanded = expandedRows.has(outcome.id)
            return (
              <OutcomesTableRow
                key={outcome.id}
                outcome={outcome}
                isExpanded={isExpanded}
                onToggleRowExpansion={toggleRowExpansion}
              />
            )
          })}
        </Table.Body>
      </Table>
    </View>
  )
}

export default StudentOutcomesTable
