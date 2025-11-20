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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Alert} from '@instructure/ui-alerts'
import {Link} from '@instructure/ui-link'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconAssignmentLine} from '@instructure/ui-icons'
import {
  useTurnitinMigrationData,
  useMigrationMutation,
  type TiiApMigration,
  cancelMigrationQueries,
} from './TurnitinApMigrationModalState'
import {validateEmailForNewUser} from '@canvas/add-people/react/helpers'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('lti_registrations')

export type TurnitinAPMigrationModalProps = {
  onClose: () => void
  rootAccountId: string
}

const ViewReportLink = (migration: TiiApMigration) => {
  // TODO implement report download in later commit
  return null
}

const MigrationStatusDetails = (migration: TiiApMigration) => {
  const workflowState = migration.migration_progress?.workflow_state || 'ready'
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
        <>
          <Text size="small" color="secondary">
            {I18n.t('Migration completed!')}
          </Text>
          <ViewReportLink {...migration} />
        </>
      )
    case 'failed':
      return (
        <>
          <Text size="small" color="secondary">
            {I18n.t('Migration failed.')}
          </Text>
          <ViewReportLink {...migration} />
        </>
      )
    default:
      return workflowState satisfies never
  }
}

const MigrationActionButton = ({
  migration,
  startMigration,
  isPending,
  emailError,
}: {
  migration: TiiApMigration
  startMigration: (subAccountId: string) => void
  isPending: boolean
  emailError?: boolean
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
      return (
        <Button
          color="primary"
          interaction={isPending || emailError ? 'disabled' : 'enabled'}
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

/**
 * Individual migration row component
 */
const MigrationRow = ({
  migration,
  startMigration,
  isPending,
  emailError,
}: {
  migration: TiiApMigration
  startMigration: (subAccountId: string) => void
  isPending: boolean
  emailError?: boolean
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
                <Link href={`#${migration.account_id}`} isWithinText={false}>
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
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export const TurnitinAPMigrationModal = ({
  onClose,
  rootAccountId,
}: TurnitinAPMigrationModalProps) => {
  const {data: migrations, isLoading, error} = useTurnitinMigrationData(rootAccountId)
  const {mutate: startMigrationMutation} = useMigrationMutation(rootAccountId, {
    onError: (_error: Error) => {
      showFlashError(I18n.t('Failed to start migration. Please try again later.'))()
    },
  })

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
    // Validate on change
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
          <View as="div" textAlign="center" padding="large" height="25rem">
            <Text>{I18n.t('Loading migration data...')}</Text>
          </View>
        ) : error ? (
          <View as="div" textAlign="center" padding="large" height="25rem">
            <Alert variant="error" margin="0 0 medium 0">
              {I18n.t('Failed to load migration data. Please try again.')}
            </Alert>
          </View>
        ) : !migrations || migrations.length === 0 ? (
          <View as="div" textAlign="center" padding="large" height="25rem">
            <Text>{I18n.t('No migrations available.')}</Text>
          </View>
        ) : (
          <Flex direction="column" height="25rem">
            <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="auto" margin="0 0 0 0">
              <View as="div" margin="0 0 medium 0">
                <Alert
                  variant="info"
                  renderCloseButtonLabel={I18n.t('Close')}
                  margin="0 0 medium 0"
                >
                  <Flex gap="small">
                    <Text>
                      {I18n.t(
                        'We are replacing LTI 2.0 (CPF) with LTI 1.3 (Asset/Document Processor). Below are the migrations that need to occur in order to easily start using LTI 1.3 on all of your assignments.',
                      )}
                    </Text>
                  </Flex>
                </Alert>
              </View>

              <View as="div" margin="0 0 medium 0">
                <Heading level="h3" margin="0 0 small 0">
                  {I18n.t('Migrations to be Performed:')}
                </Heading>

                <View as="div" padding="0">
                  {migrations.map((migration: TiiApMigration) => (
                    <MigrationRow
                      key={migration.account_id}
                      migration={migration}
                      startMigration={startMigration}
                      isPending={!!migration.migrateClicked}
                      emailError={!!emailError}
                    />
                  ))}
                </View>
              </View>
            </Flex.Item>

            <Flex.Item padding="small none none none">
              <View as="div" borderWidth="small 0 0 0" padding="small 0 0 0">
                <Flex direction="column" gap="small">
                  <Flex.Item>
                    <Checkbox
                      label={I18n.t('Email report upon completion of a migration')}
                      checked={emailNotification}
                      onChange={e => {
                        setEmailNotification(e.target.checked)
                        if (!e.target.checked) {
                          setEmailError(undefined)
                          setEmail('')
                        }
                      }}
                    />
                  </Flex.Item>
                  {emailNotification && (
                    <Flex.Item>
                      <TextInput
                        value={email}
                        onChange={handleEmailChange}
                        placeholder={I18n.t('Enter email address')}
                        isRequired={true}
                        messages={emailError ? [{text: emailError, type: 'error'}] : undefined}
                        inputRef={ref => {
                          if (ref instanceof HTMLInputElement) {
                            setEmailInputElement(ref)
                          }
                        }}
                      />
                    </Flex.Item>
                  )}
                </Flex>
              </View>
            </Flex.Item>
          </Flex>
        )}
      </Modal.Body>

      <Modal.Footer>
        <Button onClick={handleClose} margin="0 small 0 0">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
