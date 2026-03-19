/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import ClosedCaptionCreator from './ClosedCaptionCreator'
import ClosedCaptionCreatorV2 from './ClosedCaptionCreatorV2'
import closedCaptionLanguages, {
  captionLanguageForLocale,
  sortedClosedCaptionLanguageList,
} from './closedCaptionLanguages'
import getTranslations from './getTranslations'
import RocketSVG from './RocketSVG'
import saveMediaRecording, {
  saveClosedCaptions,
  saveClosedCaptionsForAttachment,
} from './saveMediaRecording'
import * as CONSTANTS from './shared/constants'
import LoadingIndicator from './shared/LoadingIndicator'
import {isAudio, isPreviewable, isVideo, sizeMediaPlayer} from './shared/utils'
import UploadMedia from './UploadMedia'
import useComputerPanelFocus from './useComputerPanelFocus'

export {
  UploadMedia as default,
  ClosedCaptionCreator as ClosedCaptionPanel,
  ClosedCaptionCreatorV2 as ClosedCaptionPanelV2,
  RocketSVG,
  useComputerPanelFocus,
  isAudio,
  isVideo,
  isPreviewable,
  sizeMediaPlayer,
  LoadingIndicator,
  saveMediaRecording,
  saveClosedCaptions,
  saveClosedCaptionsForAttachment,
  closedCaptionLanguages,
  sortedClosedCaptionLanguageList,
  captionLanguageForLocale,
  getTranslations,
  CONSTANTS,
}
