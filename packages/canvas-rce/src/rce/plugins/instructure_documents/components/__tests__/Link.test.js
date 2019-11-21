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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import formatMessage from '../../../../../format-message'
import Link from '../Link'

function renderComponent(props) {
  return render(
    <Link
      content_type="text/plain"
      date="2018-07-11T21:04:44Z"
      display_name="file display name"
      filename="filename.txt"
      hidden_to_use={false}
      href="http://192.168.86.175:3000/files/469/download?download_frd=1"
      id={469}
      lock_at={null}
      locked_for_user={false}
      published
      unlock_at={null}
      onClick={() => {}}
      {...props}
    />
  )
}

function queryIconByName(elem, name) {
  return elem.querySelector(`svg[name="${name}"]`)
}

describe('RCE "Documents" Plugin > Document', () => {
  describe('renders', () => {
    it('the date', () => {
      const value = '2019-04-24T13:00:00Z'
      const formattedValue = formatMessage.date(Date.parse(value), 'long')

      const {getByText} = renderComponent({date: value})

      expect(getByText(formattedValue)).toBeInTheDocument()
    })

    it('the display_name', () => {
      const {getByText} = renderComponent()
      expect(getByText('file display name')).toBeInTheDocument()
    })

    it('the filename if there is no display_name', () => {
      const {getByText} = renderComponent({display_name: undefined})
      expect(getByText('filename.txt')).toBeInTheDocument()
    })

    it('as published', () => {
      const {container} = renderComponent({published: true})
      expect(queryIconByName(container, 'IconPublish')).toBeInTheDocument()
    })

    it('as unpublished', () => {
      const {container} = renderComponent({published: false})
      expect(queryIconByName(container, 'IconUnpublished')).toBeInTheDocument()
    })

    it('the doc icon', () => {
      const {container} = renderComponent()
      expect(queryIconByName(container, 'IconDocument')).toBeInTheDocument()
    })

    it('the ppt icon', () => {
      const {container} = renderComponent({content_type: 'application/vnd.ms-powerpoint'})
      expect(queryIconByName(container, 'IconMsPpt')).toBeInTheDocument()
    })

    it('the word icon', () => {
      const {container} = renderComponent({content_type: 'application/msword'})
      expect(queryIconByName(container, 'IconMsWord')).toBeInTheDocument()
    })

    it('the excel icon', () => {
      const {container} = renderComponent({content_type: 'application/vnd.ms-excel'})
      expect(queryIconByName(container, 'IconMsExcel')).toBeInTheDocument()
    })

    it('the pdf icon', () => {
      const {container} = renderComponent({content_type: 'application/pdf'})
      expect(queryIconByName(container, 'IconPdf')).toBeInTheDocument()
    })

    it('the video icon', () => {
      const {container} = renderComponent({content_type: 'video/mp4'})
      expect(queryIconByName(container, 'IconVideo')).toBeInTheDocument()
    })

    it('the audio icon', () => {
      const {container} = renderComponent({content_type: 'audio/mp3'})
      expect(queryIconByName(container, 'IconAudio')).toBeInTheDocument()
    })

    it('the drag handle only on hover', () => {
      const {container, getByTestId} = renderComponent()

      expect(queryIconByName(container, 'IconDragHandle')).not.toBeInTheDocument()
      fireEvent.mouseEnter(getByTestId('instructure_links-Link'))
      expect(queryIconByName(container, 'IconDragHandle')).toBeInTheDocument()
    })
  })

  describe('handles input', () => {
    it('calls onClick when clicked', () => {
      const onClick = jest.fn()
      const {getByText} = renderComponent({display_name: 'click me', onClick})

      const btn = getByText('click me')
      btn.click()
      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick on <Enter>', () => {
      const onClick = jest.fn()
      const {getByText} = renderComponent({display_name: 'click me', onClick})

      const btn = getByText('click me')
      fireEvent.keyDown(btn, {keyCode: 13})
      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick on <Space>', () => {
      const onClick = jest.fn()
      const {getByText} = renderComponent({display_name: 'click me', onClick})

      const btn = getByText('click me')
      fireEvent.keyDown(btn, {keyCode: 32})
      expect(onClick).toHaveBeenCalled()
    })

    it('only shows drag handle on hover', () => {
      const {container, getByTestId} = renderComponent()

      expect(container.querySelectorAll('svg[name="IconDragHandle"]')).toHaveLength(0)
      fireEvent.mouseEnter(getByTestId('instructure_links-Link'))
      expect(container.querySelectorAll('svg[name="IconDragHandle"]')).toHaveLength(1)
    })
  })
})
