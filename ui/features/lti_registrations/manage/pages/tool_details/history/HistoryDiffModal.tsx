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
import * as tz from '@instructure/moment-utils'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React from 'react'
import {isEntryForConfigChange} from '../../../model/LtiRegistrationHistoryEntry'
import {IconsDiff} from './diff_components/IconsDiff'
import {LaunchSettingsDiff} from './diff_components/LaunchSettingsDiff'
import {NamingDiff} from './diff_components/NamingDiff'
import {PermissionsDiff} from './diff_components/PermissionsDiff'
import {PlacementsDiff} from './diff_components/PlacementsDiff'
import {PrivacyLevelDiff} from './diff_components/PrivacyLevelDiff'
import {
  AvailabilityChangeEntryWithDiff,
  ConfigChangeEntryWithDiff,
  LtiHistoryEntryWithDiff,
} from './differ'

const I18n = createI18nScope('lti_registrations')

export type HistoryDiffModalProps = {
  entry: LtiHistoryEntryWithDiff | null
  isOpen: boolean
  onClose: () => void
}

/**
 * Modal that displays detailed configuration changes for an LTI registration history entry.
 * Shows side-by-side diff view with removals (red) and additions (green) organized by field categories.
 */
export const HistoryDiffModal: React.FC<HistoryDiffModalProps> = ({entry, isOpen, onClose}) => {
  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size="large"
      label={I18n.t('Configuration Changes')}
      shouldCloseOnDocumentClick={false}
      data-pendo="lti-registrations-view-history-diff"
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        {entry && (
          <Heading level="h2">
            {I18n.t('Changes by %{userName} on %{date}', {
              userName:
                entry.created_by === 'Instructure' ? I18n.t('Instructure') : entry.created_by.name,
              date: tz.format(entry.created_at, 'date.formats.full'),
            })}
          </Heading>
        )}
      </Modal.Header>
      <Modal.Body>
        {(() => {
          if (entry === null) {
            return null
          } else if (isEntryForConfigChange(entry)) {
            return <ConfigChangeBody entry={entry} />
          } else {
            return <AvailabilityChangeBody entry={entry} />
          }
        })()}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} color="primary">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

type ConfigChangeBodyProps = {
  entry: ConfigChangeEntryWithDiff
}

const ConfigChangeBody = ({entry}: ConfigChangeBodyProps) => {
  const changedSections = [
    entry.internalConfig?.launchSettings,
    entry.internalConfig?.permissions,
    entry.internalConfig?.privacyLevel,
    entry.internalConfig?.placements,
    entry.internalConfig?.naming,
    entry.internalConfig?.icons,
  ].filter(Boolean)

  const fieldCount = changedSections.length

  return (
    <View as="div" padding="small">
      <Heading level="h2" margin="0">
        <Flex gap="medium" margin="0 0 medium 0">
          <Flex.Item shouldGrow={true} shouldShrink={true} size="45%">
            <Flex direction="row" alignItems="center" gap="x-small">
              <Flex.Item>
                <span
                  className="diff-container-removal"
                  aria-hidden="true"
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: '1.5rem',
                    height: '1.5rem',
                    borderRadius: '50%',
                    fontWeight: 'bold',
                  }}
                >
                  -
                </span>
              </Flex.Item>
              <Flex.Item>
                {I18n.t(
                  {
                    one: '1 removal',
                    other: '%{count} removals',
                  },
                  {count: entry.totalRemovals},
                )}
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item shouldGrow={true} shouldShrink={true} size="45%">
            <Flex direction="row" alignItems="center" gap="x-small">
              <Flex.Item>
                <span
                  className="diff-container-addition"
                  aria-hidden="true"
                  style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: '1.5rem',
                    height: '1.5rem',
                    borderRadius: '50%',
                    fontWeight: 'bold',
                  }}
                >
                  +
                </span>
              </Flex.Item>
              <Flex.Item>
                {I18n.t(
                  {
                    one: '1 addition',
                    other: '%{count} additions',
                  },
                  {count: entry.totalAdditions},
                )}
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Heading>
      {/* Diff Sections */}
      {entry.internalConfig?.launchSettings && (
        <LaunchSettingsDiff diff={entry.internalConfig.launchSettings} />
      )}
      {entry.internalConfig?.permissions && (
        <PermissionsDiff diff={entry.internalConfig.permissions} />
      )}
      {entry.internalConfig?.privacyLevel && (
        <PrivacyLevelDiff diff={entry.internalConfig.privacyLevel} />
      )}
      {entry.internalConfig?.placements && (
        <PlacementsDiff diff={entry.internalConfig.placements} />
      )}
      {entry.internalConfig?.naming && <NamingDiff diff={entry.internalConfig.naming} />}
      {entry.internalConfig?.icons && <IconsDiff diff={entry.internalConfig.icons} />}

      {fieldCount === 0 && (
        <View as="div" textAlign="center" padding="large">
          <Text>
            {I18n.t(
              "We're unable to show a comparison for these changes. For a complete representation of changes, please use the API.",
            )}
          </Text>
        </View>
      )}
    </View>
  )
}

type AvailabilityChangeBodyProps = {
  entry: AvailabilityChangeEntryWithDiff
}

const AvailabilityChangeBody = ({entry}: AvailabilityChangeBodyProps) => {
  return (
    <>
      <Text>TODO: Implement this properly</Text>
      <Text>{JSON.stringify(entry, null, 2)}</Text>
    </>
  )
}
