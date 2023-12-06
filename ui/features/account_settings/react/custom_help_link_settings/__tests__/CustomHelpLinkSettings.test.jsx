// @vitest-environment jsdom
/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import CustomHelpLinkSettings from '../CustomHelpLinkSettings'
import {render, fireEvent, within} from '@testing-library/react'
import $ from 'jquery'
import sinon from 'sinon'

function makeProps(overrides = {}) {
  const defaultLinks = [
    {
      available_to: ['student'],
      text: 'Ask Your Instructor a Question',
      subtext: 'Questions are submitted to your instructor',
      url: '#teacher_feedback',
      type: 'default',
      is_featured: false,
      is_new: false,
      feature_headline: '',
    },
    {
      available_to: ['user', 'student', 'teacher', 'admin'],
      text: 'Search the Canvas Guides',
      subtext: 'Find answers to common questions',
      url: 'https://community.canvaslms.test/t5/Canvas/ct-p/canvas',
      type: 'default',
      is_featured: false,
      is_new: false,
      feature_headline: '',
    },
    {
      available_to: ['user', 'student', 'teacher', 'admin'],
      text: 'Report a Problem',
      subtext: 'If Canvas misbehaves, tell us about it',
      url: '#create_ticket',
      type: 'default',
      is_featured: false,
      is_new: false,
      feature_headline: '',
    },
  ]

  return {
    name: 'Help',
    icon: 'help',
    links: defaultLinks,
    defaultLinks,
    ...overrides,
  }
}

const updateTextField = async (rendered, labelText, value) => {
  const input = await rendered.findByLabelText(labelText)
  fireEvent.change(input, {target: {value}})
  fireEvent.blur(input)
}

const addCustomLink = async (rendered, name = 'New link', callback = null) => {
  fireEvent.click(rendered.getByText('Add Link'))
  fireEvent.click(rendered.getByText('Add Custom Link'))
  await updateTextField(rendered, /Link name/, name)
  await updateTextField(rendered, /Link URL/, 'http://example.com')
  if (callback) {
    callback(rendered)
  }
  fireEvent.click(rendered.getByText('Add link'))
}

