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

import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import {NoTranscript} from './components/NoTranscript'
import styles from './ImmersiveView.module.css'
import {ImmersiveViewBackButton} from './components/ImmersiveViewBackButton'
import {useMedia} from 'react-use'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'

export type ImmersiveViewProps = {
  id: string
  title: string
  attachmentId?: string
  isAttachment?: boolean
}

const I18n = createI18nScope('media_immersive_view')

export function ImmersiveView({id, title, attachmentId, isAttachment}: ImmersiveViewProps) {
  const rollingTranscriptElementId = 'immersive-view-transcript-root'
  const isTablet = !useMedia('(min-width: 769px)')
  const playerHeight = isTablet ? 'calc(100vw / (16 / 9) + 40px)' : '490px'

  return (
    <div className={styles.immersiveView}>
      <div className={styles.immersiveViewHeader}>
        <h1 className={styles.immersiveViewTitle}>{title}</h1>
        <ImmersiveViewBackButton />
      </div>

      <div className={styles.immersiveViewContent}>
        <CanvasStudioPlayer
          explicitSize={{height: playerHeight, width: '100%'}}
          media_id={id}
          attachment_id={attachmentId}
          is_attachment={isAttachment}
          aria_label={title}
          type="video"
          enableSidebar={!isTablet}
          openSidebar={!isTablet}
          emptyTranscriptsComponent={<NoTranscript />}
          hideUploadCaptions
          show_loader={true}
          rollingTranscriptElement={isTablet ? rollingTranscriptElementId : undefined}
        />

        {isTablet && (
          <Heading variant="titleCardRegular" level="h2" margin="small">
            {I18n.t('Transcript')}
          </Heading>
        )}

        <div className={styles.immersivViewTranscript} id={rollingTranscriptElementId} />
      </div>
    </div>
  )
}
