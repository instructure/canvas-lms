/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconAssignmentLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {type TiiApMigration} from './TurnitinApMigrationModalState'

const I18n = createI18nScope('lti_registrations')

const MigrationStatusDetails = (migration: TiiApMigration) => {
  const workflowState = migration.migration_progress?.workflow_state || 'ready'
  const reportUrl = migration.migration_progress?.results?.migration_report_url

  switch (workflowState) {
    case 'ready':
      return (
        <Text size="small" color="secondary">
          {I18n.t('Migration not started yet')}
        </Text>
      )
    case 'running':
    case 'queued':
      return (
        <Text size="small" color="secondary">
          {I18n.t('Migration is currently in progress')}
        </Text>
      )
    case 'completed':
      return (
        <Text size="small" color="secondary">
          {I18n.t('Migration completed!')}{' '}
          {reportUrl && (
            <Link href={reportUrl} target="_blank" rel="noopener noreferrer" isWithinText={true}>
              {I18n.t('Download Report')}
            </Link>
          )}
        </Text>
      )
    case 'failed':
      return (
        <Text size="small" color="secondary">
          {I18n.t('Migration failed.')}{' '}
          {reportUrl && (
            <Link href={reportUrl} target="_blank" rel="noopener noreferrer" isWithinText={true}>
              {I18n.t('Download Report')}
            </Link>
          )}
        </Text>
      )
  }
}

const MigrationActionButton = ({
  migration,
  startMigration,
  isPending,
  emailError,
  isBulkInProgress,
}: {
  migration: TiiApMigration
  startMigration: (subAccountId: string) => void
  isPending: boolean
  emailError?: boolean
  isBulkInProgress: boolean
}) => {
  const workflowState = migration.migration_progress?.workflow_state || 'ready'

  switch (workflowState) {
    case 'running':
    case 'queued':
      return (
        <Button color="primary" interaction="disabled">
          {I18n.t('Migrating...')}
        </Button>
      )
    case 'failed':
      return null // TODO we might allow retry in future
    case 'ready':
      if (isBulkInProgress && !isPending) {
        return (
          <Button color="primary" interaction="disabled">
            {I18n.t('Queued...')}
          </Button>
        )
      }
      return (
        <Button
          color="primary"
          interaction={isPending || emailError || isBulkInProgress ? 'disabled' : 'enabled'}
          onClick={() => startMigration(migration.account_id)}
        >
          {I18n.t('Migrate')}
        </Button>
      )
    case 'completed':
      return null
    default:
      return workflowState satisfies never
  }
}

export const MigrationRow = ({
  migration,
  startMigration,
  isPending,
  emailError,
  isBulkInProgress,
}: {
  migration: TiiApMigration
  startMigration: (subAccountId: string) => void
  isPending: boolean
  emailError?: boolean
  isBulkInProgress: boolean
}) => {
  return (
    <View
      key={migration.account_id}
      as="div"
      borderWidth="0 0 0 large"
      padding="none small"
      borderColor="#C1368F"
      margin="small none"
    >
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item margin="0 small 0 0" as="div">
          <IconAssignmentLine size="x-small" color="secondary" />
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Flex direction="column" gap="x-small">
            <View as="div">
              <Flex gap="x-small" alignItems="center">
                <Link
                  href={`/accounts/${migration.account_id}`}
                  isWithinText={false}
                  target="_blank"
                >
                  {migration.account_name}
                </Link>
              </Flex>
              <MigrationStatusDetails {...migration} />
            </View>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <MigrationActionButton
            migration={migration}
            startMigration={startMigration}
            isPending={isPending}
            emailError={emailError}
            isBulkInProgress={isBulkInProgress}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}
