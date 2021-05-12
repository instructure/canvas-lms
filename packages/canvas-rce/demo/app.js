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
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import CanvasRce from '../src/rce/CanvasRce'
import '@instructure/canvas-theme'

import {getLocaleList} from '../src/getTranslations'
import * as fakeSource from '../src/sidebar/sources/fake'

const locales = getLocaleList()

function renderDemos(state) {
  const {
    canvas_exists,
    canvas_origin,
    dir,
    host,
    jwt,
    contextType,
    contextId,
    userId,
    sourceType,
    lang
  } = state
  let trayProps

  if (canvas_exists) {
    trayProps = {
      canUploadFiles: true,
      contextId,
      contextType,
      containingContext: {
        contextType,
        contextId,
        userId
      },
      filesTabDisabled: false,
      host,
      jwt,
      refreshToken:
        sourceType === 'real'
          ? refreshCanvasToken.bind(null, canvas_origin)
          : () => {
              Promise.resolve({jwt})
            },
      source: jwt && sourceType === 'real' ? undefined : fakeSource,
      themeUrl: ''
    }
  }

  document.documentElement.setAttribute('dir', dir)
  document.documentElement.setAttribute('lang', lang)

  ReactDOM.render(
    <CanvasRce
      language={lang}
      textareaId="textarea3"
      defaultContent="hello RCE"
      height={350}
      highContrastCSS={[]}
      trayProps={trayProps}
    />,
    document.getElementById('content')
  )
}

function getSetting(settingKey, defaultValue) {
  let val = localStorage.getItem(settingKey) || defaultValue
  if (typeof defaultValue === 'boolean') {
    val = val === 'true'
  }
  return val
}

function saveSetting(settingKey, settingValue) {
  localStorage.setItem(settingKey, settingValue)
}

function saveSettings(state) {
  ;[
    'canvas_exists',
    'dir',
    'sourceType',
    'lang',
    'host',
    'jwt',
    'contextType',
    'contextId',
    'userId'
  ].forEach(settingKey => {
    saveSetting(settingKey, state[settingKey])
  })
}

// adapted from canvas-lms/ui/shared/rce/jwt.js
function refreshCanvasToken(canvas_origin, initialToken) {
  let token = initialToken
  let promise = null

  return done => {
    if (promise === null) {
      promise = fetch(`${canvas_origin}/api/v1/jwts/refresh`, {
        method: 'POST',
        mode: 'cors',
        body: JSON.stringify({jwt: token})
      }).then(resp => {
        promise = null
        token = resp.data.token
        return token
      })
    }

    if (typeof done === 'function') {
      promise.then(done)
    }

    return promise
  }
}

class DemoOptions extends Component {
  state = {
    canvas_origin: getSetting('canvas_origin', 'http://localhost:3000'),
    canvas_exists: getSetting('canvas_exists', false),
    dir: getSetting('dir', 'ltr'),
    sourceType: getSetting('sourceType', 'fake'),
    lang: getSetting('lang', 'en'),
    host: getSetting('host', 'http:/who.cares'), // 'https://rich-content-iad.inscloudgate.net'
    jwt: getSetting('jwt', 'doesnotmatteriffake'),
    contextType: getSetting('contextType', 'course'),
    contextId: getSetting('contextId', '1'),
    userId: getSetting('userId', '1')
  }

  handleChange = () => {
    const canvas_exists = getSetting('canvas_exists', false)
    const lang = getSetting('lang', null)
    const refresh = canvas_exists !== this.state.canvas_exists || lang !== this.state.lang
    document.documentElement.setAttribute('dir', this.state.dir)
    saveSettings(this.state)
    if (refresh) {
      window.location.reload()
    } else {
      renderDemos(this.state)
    }
  }

  componentDidMount() {
    this.handleChange()
  }

