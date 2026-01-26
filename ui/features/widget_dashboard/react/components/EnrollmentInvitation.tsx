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

import React, {useCallback} from 'react'
import {useMutation, useQueryClient} from '@tanstack/react-query'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {executeQuery} from '@canvas/graphql'
import {
  ACCEPT_ENROLLMENT_INVITATION,
  REJECT_ENROLLMENT_INVITATION,
  DASHBOARD_NOTIFICATIONS_KEY,
} from '../constants'

interface AcceptEnrollmentInvitationResponse {
  acceptEnrollmentInvitation?: {
    success?: boolean
    enrollment?: {
      id: string
      course?: {
        id: string
        name: string
      }
    }
    errors?: Array<{message: string}>
  }
}

interface RejectEnrollmentInvitationResponse {
  rejectEnrollmentInvitation?: {
    success?: boolean
    enrollment?: {
      id: string
    }
    errors?: Array<{message: string}>
  }
}

const I18n = createI18nScope('enrollment_invitation')

export interface EnrollmentInvitationData {
  id: string
  uuid: string
  course: {
    id: string
    name: string
  }
  role: {
    name: string
  }
  roleLabel: string
}

interface EnrollmentInvitationProps {
  invitation: EnrollmentInvitationData
  onAccept?: (invitationId: string) => void
  onReject?: (invitationId: string) => void
}

const EnrollmentInvitation: React.FC<EnrollmentInvitationProps> = ({
  invitation,
  onAccept,
  onReject,
}) => {
  const queryClient = useQueryClient()

  const acceptMutation = useMutation<AcceptEnrollmentInvitationResponse, Error, string>({
    mutationFn: async (enrollmentUuid: string) => {
      return executeQuery<AcceptEnrollmentInvitationResponse>(ACCEPT_ENROLLMENT_INVITATION, {
        enrollmentUuid,
      })
    },
    onSuccess: () => {
      // Invalidate dashboard notifications to remove accepted invitation from cache
      queryClient.invalidateQueries({
        queryKey: [DASHBOARD_NOTIFICATIONS_KEY],
      })
    },
  })

  const rejectMutation = useMutation<RejectEnrollmentInvitationResponse, Error, string>({
    mutationFn: async (enrollmentUuid: string) => {
      return executeQuery<RejectEnrollmentInvitationResponse>(REJECT_ENROLLMENT_INVITATION, {
        enrollmentUuid,
      })
    },
    onSuccess: () => {
      // Invalidate dashboard notifications to remove rejected invitation from cache
      queryClient.invalidateQueries({
        queryKey: [DASHBOARD_NOTIFICATIONS_KEY],
      })
    },
  })

  const handleAccept = useCallback(async () => {
    try {
      const result = await acceptMutation.mutateAsync(invitation.uuid)

      if (result?.acceptEnrollmentInvitation?.success) {
        showFlashAlert({
          message: I18n.t('Enrollment invitation accepted successfully'),
          type: 'success',
        })
        onAccept?.(invitation.id)

        // Small delay to allow backend after_transaction_commit to clear cache
        await new Promise(resolve => setTimeout(resolve, 500))
        window.location.reload()
      } else {
        const errors = result?.acceptEnrollmentInvitation?.errors || []
        const errorMessage =
          errors.length > 0 ? errors[0].message : I18n.t('Failed to accept invitation')
        showFlashAlert({
          message: errorMessage,
          type: 'error',
        })
      }
    } catch {
      showFlashAlert({
        message: I18n.t('An error occurred while accepting the invitation'),
        type: 'error',
      })
    }
  }, [acceptMutation, invitation.uuid, invitation.id, onAccept])

  const handleReject = useCallback(async () => {
    try {
      const result = await rejectMutation.mutateAsync(invitation.uuid)

      if (result?.rejectEnrollmentInvitation?.success) {
        showFlashAlert({
          message: I18n.t('Enrollment invitation declined'),
          type: 'info',
        })
        onReject?.(invitation.id)
      } else {
        const errors = result?.rejectEnrollmentInvitation?.errors || []
        const errorMessage =
          errors.length > 0 ? errors[0].message : I18n.t('Failed to decline invitation')
        showFlashAlert({
          message: errorMessage,
          type: 'error',
        })
      }
    } catch {
      showFlashAlert({
        message: I18n.t('An error occurred while declining the invitation'),
        type: 'error',
      })
    }
  }, [rejectMutation, invitation.uuid, invitation.id, onReject])

  const courseUrl = `/courses/${invitation.course.id}?invitation=${invitation.uuid}`

  return (
    <View as="div" margin="0 0 small 0" data-testid="enrollment-invitation">
      <Alert variant="success" renderCloseButtonLabel="">
        <Flex>
          <Flex.Item shouldGrow shouldShrink>
            <Flex direction="row" alignItems="start">
              <Flex.Item shouldGrow shouldShrink>
                <View as="div">
                  <span>
                    {I18n.t('You have been invited to join ')}{' '}
                    <Link href={courseUrl}>{invitation.course.name}</Link>{' '}
                    {I18n.t('with the following user role: %{role}', {
                      role: invitation.roleLabel || invitation.role?.name,
                    })}
                  </span>
                </View>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
        <View as="div" margin="small 0 0 0">
          <Flex gap="small" justifyItems="start">
            <Flex.Item>
              <Button
                size="small"
                onClick={handleReject}
                interaction={rejectMutation.isPending ? 'disabled' : 'enabled'}
              >
                {I18n.t('Decline')}
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button
                size="small"
                color="success"
                onClick={handleAccept}
                interaction={acceptMutation.isPending ? 'disabled' : 'enabled'}
              >
                {I18n.t('Accept')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>
      </Alert>
    </View>
  )
}

export default EnrollmentInvitation
