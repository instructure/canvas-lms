/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {Tooltip} from '@instructure/ui-tooltip'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconPlusLine, IconTrashLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import type {Bookmark, Enrollment, EnrollmentType, User, ModifyPermissions} from './types'
import {MODULE_NAME, PROVIDER, RECIPIENT} from './types'
import {deleteEnrollment, fetchTemporaryEnrollments} from './api/enrollment'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {createAnalyticPropsGenerator} from './util/analytics'
import {TempEnrollAvatar} from './TempEnrollAvatar'
import {TempEnrollNavigation} from './TempEnrollNavigation'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {captureException} from '@sentry/browser'
import {queryClient} from '@canvas/query'
import {useMutation, useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

type TemporaryEnrollmentsQueryKey = readonly [
  string, // 'enrollments'
  string, // userId
  boolean, // isRecipient
  number, // currentBookmark
  string, // page
]

const fetchTemporaryEnrollmentsWithQueryKey = async ({
  queryKey,
}: {
  queryKey: TemporaryEnrollmentsQueryKey
}) => {
  const [, userId, isRecipient, , pageRequest] = queryKey
  return fetchTemporaryEnrollments(userId, isRecipient, pageRequest)
}

interface Props {
  user: User
  onEdit: (enrollmentUser: User, tempEnrollments: Enrollment[]) => void
  onAddNew?: () => void
  enrollmentType: EnrollmentType
  modifyPermissions: ModifyPermissions
  disableModal: (isDisabled: boolean) => void
}

export function getRelevantUserFromEnrollment(enrollment: Enrollment) {
  return enrollment.temporary_enrollment_provider ?? enrollment.user
}

export function groupEnrollmentsByPairingId(enrollments: Enrollment[]) {
  return enrollments.reduce(
    (groupedById, enrollment) => {
      const groupId = enrollment.temporary_enrollment_pairing_id
      if (!groupedById[groupId]) {
        groupedById[groupId] = []
      }
      groupedById[groupId].push(enrollment)
      return groupedById
    },
    {} as Record<number, Enrollment[]>,
  )
}

/**
 * Confirms with the user and then attempts to delete a list of enrollments,
 * calls the onDelete callback for each successfully deleted enrollment
 *
 * @param {Enrollment[]} tempEnrollments Enrollments to be deleted
 * @param {function} onDelete Callback function
 * @returns {Promise<void>}
 */
async function handleConfirmAndDeleteEnrollment(tempEnrollments: Enrollment[]): Promise<void> {
  // TODO is there a good inst ui component for confirmation dialog?

  const userConfirmed = window.confirm(I18n.t('Are you sure you want to delete this enrollment?'))
  if (userConfirmed) {
    const results = await Promise.allSettled(
      tempEnrollments.map(enrollment =>
        deleteEnrollment(enrollment.course_id, enrollment.id)
          .then(() => ({status: 'success', id: enrollment.id}))
          .catch(() => ({status: 'error', id: enrollment.id})),
      ),
    )
    const successfulDeletions = results
      .filter(result => result.status === 'fulfilled')
      .map(result => (result as PromiseFulfilledResult<{status: string; id: string}>).value.id)
    if (successfulDeletions.length > 0) {
      showFlashAlert({
        type: 'success',
        message: I18n.t(`%{successfulDeletionCount} enrollments deleted successfully.`, {
          successfulDeletionCount: successfulDeletions.length,
        }),
      })
    }
    const errorCount = results.filter(result => result.status === 'rejected').length
    if (errorCount > 0) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('%{errorCount} enrollments could not be deleted.', {errorCount}),
      })
    }
  }
}

