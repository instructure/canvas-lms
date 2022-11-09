/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import FileUploader from '../FileUploader'
import {ICON_MAKER_ICONS} from '../../../../../../packages/canvas-rce/src/rce/plugins/instructure_icon_maker/svg/constants'

let fileOptions: object, folder: object

beforeEach(() => {
  folder = {}
  fileOptions = {
    file: {},
  }
})

const uploader = () => new FileUploader(fileOptions, folder)

describe('createPreFlightParams()', () => {
  const subject = () => uploader().createPreFlightParams()

  beforeEach(() => {
    fileOptions = {...fileOptions, category: ICON_MAKER_ICONS}
  })

  describe('when a "category" option is given', () => {
    it('sets the category', () => {
      expect(subject().category).toEqual(ICON_MAKER_ICONS)
    })
  })
})
