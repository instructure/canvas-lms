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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCheckLine, IconWarningLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {createUserToMergeQueryKey, fetchUserWithRelations, User} from './common'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('merge_users')

export interface PreviewMergeProps {
  currentUserId: string
  sourceUserId: string
  destinationUserId: string
  onSwap: () => void
  onStartOver: (sourceUserId: string) => void
}

const PreviewMerge = ({
  currentUserId,
  sourceUserId,
  destinationUserId,
  onSwap,
  onStartOver,
}: PreviewMergeProps) => {
  const [isSubmitting, setIsSubmitting] = useState(false)
  const {data: sourceUser} = useQuery({
    queryKey: createUserToMergeQueryKey(sourceUserId),
    queryFn: async () => fetchUserWithRelations(sourceUserId),
  })
  const {data: destinationUser} = useQuery({
    queryKey: createUserToMergeQueryKey(destinationUserId),
    queryFn: async () => fetchUserWithRelations(destinationUserId),
  })
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isOverlayOpen, setIsOverlayOpen] = useState(false)
  const confirmMergeButtonText = I18n.t('Merge User Accounts')
  const mergeButtonText = I18n.t('Merge Accounts')
  const startOverWithSourceButtonText = I18n.t('Start Over with Source Account')
  const startOverWithDestinationButtonText = I18n.t('Start Over with Target Account')
  const swapButtonText = I18n.t('Swap Source and Target Accounts')

  const closeModal = () => setIsModalOpen(false)

  const mergeUsers = async () => {
    try {
      setIsModalOpen(false)
      setIsSubmitting(true)
      setIsOverlayOpen(true)

      await doFetchApi({
        path: `/api/v1/users/${sourceUser?.id}/merge_into/${destinationUser?.id}`,
        method: 'PUT',
      })

      const urlToMoveTo =
        currentUserId === destinationUser?.id
          ? `/about/${destinationUser?.id}`
          : `/users/${destinationUser?.id}`
      setIsOverlayOpen(false)
      showFlashSuccess(
        I18n.t(
          "User merge succeeded! %{sourceUser} and %{destinationUser} are now one and the same. Redirecting to the user's page...",
          {sourceUser: sourceUser?.name, destinationUser: destinationUser?.name},
        ),
      )()
      setTimeout(() => {
        window.location.href = urlToMoveTo
      }, 3000)
    } catch (error: any) {
      const errorMessage =
        error.response.status === 403
          ? I18n.t('User merge failed. Please make sure you have proper permission and try again.')
          : I18n.t('Failed to merge users. Please try again.')

      setIsOverlayOpen(false)
      setIsSubmitting(false)
      showFlashError(errorMessage)()
    }
  }

  const renderEmails = (sourceUser: User, destinationUser: User) => {
    const emails = [...destinationUser.communication_channels, ...sourceUser.communication_channels]

    return (
      <Flex direction="column" data-testid="merged-user-emails">
        {emails.length
          ? emails
              .toSorted()
              .map((email, index) => (
                <Text key={index}>
                  {email === destinationUser.email ? `${email} (${I18n.t('Default')})` : email}
                </Text>
              ))
          : '-'}
      </Flex>
    )
  }

  const renderLogins = (sourceUser: User, destinationUser: User) => {
    const logins = [...destinationUser.pseudonyms, ...sourceUser.pseudonyms]

    return (
      <Flex direction="column" data-testid="merged-user-logins">
        {logins.length
          ? logins.toSorted().map((login, index) => <Text key={index}>{login}</Text>)
          : '-'}
      </Flex>
    )
  }

  const renderEnrollments = (sourceUser: User, destinationUser: User) => {
    const enrollments = [...destinationUser.enrollments, ...sourceUser.enrollments]

    return (
      <Flex direction="column" data-testid="merged-user-enrollments">
        {enrollments.length
          ? enrollments.toSorted().map((enrollment, index) => <Text key={index}>{enrollment}</Text>)
          : '-'}
      </Flex>
    )
  }

  const renderMergeOutcome = (sourceUser: User, destinationUser: User) => {
    return (
      <Flex direction="column" gap="xx-small">
        <Flex gap="x-small" data-testid="source-user-outcome">
          <IconWarningLine color="error" />
          <Text color="danger">
            {I18n.t('Source account %{userNameWithId} will be removed.', {
              userNameWithId: `${sourceUser.name} (ID: ${sourceUser.id})`,
            })}
          </Text>
        </Flex>
        <Flex gap="x-small" data-testid="merged-user-status">
          <IconCheckLine color="success" />
          <Text color="success">
            {I18n.t('Target account %{userNameWithId} will be kept.', {
              userNameWithId: `${destinationUser.name} (ID: ${destinationUser.id})`,
            })}
          </Text>
        </Flex>
      </Flex>
    )
  }

  if (!sourceUser || !destinationUser) {
    return null
  }

  return (
    <>
      <Overlay
        open={isOverlayOpen}
        transition="fade"
        label={I18n.t('Merging User Accounts...')}
        shouldContainFocus
      >
        <Mask>
          <Spinner
            renderTitle={I18n.t('Merging User Accounts...')}
            size="large"
            margin="0 0 0 medium"
          />
        </Mask>
      </Overlay>
      <Modal
        open={isModalOpen}
        label={I18n.t('Confirm User Merge modal')}
        size="small"
        shouldCloseOnDocumentClick={false}
        onDismiss={closeModal}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={closeModal}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Are you sure?')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Flex direction="column" gap="medium">
            <Text weight="bold">{I18n.t('This process cannot be undone.')}</Text>
            {renderMergeOutcome(sourceUser, destinationUser)}
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          <Button
            color="primary"
            margin="0 x-small 0 0"
            onClick={mergeUsers}
            aria-label={confirmMergeButtonText}
          >
            {confirmMergeButtonText}
          </Button>
          <Button color="secondary" onClick={closeModal}>
            {I18n.t('Cancel')}
          </Button>
        </Modal.Footer>
      </Modal>
      <Flex direction="column">
        <Heading level="h1" margin="0 0 small 0">
          {I18n.t('Preview & Confirm')}
        </Heading>
        <Text
          dangerouslySetInnerHTML={{
            __html: I18n.t(
              "This process will consolidate the users into a single user account with the information shown. <b>This process cannot be undone, so please make sure you're certain before you continue.</b>",
            ),
          }}
        />
        <View margin="large 0">{renderMergeOutcome(sourceUser, destinationUser)}</View>
        <Flex direction="column" gap="x-small">
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Name')}</Text>
            </Flex.Item>
            <Text>
              <Link
                href={`/users/${destinationUser.id}`}
                target="_blank"
                data-testid="merged-user-link"
              >
                {destinationUser.name}
              </Link>
            </Text>
          </Flex>
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('User ID')}</Text>
            </Flex.Item>
            <Text>{destinationUser.id}</Text>
          </Flex>
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Display Name')}</Text>
            </Flex.Item>
            <Text data-testid="merged-user-display-name">
              {destinationUser.short_name ?? sourceUser.short_name ?? '-'}
            </Text>
          </Flex>
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('SIS ID')}</Text>
            </Flex.Item>
            <Text data-testid="merged-user-sis-user-id">
              {destinationUser.sis_user_id ?? sourceUser.sis_user_id ?? '-'}
            </Text>
          </Flex>
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Login ID')}</Text>
            </Flex.Item>
            <Text data-testid="merged-user-login-id">
              {destinationUser.login_id ?? sourceUser.login_id ?? '-'}
            </Text>
          </Flex>
          <Flex gap="small">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Integration ID')}</Text>
            </Flex.Item>
            <Text data-testid="merged-user-integration-id">
              {destinationUser.integration_id ?? sourceUser.integration_id ?? '-'}
            </Text>
          </Flex>
          <Flex gap="small" alignItems="start">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Emails')}</Text>
            </Flex.Item>
            {renderEmails(sourceUser, destinationUser)}
          </Flex>
          <Flex gap="small" alignItems="start">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Logins')}</Text>
            </Flex.Item>
            {renderLogins(sourceUser, destinationUser)}
          </Flex>
          <Flex gap="small" alignItems="start">
            <Flex.Item width={130}>
              <Text weight="bold">{I18n.t('Enrollments')}</Text>
            </Flex.Item>
            {renderEnrollments(sourceUser, destinationUser)}
          </Flex>
        </Flex>
        <Flex gap="small" margin="large 0 0 0" wrap="wrap">
          <Button
            color="primary"
            onClick={() => setIsModalOpen(true)}
            aria-label={mergeButtonText}
            disabled={isSubmitting}
          >
            {mergeButtonText}
          </Button>
          <Button color="secondary" onClick={onSwap} aria-label={swapButtonText}>
            {swapButtonText}
          </Button>
          <Button
            color="secondary"
            onClick={() => onStartOver(sourceUser.id)}
            aria-label={startOverWithSourceButtonText}
          >
            {startOverWithSourceButtonText}
          </Button>
          <Button
            color="secondary"
            onClick={() => onStartOver(destinationUser.id)}
            aria-label={startOverWithDestinationButtonText}
          >
            {startOverWithDestinationButtonText}
          </Button>
        </Flex>
      </Flex>
    </>
  )
}

export default PreviewMerge
