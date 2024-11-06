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

export type ClickableImageProps = {
  editable: boolean
  onClick: () => void
  size: 'small' | 'medium' | 'large'
  sticker: Sticker
}

export type IconOverlayProps = {
  showIcon: boolean
  sticker: Sticker
}

type BaseSubmission = {
  assignmentId: string
  courseId: string
  sticker: Sticker
}

type AnonymousUserSubmission = BaseSubmission & {
  anonymousId: string
  userId?: never
}

type KnownUserSubmission = BaseSubmission & {
  anonymousId?: never
  userId: string
}

export type Submission = AnonymousUserSubmission | KnownUserSubmission

export type StickerDescriptions = {
  [key: string]: string
}

type Sticker = string | null

export type StickerModalProps = {
  liveRegion: () => HTMLElement
  onDismiss: () => void
  onRemoveSticker: () => void
  onSelectSticker: (sticker: Sticker) => void
  open: boolean
  sticker: Sticker
}

export type StickerProps = {
  confetti: boolean
  editable: boolean
  liveRegion?: () => HTMLElement | null
  onStickerChange?: (sticker: Sticker) => void
  size: 'small' | 'medium' | 'large'
  submission: Submission
}
