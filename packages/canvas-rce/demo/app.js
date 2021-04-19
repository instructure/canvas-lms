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

import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup, Select} from '@instructure/ui-forms'
import {TextInput} from '@instructure/ui-text-input'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import '@instructure/canvas-theme'

import {renderIntoDiv, renderSidebarIntoDiv} from '../src/async'
import locales from '../src/locales'
import CanvasRce from '../src/rce/CanvasRce'
import * as fakeSource from '../src/sidebar/sources/fake'

function getProps(textareaId, state) {
  return {
    language: state.lang,

    editorOptions: () => {
      return {
        directionality: state.dir,
        height: '250px',
        plugins:
          'instructure-context-bindings, instructure-embeds, instructure-ui-icons, instructure_equation, ' +
          'instructure_image, instructure_equella, link, instructure_external_tools, instructure_record, ' +
          'instructure_links, table, lists, instructure_condensed_buttons, instructure_documents',
        // todo: add "instructure_embed" when the wiki sidebar work is done
        external_plugins: {},
        menubar: true
      }
    },

    textareaClassName: 'exampleClassOne',
    textareaId,
    onFocus: () => console.log('rce focused'), // eslint-disable-line no-console
    onBlur: () => console.log('rce blurred'), // eslint-disable-line no-console

    trayProps: {
      canUploadFiles: true,
      contextId: state.contextId,
      contextType: state.contextType,
      host: state.host,
      jwt: state.jwt,
      source: state.jwt && state.sourceType === 'real' ? undefined : fakeSource
    }
  }
}

function renderDemos(state) {
  const {host, jwt, contextType, contextId, sourceType} = state

  renderIntoDiv(document.getElementById('editor1'), getProps('textarea1', state))

  renderIntoDiv(document.getElementById('editor2'), getProps('textarea2', state))

  ReactDOM.render(
    <CanvasRce rceProps={getProps('textarea3', state)} />,
    document.getElementById('editor3')
  )

  const parsedUrl = new URL(window.location.href)
  if (parsedUrl.searchParams.get('sidebar') === 'no') {
    return
  }

  const sidebarEl = document.getElementById('sidebar')
  ReactDOM.render(<div />, sidebarEl)
  renderSidebarIntoDiv(sidebarEl, {
    source: jwt && sourceType === 'real' ? undefined : fakeSource,
    host,
    jwt,
    contextType,
    contextId,
    canUploadFiles: true
  })
}

function getSetting(settingKey, defaultValue) {
  return localStorage.getItem(settingKey) || defaultValue
}

function saveSettings(state) {
  ;['dir', 'sourceType', 'lang', 'host', 'jwt', 'contextType', 'contextId'].forEach(settingKey => {
    localStorage.setItem(settingKey, state[settingKey])
  })
}

class DemoOptions extends Component {
  state = {
    dir: getSetting('dir', 'ltr'),
    sourceType: getSetting('sourceType', 'fake'),
    lang: getSetting('lang', 'en'),
    host: getSetting('host', 'https://rich-content-iad.inscloudgate.net'),
    jwt: getSetting('jwt', ''),
    contextType: getSetting('contextType', 'course'),
    contextId: getSetting('contextId', '1')
  }

  handleChange = () => {
    document.documentElement.setAttribute('dir', this.state.dir)
    saveSettings(this.state)
    renderDemos(this.state)
  }

  componentDidMount() {
    this.handleChange()
  }

  render() {
    return (
      <ToggleDetails expanded summary="Configuration Options">
        <form
          onSubmit={e => {
            e.preventDefault()
            this.handleChange()
          }}
        >
          <RadioInputGroup
            description="Source Type"
            variant="toggle"
            name="source"
            onChange={(event, value) => this.setState({sourceType: value})}
            value={this.state.sourceType}
          >
            <RadioInput label="Fake" value="fake" />

            <RadioInput label="Real" value="real" />
          </RadioInputGroup>

          <RadioInputGroup
            description="Text Direction"
            variant="toggle"
            name="dir"
            value={this.state.dir}
            onChange={(event, value) => this.setState({dir: value})}
          >
            <RadioInput label="LTR" value="ltr" />
            <RadioInput label="RTL" value="rtl" />
          </RadioInputGroup>

          <Select
            label="Language"
            value={this.state.lang}
            onChange={(_e, option) => this.setState({lang: option.value})}
          >
            {['en', ...Object.keys(locales)].map(locale => (
              <option key={locale} value={locale}>
                {locale}
              </option>
            ))}
          </Select>

          <TextInput
            renderLabel="API Host"
            value={this.state.host}
            onChange={e => this.setState({host: e.target.value})}
          />

          <TextInput
            renderLabel="Canvas JWT"
            value={this.state.jwt}
            onChange={e => this.setState({jwt: e.target.value})}
          />

          <Select
            label="Context Type"
            selectedOption={this.state.contextType}
            onChange={(_e, option) => this.setState({contextType: option.value})}
          >
            <option value="course">Course</option>
            <option value="group">Group</option>
            <option value="user">User</option>
          </Select>

          <TextInput
            renderLabel="Context ID"
            value={this.state.contextId}
            onChange={e => this.setState({contextId: e.target.value})}
          />

          <Button type="submit">Update</Button>
        </form>
      </ToggleDetails>
    )
  }
}

ReactDOM.render(<DemoOptions />, document.getElementById('options'))