export function TempEnrollView(props: Props) {
  const formatDateTime = useDateTimeFormat('date.formats.short_with_time')
  const [currentBookmark, setCurrentBookmark] = useState(0)
  const [allBookmarks, setAllBookmarks] = useState<Bookmark[]>([{page: 'first', rel: 'first'}])

  // destructure and cache permission checks (for use in eager and lazy evaluations)
  const {canEdit, canDelete, canAdd} = props.modifyPermissions

  const canEditOrDelete = canEdit || canDelete

  const enrollmentTypeLabel =
    props.enrollmentType === PROVIDER ? I18n.t('Recipient') : I18n.t('Provider')

  const isRecipient = props.enrollmentType === RECIPIENT

  // Define the query key
  const queryKey = [
    'enrollments',
    props.user.id,
    isRecipient,
    currentBookmark,
    allBookmarks[currentBookmark].page,
  ] as const

  const {isFetching, error, data} = useQuery({
    queryKey,
    queryFn: fetchTemporaryEnrollmentsWithQueryKey,
    staleTime: 10_000,
    refetchOnMount: 'always',
  })

  useEffect(() => {
    if (data?.link?.next && allBookmarks[currentBookmark + 1] == null) {
      setAllBookmarks(prevBookmarks => [...prevBookmarks, data.link!.next!])
    }
  }, [data, currentBookmark, allBookmarks])

  const {mutate} = useMutation({
    mutationFn: async (enrollments: Enrollment[]) => handleConfirmAndDeleteEnrollment(enrollments),
    mutationKey: ['delete-enrollments'],
    onSuccess: () => queryClient.refetchQueries({queryKey: ['enrollments'], type: 'active'}),
  })

  useEffect(() => {
    props.disableModal(isFetching)
  }, [isFetching, props])

  const handleBookmarkChange = async (bookmark: Bookmark) => {
    if (bookmark.rel === 'next') {
      setCurrentBookmark(currentBookmark + 1)
    } else {
      setCurrentBookmark(currentBookmark - 1)
    }
  }

  const handleEditClick = (enrollments: Enrollment[]) => {
    if (canEdit) {
      props.onEdit?.(getRelevantUserFromEnrollment(enrollments[0]), enrollments)
    } else {
      console.error('User does not have permission to edit enrollment')
    }
  }

  const handleDeleteClick = (enrollments: Enrollment[]) => {
    if (canDelete) {
      mutate(enrollments)
    } else {
      console.error('User does not have permission to delete enrollment')
    }
  }

  const handleAddNewClick = () => {
    if (canAdd) {
      props.onAddNew?.()
    } else {
      console.error('User does not have permission to add enrollment')
    }
  }

  const renderEnrollmentPairingStatus = (enrollments: Enrollment[]) => {
    const timestamp = enrollments[0].start_at ? new Date(enrollments[0].start_at).getTime() : 0
    const status: string = timestamp >= Date.now() ? I18n.t('Future') : I18n.t('Active')
    const color = status === 'Active' ? 'success' : 'info'

    return <Pill color={color}>{status}</Pill>
  }

  const renderActionIcons = (enrollments: Enrollment[]) => (
    <Flex gap="xxx-small" wrap="no-wrap" justifyItems="end">
      {canEdit && (
        <Flex.Item shouldShrink={true}>
          <Tooltip renderTip={I18n.t('Edit')}>
            <IconButton
              data-testid="edit-button"
              withBorder={false}
              withBackground={false}
              size="small"
              screenReaderLabel={I18n.t('Edit')}
              onClick={() => handleEditClick(enrollments)}
              {...analyticProps('Edit')}
            >
              <IconEditLine />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}

      {canDelete && (
        <Flex.Item shouldShrink={true}>
          <Tooltip renderTip={I18n.t('Delete')}>
            <IconButton
              data-testid="delete-button"
              withBorder={false}
              withBackground={false}
              size="small"
              screenReaderLabel={I18n.t('Delete')}
              onClick={() => handleDeleteClick(enrollments)}
              {...analyticProps('Delete')}
            >
              <IconTrashLine />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}
    </Flex>
  )

  const renderRows = (enrollments: Enrollment[]) => {
    const rows: JSX.Element[] = []
    const enrollmentGroups = groupEnrollmentsByPairingId(enrollments)
    const usedKeys: number[] = []

    // iterate enrollments instead of enrollmentGroups to keep chronological order
    for (const enrollment of enrollments) {
      const pairingId = enrollment.temporary_enrollment_pairing_id
      // avoid creating duplicate enrollment rows since we iterate by enrollment
      // for sorting instead of by temp enroll grouping
      if (!usedKeys.includes(pairingId)) {
        const group = enrollmentGroups[pairingId]
        const firstEnrollment = group[0]
        rows.push(
          <Table.Row key={pairingId}>
            <Table.RowHeader>
              <TempEnrollAvatar user={getRelevantUserFromEnrollment(firstEnrollment)} />
            </Table.RowHeader>
            <Table.Cell>
              {`${formatDateTime(firstEnrollment.start_at)} - ${formatDateTime(
                firstEnrollment.end_at,
              )}`}
            </Table.Cell>
            <Table.Cell>{firstEnrollment.type}</Table.Cell>
            <Table.Cell>{renderEnrollmentPairingStatus(group)}</Table.Cell>
            {canEditOrDelete ? <Table.Cell>{renderActionIcons(group)}</Table.Cell> : <></>}
          </Table.Row>,
        )
        usedKeys.push(pairingId)
      }
    }
    return rows
  }

  if (error) {
    const errorMsg = error.message

    console.error(`Failed to fetch enrollments for user ${props.user.id}:`, errorMsg)
    captureException(errorMsg)
    return (
      <Alert variant="error" margin="0">
        {errorMsg}
      </Alert>
    )
  } else if (isFetching) {
    return (
      <Flex justifyItems="center" alignItems="center">
        <Spinner renderTitle={I18n.t('Loading')} />
      </Flex>
    )
  } else if (data) {
    const links = {
      prev: allBookmarks[currentBookmark - 1] ?? data.link?.prev,
      next: allBookmarks[currentBookmark + 1] ?? data.link?.next,
    }

    return (
      <>
        <Flex gap="medium" direction="column">
          <Flex.Item overflowY="visible">
            <Flex wrap="wrap" gap="x-small" justifyItems="space-between">
              <Flex.Item>
                <TempEnrollAvatar user={props.user} />
              </Flex.Item>
              {canAdd && props.enrollmentType === PROVIDER && (
                <Flex.Item>
                  <Button
                    data-testid="add-button"
                    onClick={handleAddNewClick}
                    aria-label={I18n.t('Create temporary enrollment')}
                    {...analyticProps('Create')}
                    // @ts-expect-error
                    renderIcon={IconPlusLine}
                  >
                    {I18n.t('Recipient')}
                  </Button>
                </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <Table
              caption={<ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent>}
            >
              <Table.Head>
                <Table.Row>
                  <Table.ColHeader id="usertable-name">
                    {enrollmentTypeLabel} {I18n.t('Name')}
                  </Table.ColHeader>
                  <Table.ColHeader id="usertable-email">
                    {I18n.t('Recipient Enrollment Period')}
                  </Table.ColHeader>
                  <Table.ColHeader id="usertable-loginid">
                    {I18n.t('Recipient Enrollment Type')}
                  </Table.ColHeader>
                  <Table.ColHeader id="usertable-status">{I18n.t('Status')}</Table.ColHeader>

                  {canEdit || canDelete ? (
                    <Table.ColHeader id="header-user-option-links">
                      <ScreenReaderContent>
                        {I18n.t('Temporary enrollment option links')}
                      </ScreenReaderContent>
                    </Table.ColHeader>
                  ) : (
                    <></>
                  )}
                </Table.Row>
              </Table.Head>
              <Table.Body>{renderRows(data.enrollments)}</Table.Body>
            </Table>
          </Flex.Item>
        </Flex>
        <TempEnrollNavigation
          prev={links.prev}
          next={links.next}
          onPageClick={handleBookmarkChange}
        />
      </>
    )
  }
  return null
}
