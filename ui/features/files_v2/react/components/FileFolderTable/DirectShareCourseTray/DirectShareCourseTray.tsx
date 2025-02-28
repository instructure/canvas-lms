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

import {createRef, Ref, useCallback, useEffect, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import FileFolderTray from '../../shared/TrayWrapper'
import FileFolderInfo from '../../shared/FileFolderInfo'
import {type File} from '../../../../interfaces/File'
import DirectShareCoursePanel, {DirectShareCoursePanelPropsRef} from './DirectShareCoursePanel'

const I18n = createI18nScope('files_v2')

export type DirectShareCourseTrayProps = {
  open: boolean
  onDismiss: () => void
  courseId: string
  file: File
}

export type Course = {
  id: string
  name: string
  course_code: string
  term: string
}

export type Module = {
  id: string
}

const DirectShareCourseTray = ({open, onDismiss, courseId, file}: DirectShareCourseTrayProps) => {
  const coursePanelRef: Ref<DirectShareCoursePanelPropsRef> =
    createRef<DirectShareCoursePanelPropsRef>()
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null)
  const [selectedModule, setSelectedModule] = useState<Module | null>(null)
  const [selectedPosition, setSelectedPosition] = useState<number | null>(null)
  const [postStatus, setPostStatus] = useState<boolean>(false)
  const [warningVisible, setWarningVisible] = useState<boolean>(true)

  const resetState = useCallback(() => {
    setSelectedCourse(null)
    setSelectedModule(null)
    setSelectedPosition(null)
    setPostStatus(false)
    setWarningVisible(true)
  }, [])

  const startCopyOperation = useCallback(() => {
    const contentSelection = {attachments: [file.id]}
    return doFetchApi({
      method: 'POST',
      path: `/api/v1/courses/${selectedCourse?.id}/content_migrations`,
      body: {
        migration_type: 'course_copy_importer',
        select: contentSelection,
        settings: {
          source_course_id: courseId,
          insert_into_module_id: selectedModule?.id || null,
          associate_with_assignment_id: null,
          is_copy_to: true,
          insert_into_module_type: contentSelection ? Object.keys(contentSelection)[0] : null,
          insert_into_module_position: selectedPosition,
        },
      },
    })
  }, [file.id, selectedCourse?.id, selectedModule?.id, selectedPosition, courseId])

  const sendSuccessful = useCallback(() => {
    showFlashSuccess(I18n.t('Copy operation started successfully'))()
    onDismiss()
  }, [onDismiss])

  const handleCopy = useCallback(() => {
    // if (!selectorRef.current?.validate()) return
    if (!coursePanelRef.current?.validate()) return

    showFlashAlert({message: I18n.t('Starting copy operation...')})
    setPostStatus(true)
    startCopyOperation()
      .then(sendSuccessful)
      .catch(showFlashError(I18n.t('Copy operation failed.')))
  }, [coursePanelRef, sendSuccessful, startCopyOperation])

  const handleSelectCourse = useCallback((course: Course) => {
    setSelectedCourse(course)
    setSelectedModule(null)
  }, [])

  // Reset the state when the open prop changes so we don't carry over state
  // from the previously opened tray
  useEffect(() => {
    if (open) resetState()
  }, [open, resetState])

  return (
    <FileFolderTray
      closeLabel={I18n.t('Close')}
      label={I18n.t('Copy To...')}
      onDismiss={onDismiss}
      open={open}
      header={<Heading level="h3">{I18n.t('Copy To...')}</Heading>}
      footer={
        <>
          <Button data-testid="direct-share-course-cancel" onClick={onDismiss}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="direct-share-course-copy"
            disabled={postStatus}
            color="primary"
            margin="0 0 0 x-small"
            onClick={handleCopy}
          >
            {I18n.t('Copy')}
          </Button>
        </>
      }
    >
      <Flex direction="column">
        <Flex.Item padding="small">
          <FileFolderInfo items={[file]} />
        </Flex.Item>
        {warningVisible && (
          <Flex.Item padding="small">
            <Alert
              variant="warning"
              renderCloseButtonLabel={I18n.t('Close warning message')}
              onDismiss={() => setWarningVisible(false)}
              hasShadow={false}
            >
              {I18n.t(
                'Importing the same course content more than once will overwrite any existing content in the course.',
              )}
            </Alert>
          </Flex.Item>
        )}
        <Flex.Item padding="small">
          <DirectShareCoursePanel
            ref={coursePanelRef}
            selectedCourseId={selectedCourse?.id}
            onSelectCourse={handleSelectCourse}
            selectedModuleId={selectedModule?.id}
            onSelectModule={setSelectedModule}
            onSelectPosition={setSelectedPosition}
          />
        </Flex.Item>
      </Flex>
    </FileFolderTray>
  )
}

export default DirectShareCourseTray
