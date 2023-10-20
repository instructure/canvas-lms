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
import Link from '../Link'
import RCEGlobals from '../../../../RCEGlobals'

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
  beforeAll(() => {
    // UTC/GMT -7 hours
    RCEGlobals.getConfig = jest.fn().mockReturnValue({timezone: 'America/Denver'})
  })

  afterAll(() => {
    jest.resetAllMocks()
  })

  describe('object type variant', () => {
    const linkTypes = [
      {type: 'assignments', icon: 'IconAssignment'},
      {type: 'discussions', icon: 'IconDiscussion'},
      {type: 'modules', icon: 'IconModule'},
      {type: 'quizzes', icon: 'IconQuiz', quiz_type: 'assignment'},
      {type: 'quizzes', icon: 'IconQuiz', quiz_type: 'quizzes.next'},
      {type: 'announcements', icon: 'IconAnnouncement'},
      {type: 'wikiPages', icon: 'IconDocument'},
      {type: 'navigation', icon: 'IconBlank'},
    ]

    linkTypes.forEach(lt => {
      it(`renders published ${lt.type}`, () => {
        const link = {
          href: 'the_url',
          title: 'object title',
          published: true,
        }
        const {container, getByText} = renderComponent({
          type: lt.type,
          link: {...link, quiz_type: lt.quiz_type},
        })

        expect(getByText(link.title)).toBeInTheDocument()
        expect(queryIconByName(container, 'IconPublish')).toBeInTheDocument()
        const icon = queryIconByName(container, lt.icon)
        expect(icon).toBeInTheDocument()
        expect(icon.getAttribute('data-type')).toEqual(
          lt.type === 'quizzes' && lt.quiz_type === 'quizzes.next' ? 'quizzes.next' : lt.type
        )
      })

      it(`renders unpublished ${lt.type}`, () => {
        const link = {
          href: 'the_url',
          title: 'object title',
          published: false,
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
    const formattedValue = 'April 24, 2019'

    it('renders muliple due dates', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: 'multiple',
        date_type: 'due',
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
        date_type: 'due',
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
        date_type: 'todo',
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
        date_type: 'published',
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
        date_type: 'posted',
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
        date_type: 'delayed_post',
      }
      const {getByText} = renderComponent({type: 'announcements', link})

      expect(getByText(`To Be Posted: ${formattedValue}`)).toBeInTheDocument()
    })
  })

  describe('date changes by timezone', () => {
    const value = '2019-04-24T01:00:00Z'
    const formattedValue = 'April 23, 2019'

    it('renders muliple due dates', () => {
      const link = {
        href: 'the_url',
        title: 'object title',
        published: true,
        date: 'multiple',
        date_type: 'due',
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
        date_type: 'due',
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
        date_type: 'todo',
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
        date_type: 'published',
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
        date_type: 'posted',
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
        date_type: 'delayed_post',
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
        published: true,
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
        published: true,
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
        published: true,
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

  describe('When in edit link tray', () => {
    const props = {
      onEditClick: jest.fn(),
      editing: true,
      link: {
        href: 'the_url',
        title: 'object title',
        published: true,
      },
    }

    afterAll(() => {
      jest.resetAllMocks()
    })

    it('calls onEditClick when clicked', () => {
      const {getByText} = renderComponent(props)
      getByText(props.link.title).click()
      expect(props.onEditClick).toHaveBeenCalled()
    })

    it('calls onEditClick on <Enter>', () => {
      const {getByText} = renderComponent(props)
      const btn = getByText(props.link.title)
      fireEvent.keyDown(btn, {keyCode: 13})
      expect(props.onEditClick).toHaveBeenCalled()
    })

    it('calls onEditClick on <Space>', () => {
      const {getByText} = renderComponent(props)
      const btn = getByText(props.link.title)
      fireEvent.keyDown(btn, {keyCode: 32})
      expect(props.onEditClick).toHaveBeenCalled()
    })

    it('calls onEditClick with the appropriate args for a publishable link type', () => {
      const {getByText} = renderComponent(props)
      getByText(props.link.title).click()
      expect(props.onEditClick).toHaveBeenCalledWith({
        href: 'the_url',
        published: true,
        title: 'object title',
        type: 'assignments',
        'data-course-type': 'assignments',
        'data-published': true,
      })
    })

    it('calls onEditClick with the appropriate args for a non-publishable link type', () => {
      const {getByText} = renderComponent({...props, type: 'navigation'})
      getByText(props.link.title).click()
      expect(props.onEditClick).toHaveBeenCalledWith({
        href: 'the_url',
        published: true,
        title: 'object title',
        type: 'navigation',
        'data-course-type': 'navigation',
        'data-published': null,
      })
    })

    it('does not show the drag handle when hovering', () => {
      const {container, getByTestId} = renderComponent(props)
      fireEvent.mouseEnter(getByTestId('instructure_links-Link'))
      expect(container.querySelectorAll('svg[name="IconDragHandle"]')).toHaveLength(0)
    })
  })
})