  render() {
    return (
      <form
        onSubmit={e => {
          e.preventDefault()
          this.handleChange()
        }}
      >
        <FormFieldGroup layout="stacked" description="Configuration Options">
          <View as="div" padding="x-small" margin="0 0 small">
            <RadioInputGroup
              description="Text Direction"
              variant="simple"
              layout="columns"
              name="dir"
              value={this.state.dir}
              onChange={(event, value) => this.setState({dir: value})}
            >
              <RadioInput label="LTR" value="ltr" />
              <RadioInput label="RTL" value="rtl" />
            </RadioInputGroup>

            <SimpleSelect
              renderLabel="Language"
              value={this.state.lang}
              onChange={(_e, option) => this.setState({lang: option.value})}
            >
              {[...locales, 'bad-locale-default-en'].map(locale => (
                <SimpleSelect.Option id={locale} key={locale} value={locale}>
                  {locale}
                </SimpleSelect.Option>
              ))}
            </SimpleSelect>

            <View as="div" margin="medium 0 0 0">
              <RadioInputGroup
                description="Canvas"
                variant="simple"
                layout="columns"
                name="canvas_exists"
                onChange={(_event, value) => {
                  this.setState(_state => {
                    const newState = {
                      canvas_exists: value === 'yes'
                    }
                    if (value === 'yes') {
                      newState.expandRCS = true
                    }
                    return newState
                  })
                }}
                value={this.state.canvas_exists ? 'yes' : 'no'}
              >
                <RadioInput label="Exists" value="yes" />
                <RadioInput label="Does not" value="no" />
              </RadioInputGroup>
            </View>
          </View>

          {/* Talking to real canvas doesn't work for now, so don't even show the UI */}
          {this.state.canvas_exists && this.state.sourceType === 'real' && (
            <ToggleDetails
              expanded={this.state.expandRCS}
              variant="filled"
              summary="RCS"
              onToggle={(_event, expanded) => this.setState({expandRCS: expanded})}
            >
              <View as="div" margin="small 0 0 0">
                <RadioInputGroup
                  description="Source Type"
                  variant="simple"
                  layout="columns"
                  name="source"
                  onChange={(event, value) => {
                    this.setState(state => {
                      return {
                        sourceType: value,
                        jwt: state.jwt || 'doesnotmatter',
                        host: state.host || 'does.not.matter'
                      }
                    })
                  }}
                  value={this.state.sourceType}
                  disabled={!this.state.canvas_exists}
                >
                  <RadioInput label="Fake" value="fake" />

                  <RadioInput label="Real" value="real" />
                </RadioInputGroup>

                <TextInput
                  renderLabel="API Host"
                  value={this.state.host}
                  onChange={e => this.setState({host: e.target.value})}
                  interaction={this.state.canvas_exists ? 'enabled' : 'disabled'}
                />

                <TextInput
                  renderLabel="Canvas JWT"
                  value={this.state.jwt}
                  onChange={e => this.setState({jwt: e.target.value})}
                  interaction={this.state.canvas_exists ? 'enabled' : 'disabled'}
                />

                <SimpleSelect
                  renderLabel="Context Type"
                  value={this.state.contextType}
                  onChange={(_e, option) => this.setState({contextType: option.value})}
                  interaction={this.state.canvas_exists ? 'enabled' : 'disabled'}
                >
                  <SimpleSelect.Option id="course" value="course">
                    Course
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="group" value="group">
                    Group
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="user" value="user">
                    User
                  </SimpleSelect.Option>
                </SimpleSelect>

                <TextInput
                  renderLabel="Context ID"
                  value={this.state.contextId}
                  onChange={e => this.setState({contextId: e.target.value})}
                  interaction={this.state.canvas_exists ? 'enabled' : 'disabled'}
                />

                <TextInput
                  renderLabel="User ID"
                  value={this.state.userId}
                  onChange={e => this.setState({userId: e.target.value})}
                  interaction={this.state.canvas_exists ? 'enabled' : 'disabled'}
                />
              </View>
            </ToggleDetails>
          )}

          <Button type="submit">Update</Button>
        </FormFieldGroup>
      </form>
    )
  }
}

ReactDOM.render(<DemoOptions />, document.getElementById('options'))
