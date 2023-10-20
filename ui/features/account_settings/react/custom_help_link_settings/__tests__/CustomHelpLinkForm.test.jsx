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

import CustomHelpLinkForm from '../CustomHelpLinkForm'
import {render, fireEvent} from '@testing-library/react'

function makeProps(overrides = {}) {
  const linkOverride = overrides.link || {}
  delete overrides.link
  return {
    link: {
      available_to: ['student'],
      text: 'Ask Your Instructor a Question',
      subtext: 'Questions are submitted to your instructor',
      url: '#teacher_feedback',
      type: 'default',
      is_featured: false,
      is_new: false,
      feature_headline: '',
      ...linkOverride,
    },
    ...overrides,
  }
}

describe('<CustomHelpLinkForm/>', () => {
  it('renders', () => {
    const {getByLabelText} = render(<CustomHelpLinkForm {...makeProps()} />)
    expect(getByLabelText('Link name')).toBeInTheDocument()
  })

  describe('with featured help links', () => {
    beforeEach(() => {
      window.ENV = {FEATURES: {featured_help_links: true}}
    })

    afterEach(() => {
      window.ENV = {}
    })

    it('renders featured checkboxes unchecked if features are not selected', () => {
      const {getByLabelText} = render(<CustomHelpLinkForm {...makeProps()} />)
      expect(getByLabelText('Featured').checked).toBe(false)
      expect(getByLabelText('New').checked).toBe(false)
      expect(getByLabelText('Feature headline').disabled).toBe(true)
    })

    it('renders featured checkbox checked if featured is selected', () => {
      const {getByLabelText} = render(
        <CustomHelpLinkForm {...makeProps({link: {is_featured: true, feature_headline: 'foo'}})} />
      )
      expect(getByLabelText('Featured').checked).toBe(true)
      expect(getByLabelText('Feature headline').disabled).toBe(false)
      expect(getByLabelText('Feature headline').value).toBe('foo')
    })

    it('renders new checkbox checked if new is selected', () => {
      const {getByLabelText} = render(<CustomHelpLinkForm {...makeProps({link: {is_new: true}})} />)
      expect(getByLabelText('New').checked).toBe(true)
    })

    it('sets featured to false if new is selected', () => {
      const {getByLabelText} = render(
        <CustomHelpLinkForm {...makeProps({link: {is_featured: true}})} />
      )
      fireEvent.click(getByLabelText('New'))
      expect(getByLabelText('Featured').checked).toBe(false)
    })

    it('sets new to false if featured is selected', () => {
      const {getByLabelText} = render(<CustomHelpLinkForm {...makeProps({link: {is_new: true}})} />)
      fireEvent.click(getByLabelText('Featured'))
      expect(getByLabelText('New').checked).toBe(false)
    })

    it('clears and restores feature_headline when featured is toggled', () => {
      const headline = 'This is my headline'
      const {getByLabelText, getByDisplayValue, queryByDisplayValue} = render(
        <CustomHelpLinkForm
          {...makeProps({link: {is_featured: true, feature_headline: headline}})}
        />
      )
      fireEvent.click(getByLabelText('Featured')) // disable
      expect(queryByDisplayValue(headline)).toBeNull()
      fireEvent.click(getByLabelText('Featured')) // re-enable
      expect(getByDisplayValue(headline)).toBeInTheDocument()
    })

    it('retains feature_headline when is_new is toggled', () => {
      const headline = 'This is my headline'
      const {getByLabelText, getByDisplayValue} = render(
        <CustomHelpLinkForm
          {...makeProps({link: {is_featured: true, feature_headline: headline}})}
        />
      )
      fireEvent.click(getByLabelText('New')) // enables new (disables featured)
      fireEvent.click(getByLabelText('New')) // disables new
      fireEvent.click(getByLabelText('New')) // enables new
      fireEvent.click(getByLabelText('Featured'))
      expect(getByLabelText('Featured').checked).toBe(true)
      expect(getByLabelText('New').checked).toBe(false)
      expect(getByDisplayValue('This is my headline')).toBeInTheDocument()
    })
  })
})
