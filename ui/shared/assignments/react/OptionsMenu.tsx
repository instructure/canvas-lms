/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useMutation} from '@apollo/client'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {SET_WORKFLOW} from '@canvas/assignments/graphql/teacher/Mutations'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DownloadSubmissionsModal from '@canvas/download-submissions-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import useBoolean from '@canvas/outcomes/react/hooks/useBoolean'
import {assignLocation} from '@canvas/util/globalUtils'
import {BREAKPOINTS, type Breakpoints} from '@canvas/with-breakpoints'
import {Button, IconButton} from '@instructure/ui-buttons'
import {
  IconCommonsLine,
  IconDownloadLine,
  IconDuplicateLine,
  IconEditLine,
  IconMoreLine,
  IconSpeedGraderLine,
  IconTrashLine,
  IconUploadLine,
  IconUserLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import React, {useState, useEffect, useRef} from 'react'
import type {TeacherAssignmentType} from '../graphql/teacher/AssignmentTeacherTypes'
import {ASSIGNMENT_VIEW_TYPES} from './AssignmentTypes'

const I18n = createI18nScope('assignment_more_button')

const OptionsMenu = ({
  type,
  assignment,
  breakpoints,
}: {
  type: string
  assignment: TeacherAssignmentType
  breakpoints: Breakpoints
}): React.ReactElement => {
  const [setWorkFlowState] = useMutation(SET_WORKFLOW)
  const [menuWidth, setMenuWidth] = useState(window.innerWidth)
  const buttonRef = useRef<HTMLButtonElement | null>(null)
  const [sendToModal, setSendToModalOpen, setSendToModalClose] = useBoolean(false)
  const [copyToTray, setCopyToTrayOpen, setCopyToTrayClose] = useBoolean(false)
  const [assignToTray, setAssignToTrayOpen, setAssignToTrayClose] = useBoolean(false)
  const [
    downloadSubmissionsModal,
    setDownloadSubmissionsModalOpen,
    setDownloadSubmissionsModalClose,
  ] = useBoolean(false)
  const peerReviewLink = `/courses/${assignment.course?.lid}/assignments/${assignment?.lid}/peer_reviews`
  const editLink = `/courses/${assignment.course?.lid}/assignments/${assignment?.lid}/edit`
  const speedgraderLink = `/courses/${assignment.course?.lid}/gradebook/speed_grader?assignment_id=${assignment?.lid}`
  const isSavedView = type === ASSIGNMENT_VIEW_TYPES.SAVED
  const isEditView = type === ASSIGNMENT_VIEW_TYPES.EDIT

  const updateMenuWidth = () => {
    if (buttonRef.current) {
      setMenuWidth(buttonRef.current.offsetWidth)
    }
  }

  useEffect(() => {
    const handleResize = () => updateMenuWidth()
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  const buttonRefCallback = (element: HTMLButtonElement | null) => {
    buttonRef.current = element
    updateMenuWidth()
  }

  const handleDeletion = async () => {
    if (isEditView) {
      setWorkFlowState({variables: {id: Number(assignment.lid), workflow: 'deleted'}})
        .then(result => {
          if (result.errors?.length || !result.data || result.data.errors) {
            showFlashError(I18n.t('This assignment has failed to delete.'))()
          } else {
            assignLocation(`/courses/${assignment.course?.lid}/assignments/${assignment?.lid}`)
          }
        })
        .catch(() => showFlashError(I18n.t('This assignment has failed to delete.'))())
    } else {
      assignLocation(`/courses/${assignment.course?.lid}/assignments`)
    }
  }

  return (
    <>
      <Menu
        id="assignment_options_menu"
        label="assignment_options_menu"
        themeOverride={
          breakpoints.mobileOnly
            ? {minWidth: `${menuWidth}px`, maxWidth: BREAKPOINTS.mobileOnly.maxWidth}
            : {minWidth: isSavedView ? '250px' : '159px'}
        }
        withArrow={false}
        placement={breakpoints.mobileOnly ? 'bottom center' : 'bottom end'}
        trigger={
          breakpoints.mobileOnly ? (
            <Button
              // @ts-expect-error
              elementRef={buttonRefCallback}
              data-testid="assignment-options-button"
              display="block"
            >
              {I18n.t('More')}
            </Button>
          ) : (
            <IconButton
              renderIcon={IconMoreLine}
              screenReaderLabel={I18n.t('Options')}
              data-testid="assignment-options-button"
              margin="none none none medium"
            />
          )
        }
      >
        {isSavedView && breakpoints.mobileOnly && (
          <Menu.Item value="Edit" href={editLink} data-testid="edit-option">
            <IconEditLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Edit')}</View>
          </Menu.Item>
        )}
        {isSavedView && breakpoints.mobileOnly && (
          // @ts-expect-error
          <Menu.Item value="Assign To" onClick={setAssignToTrayOpen} data-testid="assign-to-option">
            <IconUserLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Assign To')}</View>
          </Menu.Item>
        )}
        {(breakpoints.mobileOnly || isEditView) && assignment.state === 'published' && (
          <Menu.Item
            value="SpeedGrader"
            href={speedgraderLink}
            target="_blank"
            data-testid="speedgrader-option"
          >
            <IconSpeedGraderLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('SpeedGrader')}</View>
          </Menu.Item>
        )}
        {isSavedView && assignment.hasSubmittedSubmissions && (
          <Menu.Item
            value="Download Submissions"
            // @ts-expect-error
            onClick={setDownloadSubmissionsModalOpen}
            data-testid="download-submissions-option"
          >
            <IconDownloadLine />
            <View margin="0 0 0 x-small">{I18n.t('Download Submissions')}</View>
          </Menu.Item>
        )}
        {isSavedView && assignment.submissionsDownloads && assignment.submissionsDownloads > 0 && (
          <Menu.Item value="Re-Upload Submissions" data-testid="reupload-submissions-option">
            <IconUploadLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Re-Upload Submissions')}</View>
          </Menu.Item>
        )}
        {isSavedView && assignment.peerReviews?.enabled && (
          <Menu.Item value="Peer Review" href={peerReviewLink} data-testid="peer-review-option">
            <IconUserLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Peer Review')}</View>
          </Menu.Item>
        )}
        {isSavedView && (
          // @ts-expect-error
          <Menu.Item value="Send To" onClick={setSendToModalOpen} data-testid="send-to-option">
            <IconUserLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Send To')}</View>
          </Menu.Item>
        )}
        {isSavedView && (
          // @ts-expect-error
          <Menu.Item value="Copy To" onClick={setCopyToTrayOpen} data-testid="copy-to-option">
            <IconDuplicateLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Copy To')}</View>
          </Menu.Item>
        )}
        {isSavedView && (
          <Menu.Item value="Share to Commons" data-testid="share-to-commons-option">
            <IconCommonsLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Share to Commons')}</View>
          </Menu.Item>
        )}
        {!isSavedView && (
          <Menu.Item value="Delete" onClick={handleDeletion} data-testid="delete-assignment-option">
            <IconTrashLine size="x-small" />
            <View margin="0 0 0 x-small">{I18n.t('Delete')}</View>
          </Menu.Item>
        )}
      </Menu>

      {isSavedView && (
        <View margin="0">
          <ItemAssignToTray
            // @ts-expect-error
            open={assignToTray}
            // @ts-expect-error
            onClose={setAssignToTrayClose}
            // @ts-expect-error
            onDismiss={setAssignToTrayClose}
            itemType="assignment"
            iconType="assignment"
            locale={ENV.LOCALE || 'env'}
            timezone={ENV.TIMEZONE || 'UTC'}
            courseId={assignment.course?.lid}
            // @ts-expect-error
            itemName={assignment.name}
            itemContentId={assignment?.lid}
            pointsPossible={assignment.pointsPossible as number}
          />
          <DirectShareCourseTray
            data-testid="copy-to-tray"
            open={copyToTray}
            sourceCourseId={assignment.course?.lid}
            contentSelection={{assignments: [assignment?.lid]}}
            onDismiss={() => {
              // @ts-expect-error
              setCopyToTrayClose()
              buttonRef.current?.focus()
            }}
          />
          {/* @ts-expect-error */}
          <DirectShareUserModal
            data-testid="send-to-modal"
            open={sendToModal}
            sourceCourseId={assignment.course?.lid}
            contentShare={{content_type: 'assignment', content_id: assignment?.lid}}
            onDismiss={() => {
              // @ts-expect-error
              setSendToModalClose()
              buttonRef.current?.focus()
            }}
          />
          <DownloadSubmissionsModal
            // @ts-expect-error
            open={downloadSubmissionsModal}
            // @ts-expect-error
            handleCloseModal={setDownloadSubmissionsModalClose}
            // @ts-expect-error
            assignmentId={assignment.lid}
            courseId={assignment.course.lid}
          />
        </View>
      )}
    </>
  )
}

export default OptionsMenu
