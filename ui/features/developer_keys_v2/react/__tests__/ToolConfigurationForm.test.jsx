/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ToolConfigurationForm from '../ToolConfigurationForm'

const defaultProps = (overrides = {}) => ({
  toolConfiguration: {
    name: 'Test Tool',
    url: 'https://www.test.com/launch',
    target_link_uri: 'https://example.com/target_link_uri',
  },
  toolConfigurationUrl: 'https://www.test.com/config.json',
  validScopes: {},
  validPlacements: [],
  editing: false,
  showRequiredMessages: false,
  dispatch: jest.fn(),
  updateConfigurationMethod: jest.fn(),
  configurationMethod: 'json',
  updateToolConfiguration: Function.prototype,
  updateToolConfigurationUrl: Function.prototype,
  prettifyPastedJson: jest.fn(),
  canPrettify: false,
  ...overrides,
})

const renderToolConfigurationForm = (props = {}, setup) => {
  const ref = React.createRef()
  const wrapper = render(<ToolConfigurationForm ref={ref} {...defaultProps(props)} />)

  if (setup) {
    setup(ref)
  }

  return {ref, wrapper}
}

describe('ToolConfigurationForm', () => {
  describe('when configuration method is by JSON', () => {
    const mountForm = (propOverrides = {}) =>
      renderToolConfigurationForm(propOverrides, ref => {
        ref.current.setState({configurationMethod: 'json'})
      })

    it('renders the tool configuration JSON in a text area', () => {
      mountForm()

      expect(
        screen.getByText(new RegExp(defaultProps().toolConfiguration.url, 'i'))
      ).toBeInTheDocument()
    })

    it('transitions to configuring by URL when the url option is selected', () => {
      const {ref} = mountForm()

      fireEvent.click(screen.getByRole('combobox', {name: /method/i}))
      fireEvent.click(document.querySelector('[value="url"]'))

      expect(ref.current.props.updateConfigurationMethod).toHaveBeenCalled()
    })

    it('renders the text in the jsonString prop', () => {
      mountForm({jsonString: '{"test": "test"}'})

      expect(screen.getByText(/{"test": "test"}/)).toBeInTheDocument()
    })

    it('prefers the text in the invalidJson prop even if it is an empty string', () => {
      mountForm({jsonString: '{"test": "test"}', invalidJson: ''})

      expect(screen.queryByText(/test/)).not.toBeInTheDocument()
    })

    it('renders a button that fires the prettifyPastedJson prop', () => {
      const {ref} = mountForm({canPrettify: true})

      fireEvent.click(screen.getByRole('button'))

      expect(ref.current.props.prettifyPastedJson).toHaveBeenCalled()
    })

    it('does not render a visible manual configuration', async () => {
      renderToolConfigurationForm()

      const elem1 = screen.queryByText(/Target Link URI/)
      const elem2 = screen.queryByText(/OpenID Connect Initiation Url/)

      expect(elem1).not.toBeVisible()
      expect(elem2).not.toBeVisible()
    })

    it('validates the JSON syntax', async () => {
      const {ref} = mountForm({invalidJson: '{invalid json text}'})
      expect(ref.current.valid()).toBeFalsy()
    })
  })

  describe('when configuration method is by URL', () => {
    it('renders the tool configuration URL in a text input', () => {
      renderToolConfigurationForm({configurationMethod: 'url'})

      expect(screen.getByDisplayValue(defaultProps().toolConfigurationUrl)).toBeInTheDocument()
    })

    it('transitions to configuring by JSON when the json option is selected', () => {
      const {ref} = renderToolConfigurationForm({
        configurationMethod: 'url',
        updatePastedJson: jest.fn(),
      })

      fireEvent.click(screen.getByRole('combobox', {name: /method/i}))
      fireEvent.click(document.querySelector('[value="json"]'))

      expect(ref.current.props.updateConfigurationMethod).toHaveBeenCalled()
      expect(ref.current.props.updatePastedJson).toHaveBeenCalled()
    })
  })

  describe('when configuration method is manual', () => {
    it('renders the manual configuration form', () => {
      renderToolConfigurationForm({configurationMethod: 'manual'})

      expect(screen.getAllByRole('group').length).toBeTruthy()
    })

    it('renders a visible manual configuration', () => {
      renderToolConfigurationForm({configurationMethod: 'manual'})

      const elem1 = screen.queryByText('* Target Link URI')
      const elem2 = screen.queryByText('* OpenID Connect Initiation Url')

      expect(elem1).toBeVisible()
      expect(elem2).toBeVisible()
    })

    it('preserves state when changing to Pasted JSON mode and back again', async () => {
      const {wrapper} = renderToolConfigurationForm({configurationMethod: 'manual'})
      const user = userEvent.setup()
      const props = defaultProps({configurationMethod: 'manual'})
      const oldUrl = props.toolConfiguration.target_link_uri
      const newUrl = oldUrl + 'abc'
      const input = wrapper.queryByDisplayValue(oldUrl)

      await user.type(input, 'abc')

      expect(wrapper.queryByDisplayValue(newUrl)).toBeTruthy()
      wrapper.rerender(<ToolConfigurationForm {...defaultProps({configurationMethod: 'json'})} />)
      wrapper.rerender(<ToolConfigurationForm {...defaultProps({configurationMethod: 'manual'})} />)
      expect(wrapper.queryByDisplayValue(newUrl)).toBeTruthy()
    })
  })
})
