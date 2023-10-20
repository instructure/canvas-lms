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

import {useScope as useI18nScope} from '@canvas/i18n'
import type {StickerDescriptions} from '../types/stickers.d'

const I18n = useI18nScope('submission_sticker')

export function stickerDescriptions(name: string): string {
  const descriptions: StickerDescriptions = {
    star: I18n.t('A sticker with a picture of a smiling star.'),
    trophy: I18n.t('A sticker with a picture of a golden trophy.'),
    target: I18n.t('A sticker with a picture of an archery target with an arrow in the center.'),
    apple: I18n.t('A sticker with a picture of an apple.'),
    paintbrush: I18n.t('A sticker with a picture of a paint brush.'),
    pencil: I18n.t('A sticker with a picture of a pencil.'),
    design: I18n.t('A sticker with a picture of a fountain pen nib.'),
    pen: I18n.t('A sticker with a picture of a pen.'),
    science2: I18n.t('A sticker with a picture of an atom.'),
    microscope: I18n.t('A sticker with a picture of a microscope.'),
    telescope: I18n.t('A sticker with a picture of a telescope.'),
    beaker: I18n.t('A sticker with a picture of a triangular lab beaker with a narrow neck.'),
    chem: I18n.t('A sticker with a picture of a circular lab beaker with a narrow neck.'),
    science: I18n.t('A sticker with a picture of a molecule.'),
    basketball: I18n.t('A sticker with a picture of a basketball.'),
    gym: I18n.t('A sticker with a picture of a jumping rope.'),
    book: I18n.t('A sticker with a picture of a book.'),
    composite_notebook: I18n.t('A sticker with a picture of a composite notebook.'),
    notebook: I18n.t('A sticker with a picture of a spiral-bound notebook.'),
    page: I18n.t('A sticker with a picture of a piece of paper.'),
    mail: I18n.t('A sticker with a picture of an envelope.'),
    music: I18n.t('A sticker with a picture of a musical note.'),
    globe: I18n.t('A sticker with a picture of a globe.'),
    computer: I18n.t('A sticker with a picture of a computer.'),
    tablet: I18n.t('A sticker with a picture of a tablet computer.'),
    calculator: I18n.t('A sticker with a picture of a calculator.'),
    mouse: I18n.t('A sticker with a picture of a computer mouse.'),
    panda1: I18n.t('A sticker with a picture of an open-mouth smiling panda crying tears of joy.'),
    panda2: I18n.t(
      'A sticker with a picture of an open-mouth smiling panda with hearts in its eyes.'
    ),
    panda3: I18n.t('A sticker with a picture of a closed-mouth panda smiling.'),
    panda4: I18n.t('A sticker with a picture of an open-mouth panda making a surprised face.'),
    panda5: I18n.t('A sticker with a picture of an open-mouth panda smiling.'),
    panda6: I18n.t('A sticker with a picture of a panda with a half-open mouth, smiling.'),
    panda7: I18n.t('A sticker with a picture of a panda grinning.'),
    panda8: I18n.t('A sticker with a picture of a panda smiling.'),
    panda9: I18n.t('A sticker with a picture of a panda grinning.'),
    bookbag: I18n.t('A sticker with a picture of a bookbag.'),
    briefcase: I18n.t('A sticker with a picture of a briefcase.'),
    grad: I18n.t('A sticker with a picture of a graduation cap.'),
    bus: I18n.t('A sticker with a picture of a school bus.'),
    bell: I18n.t('A sticker with a picture of a bell.'),
    clock: I18n.t('A sticker with a picture of a wall clock.'),
    calendar: I18n.t('A sticker with a picture of a calendar.'),
    paperclip: I18n.t('A sticker with a picture of a paperclip.'),
    scissors: I18n.t('A sticker with a picture of scissors.'),
    ruler: I18n.t('A sticker with a picture of a ruler.'),
    tape: I18n.t('A sticker with a picture of a tape roll dispenser.'),
    tag: I18n.t('A sticker with a picture of a clip-on identification tag.'),
    presentation: I18n.t(
      'A sticker with a picture of a projector screen with presentation content on it.'
    ),
    column: I18n.t('A sticker with a picture of a roman column.'),
  }

  return descriptions[name]
}

export default function assetFactory(key: string): string {
  switch (key) {
    case 'apple':
      return require('../../images/apple.svg')
    case 'basketball':
      return require('../../images/basketball.svg')
    case 'bell':
      return require('../../images/bell.svg')
    case 'book':
      return require('../../images/book.svg')
    case 'bookbag':
      return require('../../images/bookbag.svg')
    case 'briefcase':
      return require('../../images/briefcase.svg')
    case 'bus':
      return require('../../images/bus.svg')
    case 'calendar':
      return require('../../images/calendar.svg')
    case 'chem':
      return require('../../images/chem.svg')
    case 'design':
      return require('../../images/design.svg')
    case 'pencil':
      return require('../../images/pencil.svg')
    case 'beaker':
      return require('../../images/beaker.svg')
    case 'paintbrush':
      return require('../../images/paintbrush.svg')
    case 'computer':
      return require('../../images/computer.svg')
    case 'column':
      return require('../../images/column.svg')
    case 'pen':
      return require('../../images/pen.svg')
    case 'tablet':
      return require('../../images/tablet.svg')
    case 'telescope':
      return require('../../images/telescope.svg')
    case 'calculator':
      return require('../../images/calculator.svg')
    case 'paperclip':
      return require('../../images/paperclip.svg')
    case 'composite_notebook':
      return require('../../images/composite_notebook.svg')
    case 'scissors':
      return require('../../images/scissors.svg')
    case 'ruler':
      return require('../../images/ruler.svg')
    case 'clock':
      return require('../../images/clock.svg')
    case 'globe':
      return require('../../images/globe.svg')
    case 'grad':
      return require('../../images/grad.svg')
    case 'gym':
      return require('../../images/gym.svg')
    case 'mail':
      return require('../../images/mail.svg')
    case 'microscope':
      return require('../../images/microscope.svg')
    case 'mouse':
      return require('../../images/mouse.svg')
    case 'music':
      return require('../../images/music.svg')
    case 'notebook':
      return require('../../images/notebook.svg')
    case 'page':
      return require('../../images/page.svg')
    case 'panda1':
      return require('../../images/panda1.svg')
    case 'panda2':
      return require('../../images/panda2.svg')
    case 'panda3':
      return require('../../images/panda3.svg')
    case 'panda4':
      return require('../../images/panda4.svg')
    case 'panda5':
      return require('../../images/panda5.svg')
    case 'panda6':
      return require('../../images/panda6.svg')
    case 'panda7':
      return require('../../images/panda7.svg')
    case 'panda8':
      return require('../../images/panda8.svg')
    case 'panda9':
      return require('../../images/panda9.svg')
    case 'presentation':
      return require('../../images/presentation.svg')
    case 'science':
      return require('../../images/science.svg')
    case 'science2':
      return require('../../images/science2.svg')
    case 'star':
      return require('../../images/star.svg')
    case 'tag':
      return require('../../images/tag.svg')
    case 'tape':
      return require('../../images/tape.svg')
    case 'target':
      return require('../../images/target.svg')
    case 'trophy':
      return require('../../images/trophy.svg')
    default:
      throw new Error(`Unknown asset key: ${key}`)
  }
}
