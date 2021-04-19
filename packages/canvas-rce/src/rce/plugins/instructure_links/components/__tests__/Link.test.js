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
      type="assignments"
      link={{href: 'the_url', title: 'object title'}}
      describedByID="dbid"
      onClick={() => {}}
      {...props}
    />
  )
}

function queryIconByName(elem, name) {
  return elem.querySelector(`svg[name="${name}"]`)
}

describe('RCE "Links" Plugin > Link', () => {
  describe('object type variant', () => {
    const linkTypes = [
      {type: 'assignments', icon: 'IconAssignment'},
      {type: 'discussions', icon: 'IconDiscussion'},
      {type: 'modules', icon: 'IconModule'},
      {type: 'quizzes', icon: 'IconQuiz'},
      {type: 'announcements', icon: 'IconAnnouncement'},
      {type: 'wikiPages', icon: 'IconDocument'},
      {type: 'navigation', icon: 'IconBlank'}
    ]

    linkTypes.forEach(lt => {
      it(`renders published ${lt.type}`, () => {
        const link = {
          href: 'the_url',
          title: 'object title',
          published: true
        }
        const {container, getByText} = renderComponent({type: lt.type, link})

        expect(getByText(link.title)).toBeInTheDocument()
        expect(queryIconByName(container, 'IconPublish')).toBeInTheDocument()
        expect(queryIconByName(container, lt.icon)).toBeInTheDocument()
      })

      it(`renders unpublished ${lt.type}`, () => {
        const link = {
          href: 'the_url',
          title: 'object title',
          published: false
        }
        const {container, getByText} = renderComponent({type: lt.type, link})

        expect(getByText(link.title)).toBeInTheDocument()
        expect(queryIconByName(container, 'IconUnpublished')).toBeInTheDocument()
        expect(queryIconByName(container, lt.icon)).toBeInTheDocument()
      })
    })
  })
  describe('date variant', () => {
    const value = '2019-04-24T13:00:00Z'
    const formattedValue = formatMessage.date(Date.parse(value), 'long')

    it('renders muliple due dates', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: 'multiple',
        date_type: 'due'
      }
      const {getByText} = renderComponent({type: 'assignments', link})

      expect(getByText('Due: Multiple Dates')).toBeInTheDocument()
    })

    it('renders a due date', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: value,
        date_type: 'due'
      }
      const {getByText} = renderComponent({type: 'assignments', link})

      expect(getByText(`Due: ${formattedValue}`)).toBeInTheDocument()
    })

    it('renders a to do date', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: value,
        date_type: 'todo'
      }
      const {getByText} = renderComponent({type: 'wikiPages', link})

      expect(getByText(`To Do: ${formattedValue}`)).toBeInTheDocument()
    })

    it('renders a published date', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: value,
        date_type: 'published'
      }
      const {getByText} = renderComponent({type: 'wikiPages', link})

      expect(getByText(`Published: ${formattedValue}`)).toBeInTheDocument()
    })

    it('renders a posted date', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: value,
        date_type: 'posted'
      }
      const {getByText} = renderComponent({type: 'announcements', link})

      expect(getByText(`Posted: ${formattedValue}`)).toBeInTheDocument()
    })

    it('renders a delayed post date', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: value,
        date_type: 'delayed_post'
      }
      const {getByText} = renderComponent({type: 'announcements', link})

      expect(getByText(`To Be Posted: ${formattedValue}`)).toBeInTheDocument()
    })
  })
  describe('handles input', () => {
    it('calls onClick when clicked', () => {
      const onClick = jest.fn()
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true
      }
      const {getByText} = renderComponent({link, onClick})

      const btn = getByText(link.title)
      btn.click()
      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick on <Enter>', () => {
      const onClick = jest.fn()
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true
      }
      const {getByText} = renderComponent({link, onClick})

      const btn = getByText(link.title)
      fireEvent.keyDown(btn, {keyCode: 13})
      expect(onClick).toHaveBeenCalled()
    })

    it('calls onClick on <Space>', () => {
      const onClick = jest.fn()
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true
      }
      const {getByText} = renderComponent({link, onClick})

      const btn = getByText(link.title)
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
