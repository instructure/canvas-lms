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

import {isVideo, isAudio, sizeMediaPlayer} from '../shared/utils'

describe('media utilities', () => {
  describe('isVideo', () => {
    it('identifies video content types', () => {
      expect(isVideo('video')).toBe(true)
      expect(isVideo('video/mov')).toBe(true)
      expect(isVideo('notVideo')).toBe(false)
    })
  })
  describe('isAudio', () => {
    it('identifies video content types', () => {
      expect(isAudio('audio')).toBe(true)
      expect(isAudio('audio/mp3')).toBe(true)
      expect(isAudio('notAudio')).toBe(false)
    })
  })
  describe('sizeMediaPlayer', () => {
    it('sizes landscape videos constrained horizontally', () => {
      const sz = sizeMediaPlayer({videoWidth: 1000, videoHeight: 700}, 'video', {
        width: 500,
        height: 500
      })
      expect(sz.width).toEqual('500px')
      expect(sz.height).toEqual('350px')
    })
    it('sizes portrait videos constrained vertically', () => {
      const sz = sizeMediaPlayer({videoWidth: 700, videoHeight: 1000}, 'video', {
        width: 500,
        height: 250
      })
      expect(sz.width).toEqual('175px')
      expect(sz.height).toEqual('250px')
    })
    it('sizes small landscape videos to fill the available space', () => {
      const sz = sizeMediaPlayer({videoWidth: 500, videoHeight: 250}, 'video', {
        width: 1000,
        height: 800
      })
      expect(sz.width).toEqual('1000px')
      expect(sz.height).toEqual('500px')
    })
    it('sizes small portrait videos to fill the available space', () => {
      const sz = sizeMediaPlayer(
        {videoWidth: 250, videoHeight: 500},
        'video',
        {
          width: 1000,
          height: 800
        },
        true
      )
      expect(sz.width).toEqual('400px')
      expect(sz.height).toEqual('800px')
    })
    it('applies original video dimensions if container is null or undefined', () => {
      const sz = sizeMediaPlayer({videoWidth: 250, videoHeight: 500}, 'video', null)
      expect(sz.width).toEqual('250px')
      expect(sz.height).toEqual('500px')
    })

    it('constrains the height to be within the container', () => {
      const sz = sizeMediaPlayer(
        {videoWidth: 800, videoHeight: 500},
        'video',
        {
          width: 800,
          height: 400
        },
        true
      )
      expect(sz.width).toEqual('640px')
      expect(sz.height).toEqual('400px')
    })
  })
})