describe('<CustomHelpLinkSettings/>', () => {
  it('renders', () => {
    const {getByRole} = render(<CustomHelpLinkSettings {...makeProps()} />)
    expect(getByRole('heading', {text: 'Help menu options'})).toBeInTheDocument()
  })

  it('renders links', () => {
    const {getByText} = render(<CustomHelpLinkSettings {...makeProps()} />)
    expect(getByText('Search the Canvas Guides')).toBeInTheDocument()
  })

  it('puts links in editing mode', async () => {
    const {getByText, findByLabelText} = render(<CustomHelpLinkSettings {...makeProps()} />)
    fireEvent.click(getByText('Edit Report a Problem'))
    expect((await findByLabelText(/Link name/)).value).toBe('Report a Problem')
  })

  it('saves changes to links', async () => {
    const rendered = render(<CustomHelpLinkSettings {...makeProps()} />)

    fireEvent.click(rendered.getByText('Edit Report a Problem'))
    await updateTextField(rendered, /Link name/, 'Ignore a Problem')
    fireEvent.click(rendered.getByText('Update link'))

    expect(await rendered.findByText('Ignore a Problem')).toBeInTheDocument()
  })

  it('deletes links', () => {
    const {getByText, queryByText} = render(<CustomHelpLinkSettings {...makeProps()} />)
    fireEvent.click(getByText('Remove Report a Problem'))
    expect(queryByText('Report a Problem')).toBeNull()
  })

  it('adds custom links', async () => {
    const rendered = render(<CustomHelpLinkSettings {...makeProps()} />)

    await addCustomLink(rendered, 'This is a new link')

    expect(rendered.getByText('This is a new link')).toBeInTheDocument()
    expect(
      rendered.container.querySelector('input[name="account[custom_help_links][0][id]"').value
    ).toBe('link4')
    expect(
      rendered.container.querySelector('input[name="account[custom_help_links][0][text]"').value
    ).toBe('This is a new link')
    expect(
      rendered.container.querySelector('input[name="account[custom_help_links][0][type]"').value
    ).toBe('custom')
  })

  describe('validate', () => {
    beforeEach(() => {
      sinon.spy($, 'screenReaderFlashMessage')
    })

    afterEach(() => {
      $.screenReaderFlashMessage.restore()
    })

    it('accepts properly formatted urls', () => {
      const subject = new CustomHelpLinkSettings(makeProps())

      const link = {
        text: 'test link',
        available_to: ['user', 'student', 'teacher', 'admin'],
        url: '',
      }

      const valid = [
        'http://testurl.com',
        'https://testurl.com',
        'ftp://test.url/.test',
        'tel:1-999-999-9999',
        'mailto:test@test.com',
      ]

      const invalid = ['', null, 'nothing', 'myprotocol:foo']

      valid.forEach(validURL => {
        link.url = validURL
        expect(subject.validate(link)).toBe(true)
      })

      invalid.forEach(invalidURL => {
        link.url = invalidURL
        expect(subject.validate(link)).toBe(false)
      })
    })

    it('calls flashScreenreaderAlert when appropriate', async function () {
      const rendered = render(<CustomHelpLinkSettings {...makeProps()} />)

      // flash message when transitions to invalid
      await updateTextField(rendered, 'Name', '')
      expect($.screenReaderFlashMessage.callCount).toEqual(1)

      // no flash message as long as is invalid
      await updateTextField(rendered, 'Name', '')
      expect($.screenReaderFlashMessage.callCount).toEqual(1)

      // it's valid now
      await updateTextField(rendered, 'Name', 'foo')
      expect($.screenReaderFlashMessage.callCount).toEqual(1)

      // and invalid again, show message
      await updateTextField(rendered, 'Name', '')
      expect($.screenReaderFlashMessage.callCount).toEqual(2)
    })
  })

  describe('with featured help links', () => {
    beforeEach(() => {
      window.ENV = {FEATURES: {featured_help_links: true}}
    })

    afterEach(() => {
      window.ENV = {}
    })

    it('allows only one featured link', () => {
      const props = makeProps()
      props.links[0].is_featured = true // Ask your instructor
      const {getByText, getByLabelText, queryAllByText} = render(
        <CustomHelpLinkSettings {...props} />
      )
      expect(queryAllByText('Featured').length).toEqual(1)
      expect(
        within(getByText('Ask Your Instructor a Question').closest('li')).getByText('Featured')
      ).toBeInTheDocument()

      fireEvent.click(getByText('Edit Report a Problem'))
      fireEvent.click(getByLabelText('Featured'))
      fireEvent.click(getByText('Update link'))
      expect(queryAllByText('Featured').length).toEqual(1)
      expect(
        within(getByText('Report a Problem').closest('li')).getByText('Featured')
      ).toBeInTheDocument()
    })

    it('reorders links so that featured is first', () => {
      const props = makeProps()
      props.links[0].is_featured = true // Ask your instructor
      const {container, getByText, getByLabelText} = render(<CustomHelpLinkSettings {...props} />)

      fireEvent.click(getByText('Edit Report a Problem'))
      fireEvent.click(getByLabelText('Featured'))
      fireEvent.click(getByText('Update link'))
      const firstRow = container.querySelectorAll('li')[0]
      expect(within(firstRow).getByText('Featured')).toBeInTheDocument()
      expect(within(firstRow).getByText('Report a Problem')).toBeInTheDocument()
    })

    it('allows only one new link', () => {
      const props = makeProps()
      props.links[0].is_new = true // Ask your instructor
      const {getByText, getByLabelText} = render(<CustomHelpLinkSettings {...props} />)
      expect(getByText('New')).toBeInTheDocument()
      expect(
        within(getByText('Ask Your Instructor a Question').closest('li')).getByText('New')
      ).toBeInTheDocument()

      fireEvent.click(getByText('Edit Report a Problem'))
      fireEvent.click(getByLabelText('New'))
      fireEvent.click(getByText('Update link'))
      expect(getByText(/New/)).toBeInTheDocument()
      expect(
        within(getByText('Report a Problem').closest('li')).getByText('New')
      ).toBeInTheDocument()
    })

    it('adds link at second position when featured link exists', async () => {
      const props = makeProps()
      props.links[0].is_featured = true // Ask your instructor
      const rendered = render(<CustomHelpLinkSettings {...props} />)

      await addCustomLink(rendered, 'This is not featured')

      expect(
        within(rendered.container.querySelectorAll('li')[1]).getByText('This is not featured')
      ).toBeInTheDocument()
    })

    it('adds featured link at top position', async () => {
      const props = makeProps()
      props.links[0].is_featured = true // Ask your instructor
      const rendered = render(<CustomHelpLinkSettings {...props} />)

      await addCustomLink(rendered, 'This is newly featured', () => {
        fireEvent.click(rendered.getByLabelText('Featured'))
      })

      expect(
        within(rendered.container.querySelectorAll('li')[0]).getByText('This is newly featured')
      ).toBeInTheDocument()
    })
  })
})
