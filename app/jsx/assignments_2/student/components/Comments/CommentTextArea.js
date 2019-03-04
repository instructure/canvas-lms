/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import I18n from 'i18n!assignments_2'
import React from 'react'
import Button from '@instructure/ui-buttons/lib/components/Button'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import IconPaperclip from '@instructure/ui-icons/lib/Line/IconPaperclip'
import IconMedia from '@instructure/ui-icons/lib/Line/IconMedia'
import IconAudio from '@instructure/ui-icons/lib/Line/IconAudio'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

function CommentTextArea() {
  return (
    <div>
      <div>
        <TextArea
          resize="both"
          label={<ScreenReaderContent>{I18n.t('Comment input box')}</ScreenReaderContent>}
        />
      </div>
      <div className="textarea-action-button-container">
        <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconPaperclip}>
          <ScreenReaderContent>{I18n.t('Attach a File')}</ScreenReaderContent>
        </Button>
        <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconMedia}>
          <ScreenReaderContent>{I18n.t('Record Video')}</ScreenReaderContent>
        </Button>
        <Button size="small" margin="0 x-small 0 0" variant="icon" icon={IconAudio}>
          <ScreenReaderContent>{I18n.t('Record Audio')}</ScreenReaderContent>
        </Button>
        <Button>{I18n.t('Send Comment')}</Button>
      </div>
    </div>
  )
}

export default React.memo(CommentTextArea)
