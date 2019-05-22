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
import {render, fireEvent} from 'react-testing-library'
import formatMessage from '../../../../../format-message';
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
      published={true}
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
    it('renders the date', () => {
      const value = '2019-04-24T13:00:00Z'
      const formattedValue = formatMessage.date(Date.parse(value), 'long')

      const {getByText} = renderComponent({date: value})

      expect(getByText(formattedValue)).toBeInTheDocument()
    })

    it('renders the display_name', () => {
      const {getByText} = renderComponent()
      expect(getByText('file display name')).toBeInTheDocument()
    })

    it('renders the filename if there is no display_name', () => {
      const {getByText} = renderComponent({display_name: undefined})
      expect(getByText('filename.txt')).toBeInTheDocument()
    })

    it('renders as published', () => {
      const {container} = renderComponent({published: true})
      expect(queryIconByName(container, 'IconPublish')).toBeInTheDocument()
    })

    it('renders as unpublished', () => {
      const {container} = renderComponent({published: false})
      expect(queryIconByName(container, 'IconUnpublished')).toBeInTheDocument()
    })

    it('renders the doc icon', () => {
      const {container} = renderComponent()
      expect(queryIconByName(container, 'IconDocument')).toBeInTheDocument()
    })

    it('renders the ppt icon', () => {
      const {container} = renderComponent({content_type: 'application/vnd.ms-powerpoint'})
      expect(queryIconByName(container, 'IconMsPpt')).toBeInTheDocument()
    })

    it('renders the word icon', () => {
      const {container} = renderComponent({content_type: 'application/msword'})
      expect(queryIconByName(container, 'IconMsWord')).toBeInTheDocument()
    })

    it('renders the excel icon', () => {
      const {container} = renderComponent({content_type: 'application/vnd.ms-excel'})
      expect(queryIconByName(container, 'IconMsExcel')).toBeInTheDocument()
    })

    it('renders the pdf icon', () => {
      const {container} = renderComponent({content_type: 'application/pdf'})
      expect(queryIconByName(container, 'IconPdf')).toBeInTheDocument()
    })

    it('only shows drag handle on hover', () => {
      const {container, getByTestId} = renderComponent()

      expect(queryIconByName(container, "IconDragHandle")).not.toBeInTheDocument()
      fireEvent.mouseEnter(getByTestId('instructure_links-Link'))
      expect(queryIconByName(container, "IconDragHandle")).toBeInTheDocument()
    })
  })

  describe('handles input', () => {
    it('calls onClick when clicked', () => {
      const onClick = jest.fn()
      const {getByText} = renderComponent({display_name: 'click me', onClick: onClick})

      const btn = getByText('click me')
      btn.click()
      expect(onClick).toHaveBeenCalled()
    })
  })


})

