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

import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('discussion_create')

export const FormControlButtons = ({
  isAnnouncement,
  isEditing,
  published,
  shouldShowSaveAndPublishButton,
  submitForm,
  isSubmitting,
  willAnnouncementPostRightAway,
}: {
  isAnnouncement: boolean
  isEditing: boolean
  published: boolean
  shouldShowSaveAndPublishButton: boolean
  submitForm: (publish: boolean) => void
  isSubmitting: boolean
  willAnnouncementPostRightAway: boolean
}) => {
  return (
    <View
      display="block"
      textAlign="end"
      borderWidth="small none none none"
      margin="xx-large none"
      padding="large none"
    >
      <View margin="0 x-small 0 0">
        <Button
          type="button"
          color="secondary"
          onClick={() => {
            // @ts-expect-error
            window.location.assign(ENV?.CANCEL_TO)
          }}
          disabled={isSubmitting}
        >
          {I18n.t('Cancel')}
        </Button>
      </View>
      {shouldShowSaveAndPublishButton && (
        <View margin="0 x-small 0 0">
          <Button
            type="submit"
            onClick={() => submitForm(true)}
            color="secondary"
            margin="xxx-small"
            data-testid="save-and-publish-button"
            disabled={isSubmitting}
          >
            {I18n.t('Save and Publish')}
          </Button>
        </View>
      )}
      {/* for announcements, show publish when the available until da */}
      {isAnnouncement ? (
        <Button
          type="submit"
          // we always process announcements as published.
          onClick={() => submitForm(true)}
          color="primary"
          margin="xxx-small"
          data-testid="announcement-submit-button"
          disabled={isSubmitting}
        >
          {willAnnouncementPostRightAway ? I18n.t('Publish') : I18n.t('Save')}
        </Button>
      ) : (
        <Button
          type="submit"
          data-testid="save-button"
          // when editing, use the current published state, otherwise:
          // students will always save as published while for moderators in this case they
          // can save as unpublished
          onClick={() =>
            // @ts-expect-error
            submitForm(isEditing ? published : !ENV.DISCUSSION_TOPIC?.PERMISSIONS?.CAN_MODERATE)
          }
          color="primary"
          disabled={isSubmitting}
        >
          {I18n.t('Save')}
        </Button>
      )}
    </View>
  )
}
