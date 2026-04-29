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
import {Modal} from '@instructure/ui-modal'
import {IconButton, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import React, {useState} from 'react'
import {IconQuestionLine} from '@instructure/ui-icons'

import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import type {EnvCourseSettings} from '@canvas/global/env/EnvCourse'
declare const ENV: GlobalEnv & EnvCourseSettings

const I18n = createI18nScope('course_settings')

export default function VisibilityHelpIcon() {
  const [isOpen, setIsOpen] = useState(false)

  const openModal = () => {
    setIsOpen(true)
  }

  const closeModal = () => {
    setIsOpen(false)
  }

  return (
    <>
      <IconButton
        className="visibility_help_link"
        data-testid="visibility_help_link"
        color="primary"
        onClick={openModal}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Help with course visibilities')}
      >
        <IconQuestionLine size="x-small" />
      </IconButton>
      <Modal
        open={isOpen}
        onDismiss={closeModal}
        label={I18n.t('Course Visibility Help')}
        size="small"
        id="visibility_help_dialog"
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={closeModal}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Course Visibility Help')}</Heading>
        </Modal.Header>
        <Modal.Body data-testid="course_visibility_descriptions" padding="space8 space24">
          <dl>
            {Array.from(
              document.querySelectorAll<HTMLOptionElement>('#course_course_visibility option'),
            ).map(element => (
              <React.Fragment key={element.value}>
                <dt>{element.innerText}</dt>
                <dd>
                  {ENV.COURSE_VISIBILITY_OPTION_DESCRIPTIONS[
                    element.value as 'course' | 'institution' | 'public'
                  ] || ''}
                </dd>
              </React.Fragment>
            ))}
          </dl>
        </Modal.Body>
      </Modal>
    </>
  )
}
