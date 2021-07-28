/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {getLocaleList} from '../src/getTranslations'

const locales = getLocaleList()

export default class DemoOptions extends Component {
  constructor(props) {
    super(props)

    this.state = {...props}
  }

  handleChange = () => {
    this.props.onChange(this.state)
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
            <View as="div" margin="0 0 small">
              <Checkbox
                label="Readonly"
                checked={this.state.readonly}
                onChange={event => {
                  this.setState({readonly: event.target.checked})
                }}
              />
            </View>
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
            <View as="div" margin="medium 0 0 0" padding="small" borderWidth="small">
              <FormFieldGroup
                description="External plugins"
                messages={[{text: 'Pick the toolbar and menu to place the plugin', type: 'hint'}]}
              >
                <Checkbox
                  label="Include test plugin"
                  checked={this.state.include_test_plugin}
                  onChange={e => this.setState({include_test_plugin: e.target.checked})}
                />
                <SimpleSelect
                  renderLabel="Toolbar"
                  value={this.state.test_plugin_toolbar || '__none__'}
                  onChange={(_e, option) => this.setState({test_plugin_toolbar: option.value})}
                  interaction={this.state.include_test_plugin ? 'enabled' : 'disabled'}
                >
                  <SimpleSelect.Option id="Formatting" value="Formatting">
                    Formatting
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="Content" value="Content">
                    Content
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="Miscellaneous" value="Miscellaneous">
                    Miscellaneous
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="Ext_Plugin" value="Ext Plugin">
                    External Plugin (new!)
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="none" value="__none__">
                    None
                  </SimpleSelect.Option>
                </SimpleSelect>
                <SimpleSelect
                  renderLabel="Menu"
                  value={this.state.test_plugin_menu}
                  onChange={(_e, option) => this.setState({test_plugin_menu: option.value})}
                  interaction={this.state.include_test_plugin ? 'enabled' : 'disabled'}
                >
                  <SimpleSelect.Option id="Content" value="insert">
                    Insert
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="Miscellaneous" value="tools">
                    Tools
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="ext_plugin" value="ext_plugin">
                    External Plugin (new!)
                  </SimpleSelect.Option>
                  <SimpleSelect.Option id="none" value="__none__">
                    None
                  </SimpleSelect.Option>
                </SimpleSelect>
              </FormFieldGroup>
            </View>
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
