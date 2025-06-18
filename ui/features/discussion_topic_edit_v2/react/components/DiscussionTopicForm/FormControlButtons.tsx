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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'

import {assignLocation} from '@canvas/util/globalUtils'
import type {Breakpoints} from '@canvas/with-breakpoints'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('discussion_create')

export const FormControlButtons = ({
  isAnnouncement,
  isEditing,
  published,
  shouldShowSaveAndPublishButton,
  submitForm,
  isSubmitting,
  willAnnouncementPostRightAway,
  breakpoints,
}: {
  isAnnouncement: boolean
  isEditing: boolean
  published: boolean
  shouldShowSaveAndPublishButton: boolean
  submitForm: (publish: boolean | undefined) => void
  isSubmitting: boolean
  willAnnouncementPostRightAway: boolean
  breakpoints: Breakpoints
}) => {
  return (
    <View
      display="block"
      textAlign="end"
      borderWidth="small none none none"
      margin="none none"
      padding="large none"
    >
      <Button
        type="button"
        display={breakpoints.mobileOnly ? 'block' : 'inline-block'}
        color="secondary"
        margin={breakpoints.mobileOnly ? 'none none small none' : 'none xx-small none xx-small'}
        data-testid="announcement-cancel-button"
        onClick={() => {
          // @ts-expect-error
          assignLocation(ENV?.CANCEL_TO)
        }}
        disabled={isSubmitting}
      >
        {I18n.t('Cancel')}
      </Button>

      {shouldShowSaveAndPublishButton && (
        <Button
          type="submit"
          display={breakpoints.mobileOnly ? 'block' : 'inline-block'}
          onClick={() => submitForm(true)}
          color="secondary"
          margin={breakpoints.mobileOnly ? 'none none small none' : 'none xx-small none xx-small'}
          data-testid="save-and-publish-button"
          disabled={isSubmitting}
        >
          {I18n.t('Save and Publish')}
        </Button>
      )}
      {/* for announcements, show publish when the available until da */}
      {isAnnouncement ? (
        <Button
          type="submit"
          display={breakpoints.mobileOnly ? 'block' : 'inline-block'}
          // don't publish delayed announcements
          onClick={() => submitForm(willAnnouncementPostRightAway ? true : undefined)}
          color="primary"
          margin={breakpoints.mobileOnly ? 'none none small none' : 'none xx-small none xx-small'}
          data-testid="announcement-submit-button"
          disabled={isSubmitting}
        >
          {willAnnouncementPostRightAway && !isEditing ? I18n.t('Publish') : I18n.t('Save')}
        </Button>
      ) : (
        <Button
          type="submit"
          display={breakpoints.mobileOnly ? 'block' : 'inline-block'}
          data-testid="save-button"
          // when editing, use the current published state, otherwise:
          // students will always save as published while for moderators in this case they
          // can save as unpublished
          onClick={() =>
            // @ts-expect-error
            submitForm(isEditing ? published : !ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE)
          }
          color="primary"
          margin={breakpoints.mobileOnly ? 'none none small none' : 'none xx-small none xx-small'}
          disabled={isSubmitting}
        >
          {I18n.t('Save')}
        </Button>
      )}
    </View>
  )
}
