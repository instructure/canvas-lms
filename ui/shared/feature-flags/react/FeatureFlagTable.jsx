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

import React, {useState, useMemo, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {Alert} from '@instructure/ui-alerts'
import StatusPill from './StatusPill'
import FeatureFlagButton from './FeatureFlagButton'
import {isEnabled, isLocked, doesAllowDefaults} from './util'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import EarlyAccessModal from './EarlyAccessModal'

const I18n = createI18nScope('feature_flags')

const {Head, Body, ColHeader, Row, Cell} = Table

function FeatureFlagTable({title, rows, disableDefaults}) {
  const [stateChanges, setStateChanges] = useState({})
  const [sortConfig, setSortConfig] = useState({key: 'display_name', direction: 'ascending'})
  const [acceptedEarlyAccess, setAcceptedEarlyAccess] = useState(ENV.EARLY_ACCESS_PROGRAM)
  const [showEarlyAccessModal, setShowEarlyAccessModal] = useState(false)
  const [resolveEAP, setResolveEAP] = useState(null)

  const getStatusArray = feature => {
    const statuses = []
    const state = stateChanges[feature.feature] || feature.feature_flag.state
    if (state === 'hidden' && !feature.shadow) statuses.push('hidden')
    if (feature.shadow) statuses.push('shadow')
    if (feature.beta) statuses.push('beta')
    return statuses
  }

  const sortByStatus = (a, b) => {
    const statusesA = getStatusArray(a).toSorted()
    const statusesB = getStatusArray(b).toSorted()

    if (statusesA.length !== statusesB.length) {
      return statusesA.length - statusesB.length
    }

    for (let i = 0; i < statusesA.length; i++) {
      const comparison = statusesA[i].localeCompare(statusesB[i])
      if (comparison !== 0) return comparison
    }

    return 0
  }

  const sortByState = (a, b) => {
    const enabledA = isEnabled(a.feature_flag)
    const enabledB = isEnabled(b.feature_flag)

    if (enabledA !== enabledB) {
      return enabledA ? 1 : -1
    }

    const allowsLockingA = doesAllowDefaults(a.feature_flag)
    const allowsLockingB = doesAllowDefaults(b.feature_flag)

    if (allowsLockingA !== allowsLockingB) {
      return allowsLockingA ? 1 : -1
    }

    const lockedA = isLocked(a.feature_flag)
    const lockedB = isLocked(b.feature_flag)

    if (lockedA !== lockedB) {
      return lockedA ? 1 : -1
    }

    return 0
  }

  const sortedRows = useMemo(() => {
    return rows.toSorted((a, b) => {
      let comparison = 0

      if (sortConfig.key === 'display_name') {
        comparison = a.display_name.localeCompare(b.display_name)
      } else if (sortConfig.key === 'status') {
        comparison = sortByStatus(a, b)
      } else if (sortConfig.key === 'state') {
        comparison = sortByState(a, b)
      }

      return sortConfig.direction === 'ascending' ? comparison : -comparison
    })
  }, [rows, sortConfig])

  const handleSort = key => {
    let direction = 'ascending'
    if (sortConfig.key === key && sortConfig.direction === 'ascending') {
      direction = 'descending'
    }
    setSortConfig({key, direction})
  }

  const handleStateChange = useCallback(
    (featureKey, newState) => {
      setStateChanges(prev => ({...prev, [featureKey]: newState}))
    },
    [setStateChanges],
  )

  const checkEarlyAccessProgram = useCallback(
    async (featureFlag, state) => {
      const feature = rows.find(row => row.feature_flag.feature === featureFlag.feature)

      if (feature?.early_access_program && !acceptedEarlyAccess && state !== 'off') {
        return new Promise(resolve => {
          setResolveEAP(() => resolve)
          setShowEarlyAccessModal(true)
        })
      }

      return true
    },
    [acceptedEarlyAccess, rows],
  )

  const handleEarlyAccessAccept = () => {
    setAcceptedEarlyAccess(true)
    setShowEarlyAccessModal(false)
    if (resolveEAP) {
      resolveEAP(true)
      setResolveEAP(null)
    }
  }

  const handleEarlyAccessCancel = () => {
    setShowEarlyAccessModal(false)
    if (resolveEAP) {
      resolveEAP(false)
      setResolveEAP(null)
    }
  }

  return (
    <>
      <Heading as="h2" level="h3" data-testid="ff-table-heading">
        {title}
      </Heading>
      <Table
        caption={I18n.t('%{title} Feature Flags: sorted by %{sortBy} in %{direction} order.', {
          title: title,
          sortBy: translateSortKey(sortConfig.key),
          direction: translateSortDirection(sortConfig.direction),
        })}
        margin="medium 0"
      >
        <Head renderSortLabel={I18n.t('Sort by')}>
          <Row>
            <ColHeader
              id="display_name"
              width="50%"
              stackedSortByLabel={I18n.t('Feature')}
              onRequestSort={
                window.ENV.FEATURES.feature_flag_ui_sorting
                  ? () => handleSort('display_name')
                  : undefined
              }
              sortDirection={
                window.ENV.FEATURES.feature_flag_ui_sorting && sortConfig.key === 'display_name'
                  ? sortConfig.direction
                  : 'none'
              }
            >
              {window.ENV.FEATURES.feature_flag_ui_sorting ? (
                <>
                  <p aria-hidden="true">{I18n.t('Feature')}</p>
                  <ScreenReaderContent>{I18n.t('Sort by Feature')}</ScreenReaderContent>
                </>
              ) : (
                I18n.t('Feature')
              )}
            </ColHeader>
            <ColHeader
              id="status"
              width="50%"
              stackedSortByLabel={I18n.t('Status')}
              onRequestSort={
                window.ENV.FEATURES.feature_flag_ui_sorting ? () => handleSort('status') : undefined
              }
              sortDirection={
                window.ENV.FEATURES.feature_flag_ui_sorting && sortConfig.key === 'status'
                  ? sortConfig.direction
                  : 'none'
              }
            >
              {window.ENV.FEATURES.feature_flag_ui_sorting ? (
                <>
                  <p aria-hidden="true">{I18n.t('Status')}</p>
                  <ScreenReaderContent>{I18n.t('Sort by Status')}</ScreenReaderContent>
                </>
              ) : (
                I18n.t('Status')
              )}
            </ColHeader>
            <ColHeader
              id="state"
              stackedSortByLabel={I18n.t('State')}
              onRequestSort={
                window.ENV.FEATURES.feature_flag_ui_sorting ? () => handleSort('state') : undefined
              }
              sortDirection={
                window.ENV.FEATURES.feature_flag_ui_sorting && sortConfig.key === 'state'
                  ? sortConfig.direction
                  : 'none'
              }
            >
              {window.ENV.FEATURES.feature_flag_ui_sorting ? (
                <>
                  <p aria-hidden="true">{I18n.t('State')}</p>
                  <ScreenReaderContent>{I18n.t('Sort by State')}</ScreenReaderContent>
                </>
              ) : (
                I18n.t('State')
              )}
            </ColHeader>
          </Row>
        </Head>
        <Body>
          {sortedRows.map(feature => (
            <FeatureFlagRow
              key={feature.feature}
              feature={feature}
              updatedState={stateChanges[feature.feature]}
              onStateChange={handleStateChange}
              disableDefaults={disableDefaults}
              checkEarlyAccessProgram={checkEarlyAccessProgram}
            />
          ))}
        </Body>
      </Table>

      <Alert
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        liveRegionPoliteness="polite"
        screenReaderOnly
      >
        {I18n.t('Sorted by %{sortBy} in %{direction} order', {
          sortBy: translateSortKey(sortConfig.key),
          direction: translateSortDirection(sortConfig.direction),
        })}
      </Alert>

      <EarlyAccessModal
        isOpen={showEarlyAccessModal}
        onAccept={handleEarlyAccessAccept}
        onCancel={handleEarlyAccessCancel}
      />
    </>
  )
}

const FeatureFlagRow = React.memo(
  ({feature, updatedState, onStateChange, disableDefaults, checkEarlyAccessProgram}) => {
    return (
      <Row key={feature.feature} data-testid="ff-table-row">
        <Cell>
          <ToggleDetails summary={feature.display_name} defaultExpanded={feature.autoexpand}>
            <div dangerouslySetInnerHTML={{__html: feature.description}} />
          </ToggleDetails>
        </Cell>
        <Cell>
          <StatusPill feature={feature} updatedState={updatedState} />
        </Cell>
        <Cell>
          <FeatureFlagButton
            displayName={feature.display_name}
            featureFlag={feature.feature_flag}
            disableDefaults={disableDefaults}
            appliesTo={feature.applies_to}
            onStateChange={newState => onStateChange(feature.feature, newState)}
            checkEarlyAccessProgram={checkEarlyAccessProgram}
          />
        </Cell>
      </Row>
    )
  },
)

const translateSortKey = key => {
  if (key === 'display_name') {
    return I18n.t('Feature')
  } else if (key === 'status') {
    return I18n.t('Status')
  } else {
    return I18n.t('State')
  }
}

const translateSortDirection = direction => {
  if (direction === 'ascending') {
    return I18n.t('Ascending')
  } else {
    return I18n.t('Descending')
  }
}

export default React.memo(FeatureFlagTable)
