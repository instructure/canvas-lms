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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {
  useTurnitinMigrationData,
  useMigrationMutation,
  useMigrateAllMutation,
  hasEligibleMigrations,
  isBulkMigrationInProgress,
  type TiiApMigration,
  cancelMigrationQueries,
} from './TurnitinApMigrationModalState'
import {MigrationModalStateRenderer} from './MigrationModalStateRenderer'
import {MigrationInfoAlert} from './MigrationInfoAlert'
import {MigrationRow} from './MigrationRow'
import {MigrationEmailNotification} from './MigrationEmailNotification'
import {validateEmailForNewUser} from '@canvas/add-people/react/helpers'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('lti_registrations')

export type TurnitinAPMigrationModalProps = {
  onClose: () => void
  rootAccountId: string
}

export const TurnitinAPMigrationModal = ({
  onClose,
  rootAccountId,
}: TurnitinAPMigrationModalProps) => {
  const {data, isLoading, error} = useTurnitinMigrationData(rootAccountId)
  const {mutate: startMigrationMutation} = useMigrationMutation(rootAccountId, {
    onError: (_error: Error) => {
      showFlashError(I18n.t('Failed to start migration. Please try again later.'))()
    },
  })
  const {mutate: startMigrateAllMutation, isPending: isMigrateAllPending} = useMigrateAllMutation(
    rootAccountId,
    {
      onError: (_error: Error) => {
        showFlashError(I18n.t('Failed to start migration for all accounts. Please try again.'))()
      },
    },
  )

  const migrations = data?.accounts
  const coordinatorProgress = data?.coordinator_progress
  const canShowMigrateAll = hasEligibleMigrations(data)
  const isBulkInProgress = isBulkMigrationInProgress(data)
  const isCoordinatorInProgress =
    coordinatorProgress?.workflow_state === 'running' ||
    coordinatorProgress?.workflow_state === 'queued'
  const showConsolidatedReport = !!coordinatorProgress?.consolidated_report_url

  const [email, setEmail] = React.useState('')
  const [emailNotification, setEmailNotification] = React.useState(false)
  const [emailError, setEmailError] = React.useState<string | undefined>(undefined)
  const [emailInputElement, setEmailInputElement] = React.useState<HTMLInputElement | null>(null)

  const handleClose = () => {
    cancelMigrationQueries(rootAccountId)
    onClose()
  }

  const handleEmailChange = (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setEmail(value)
    if (value) {
      const error = validateEmailForNewUser({email: value})
      setEmailError(error || undefined)
    } else {
      setEmailError(undefined)
    }
  }

  const startMigration = (subAccountId: string) => {
    if (emailNotification && !email) {
      setEmailError(I18n.t('Email address is required for report notification.'))
      emailInputElement?.focus()
      return
    }

    startMigrationMutation({
      subAccountId,
      email: emailNotification && email ? email : undefined,
    })
  }

  const startMigrateAll = () => {
    if (emailNotification && !email) {
      setEmailError(I18n.t('Email address is required for report notification.'))
      emailInputElement?.focus()
      return
    }

    startMigrateAllMutation({
      email: emailNotification && email ? email : undefined,
    })
  }

  return (
    <Modal
      open={true}
      onDismiss={handleClose}
      size="medium"
      label={I18n.t('Migrate from LTI 2.0')}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Migrate from LTI 2.0')}</Heading>
      </Modal.Header>

      <Modal.Body overflow="scroll">
        {isLoading ? (
          <MigrationModalStateRenderer state="loading" />
        ) : error ? (
          <MigrationModalStateRenderer state="error" />
        ) : !migrations || migrations.length === 0 ? (
          <MigrationModalStateRenderer state="empty" />
        ) : (
          <Flex direction="column" height="25rem">
            <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="auto" margin="0 0 0 0">
              <MigrationInfoAlert />

              <View as="div" margin="0 0 medium 0">
                <Flex gap="medium" justifyItems="space-between" margin="0 0 small 0">
                  <Flex.Item shouldGrow={true}>
                    <Heading level="h3" margin="0">
                      {I18n.t('Migrations to be Performed:')}
                    </Heading>
                  </Flex.Item>
                  {showConsolidatedReport ? (
                    <Flex.Item>
                      <Link
                        href={coordinatorProgress.consolidated_report_url!}
                        target="_blank"
                        rel="noopener noreferrer"
                        isWithinText={false}
                      >
                        {I18n.t('Download Consolidated Report')}
                      </Link>
                    </Flex.Item>
                  ) : (
                    (canShowMigrateAll || isCoordinatorInProgress) && (
                      <Flex.Item>
                        <Button
                          color="secondary"
                          interaction={
                            isMigrateAllPending ||
                            !!emailError ||
                            isLoading ||
                            isCoordinatorInProgress
                              ? 'disabled'
                              : 'enabled'
                          }
                          onClick={startMigrateAll}
                          data-pendo="lti-registrations-migrate-all"
                        >
                          {isMigrateAllPending || isCoordinatorInProgress
                            ? I18n.t('Migrating All...')
                            : I18n.t('Migrate All')}
                        </Button>
                      </Flex.Item>
                    )
                  )}
                </Flex>

                <View as="div" padding="0">
                  {migrations.map((migration: TiiApMigration) => (
                    <MigrationRow
                      key={migration.account_id}
                      migration={migration}
                      startMigration={startMigration}
                      isPending={!!migration.migrateClicked}
                      emailError={!!emailError}
                      isBulkInProgress={isBulkInProgress}
                    />
                  ))}
                </View>
              </View>
            </Flex.Item>

            <MigrationEmailNotification
              emailNotification={emailNotification}
              setEmailNotification={setEmailNotification}
              email={email}
              setEmail={setEmail}
              emailError={emailError}
              setEmailError={setEmailError}
              handleEmailChange={handleEmailChange}
              setEmailInputElement={setEmailInputElement}
            />
          </Flex>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Button onClick={handleClose} margin="0 0 0 0">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
