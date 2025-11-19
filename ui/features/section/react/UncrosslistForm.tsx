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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {IconOffLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {addFlashNoticeForNextPage} from '@canvas/rails-flash-notifications'

const I18n = createI18nScope('section')

interface UncrosslistFormProps {
  courseId: string
  sectionId: string
  nonxlistCourseId: string
  courseName: string
  studentEnrollmentsCount: number
}

export default function UncrosslistForm({
  courseId,
  sectionId,
  nonxlistCourseId,
  courseName,
  studentEnrollmentsCount,
}: UncrosslistFormProps): React.JSX.Element {
  const [isOpen, setIsOpen] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  function handleOpen() {
    setIsOpen(true)
  }

  function handleClose() {
    if (!isSubmitting) setIsOpen(false)
  }

  async function handleSubmit() {
    setIsSubmitting(true)
    try {
      await doFetchApi({
        path: `/courses/${courseId}/sections/${sectionId}/crosslist`,
        method: 'DELETE',
      })
      // On success, redirect to the section page in the original (nonxlist) course
      addFlashNoticeForNextPage('success', I18n.t('Section successfully de-cross-listed!'))
      window.location.href = `/courses/${nonxlistCourseId}/sections/${sectionId}`
    } catch (error) {
      setIsSubmitting(false)
      showFlashError(I18n.t('Failed to de-cross-list section'))(error as Error)
    }
  }

  return (
    <>
      <Button
        onClick={handleOpen}
        display="block"
        textAlign="start"
        renderIcon={<IconOffLine />}
        data-testid="uncrosslist-trigger-button"
      >
        {I18n.t('De-Cross-List this Section')}
      </Button>

      <Modal
        open={isOpen}
        onDismiss={handleClose}
        size="small"
        label={I18n.t('De-Cross-List this Section')}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={handleClose}
            screenReaderLabel={I18n.t('Close')}
            disabled={isSubmitting}
          />
          <Heading>{I18n.t('De-Cross-List this Section')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Text as="p">{I18n.t('Are you sure you want to de-cross-list this section?')}</Text>
          {courseName && (
            <Text
              as="p"
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  'This will move the section back to its original course, *%{courseName}*.',
                  {courseName, wrapper: '<strong>$1</strong>'},
                ),
              }}
            ></Text>
          )}
          {studentEnrollmentsCount > 0 && (
            <Text as="p">
              {I18n.t(
                'All grades for students in this course will no longer be visible. You can retrieve the grades later by re-cross-listing the course, but in the mean time the grades for these students will come from the original course.',
              )}
            </Text>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button
            onClick={handleClose}
            margin="0 buttons 0 0"
            disabled={isSubmitting}
            data-testid="uncrosslist-cancel-button"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            onClick={handleSubmit}
            disabled={isSubmitting}
            data-testid="uncrosslist-submit-button"
          >
            {isSubmitting
              ? I18n.t('De-Cross-Listing Section...')
              : I18n.t('De-Cross-List This Section')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
