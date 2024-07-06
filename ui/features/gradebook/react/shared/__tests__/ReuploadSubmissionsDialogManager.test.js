/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ReuploadSubmissionsDialogManager from '../ReuploadSubmissionsDialogManager'

describe('ReuploadSubmissionsDialogManager', () => {
  describe('#constructor', () => {
    it('constructs reupload url from given assignment data and url template', () => {
      const manager = new ReuploadSubmissionsDialogManager(
        {id: 'the_id'},
        'the_{{ assignment_id }}_url',
        'user_22',
        {}
      )

      expect(manager.reuploadUrl).toBe('the_the_id_url')
    })
  })

  describe('#isDialogEnabled', () => {
    it('returns true when assignment submissions have been downloaded', () => {
      const manager = new ReuploadSubmissionsDialogManager({id: '123'}, 'the_url', 'user_22', {
        123: true,
      })

      expect(manager.isDialogEnabled()).toBe(true)
    })

    it('returns false when assignment submissions have not been downloaded', () => {
      const manager = new ReuploadSubmissionsDialogManager({id: '123'}, 'the_url', 'user_22', {
        123: false,
      })

      expect(manager.isDialogEnabled()).toBe(false)
    })
  })

  describe('#showDialog', () => {
    let getReuploadFormMock
    let attrMock

    beforeEach(() => {
      attrMock = jest.fn().mockReturnValue({dialog: jest.fn()})
      getReuploadFormMock = jest
        .spyOn(ReuploadSubmissionsDialogManager.prototype, 'getReuploadForm')
        .mockReturnValue({attr: attrMock})
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    it('sets form action to reupload url', () => {
      const manager = new ReuploadSubmissionsDialogManager(
        {id: 'the_id'},
        'the_{{ assignment_id }}_url',
        'user_22',
        {}
      )
      manager.showDialog()

      expect(attrMock).toHaveBeenCalledWith('action', 'the_the_id_url')
    })

    it('opens dialog', () => {
      const manager = new ReuploadSubmissionsDialogManager(
        {id: 'the_id'},
        'the_{{ assignment_id }}_url',
        'user_22',
        {}
      )
      const dialog = attrMock().dialog
      manager.showDialog()

      expect(dialog).toHaveBeenCalledTimes(1)
    })
  })
})
