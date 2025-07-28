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
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {createRef} from 'react'
import omit from 'lodash/omit'
import omitBy from 'lodash/omitBy'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'

const I18n = createI18nScope('react_developer_keys')

const validationMessage = [
  {text: I18n.t('Please enter a valid URL (e.g. https://example.com)'), type: 'error' as const},
]

interface AdditionalSettingsShape {
  domain?: string
  tool_id?: string
  icon_url?: string
  text?: string
  selection_height?: number | ''
  selection_width?: number | ''
  privacy_level?: string
  settings?: {
    icon_url?: string
    text?: string
    selection_height?: number
    selection_width?: number
  }
}

interface AdditionalSettingsProps {
  additionalSettings?: AdditionalSettingsShape
  custom_fields?: Record<string, string>
  showMessages?: boolean
}

interface AdditionalSettingsState {
  isIconUrlValid: boolean
  additionalSettings: AdditionalSettingsShape
  custom_fields: string
}

export default class AdditionalSettings extends React.Component<
  AdditionalSettingsProps,
  AdditionalSettingsState
> {
  iconUrlRef = createRef<HTMLInputElement>()
  isValid = true

  constructor(props: AdditionalSettingsProps) {
    super(props)
    const {additionalSettings = {}, custom_fields = {}} = props
    this.state = {
      isIconUrlValid: true,
      additionalSettings: {
        ...omit(additionalSettings, ['settings']),
        ...additionalSettings.settings,
      },
      custom_fields: this.customFieldsToString(custom_fields),
    }
    if (!this.state.additionalSettings.domain) {
      this.state.additionalSettings.domain = ''
    }
    if (!this.state.additionalSettings.tool_id) {
      this.state.additionalSettings.tool_id = ''
    }
  }

  customFieldsToString = (customFields: Record<string, string>) =>
    Object.keys(customFields)
      .map(k => `${k}=${customFields[k]}`)
      .join('\n')

  customFieldsToObject = (customFields: string) =>
    customFields.split('\n').reduce<Record<string, string>>((obj, field) => {
      const [key, value] = field.split('=')
      if (key && value) {
        obj[key] = value
      }
      return obj
    }, {})

  generateToolConfigurationPart = () => {
    const {custom_fields, additionalSettings} = this.state
    return {
      extensions: [
        {
          platform: 'canvas.instructure.com',
          settings: {
            ...omitBy(omit(additionalSettings, ['domain', 'tool_id', 'privacy_level']), s => !s),
          },
          privacy_level: additionalSettings.privacy_level || 'anonymous',
          domain: additionalSettings.domain,
          tool_id: additionalSettings.tool_id,
        },
      ],
      custom_fields: this.customFieldsToObject(custom_fields),
    }
  }

  validateUrlField = (
    fieldValue: string | undefined,
    fieldStateKey: 'isIconUrlValid',
    fieldRef: React.RefObject<HTMLInputElement>,
  ) => {
    if (fieldValue && !URL.canParse(fieldValue)) {
      this.setState({[fieldStateKey]: false} as any)
      if (this.isValid) {
        fieldRef.current?.focus()
        this.isValid = false
      }
    } else {
      this.setState({[fieldStateKey]: true} as any)
    }
  }

  valid = () => {
    const {icon_url} = this.state.additionalSettings
    this.isValid = true

    this.validateUrlField(icon_url, 'isIconUrlValid', this.iconUrlRef)

    return this.isValid
  }

  handleDomainChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    this.setState(state => ({additionalSettings: {...state.additionalSettings, domain: value}}))
  }

  handleToolIdChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    this.setState(state => ({additionalSettings: {...state.additionalSettings, tool_id: value}}))
  }

  handleIconUrlChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    this.setState(state => ({additionalSettings: {...state.additionalSettings, icon_url: value}}))
    this.validateUrlField(value, 'isIconUrlValid', this.iconUrlRef)
  }

  handleTextChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    this.setState(state => ({additionalSettings: {...state.additionalSettings, text: value}}))
  }

  handleSelectionHeightChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    const numVal = Number.parseInt(value, 10)
    this.setState(state => ({
      additionalSettings: {
        ...state.additionalSettings,
        selection_height: !Number.isNaN(numVal) ? numVal : '',
      },
    }))
  }

  handlePrivacyLevelChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    this.setState(state => ({
      additionalSettings: {...state.additionalSettings, privacy_level: value},
    }))
  }

  handleSelectionWidthChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    const numVal = Number.parseInt(value, 10)
    this.setState(state => ({
      additionalSettings: {
        ...state.additionalSettings,
        selection_width: !Number.isNaN(numVal) ? numVal : '',
      },
    }))
  }

  handleCustomFieldsChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value
    this.setState({custom_fields: value})
  }

  render() {
    const {additionalSettings, custom_fields} = this.state
    const {showMessages} = this.props

    return (
      <View as="div" margin="medium 0">
        <ToggleDetails summary={I18n.t('Additional Settings')} fluidWidth={true}>
          <View as="div" margin="small">
            <FormFieldGroup
              description={
                <ScreenReaderContent>{I18n.t('Identification Values')}</ScreenReaderContent>
              }
              layout="columns"
            >
              <Grid>
                <Grid.Row>
                  <Grid.Col>
                    <TextInput
                      name="domain"
                      value={additionalSettings.domain}
                      renderLabel={I18n.t('Domain')}
                      onChange={this.handleDomainChange}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      name="tool_id"
                      value={additionalSettings.tool_id}
                      renderLabel={I18n.t('Tool Id')}
                      onChange={this.handleToolIdChange}
                    />
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col>
                    <TextInput
                      name="settings_icon_url"
                      value={additionalSettings.icon_url}
                      renderLabel={I18n.t('Icon Url')}
                      inputRef={(ref: HTMLInputElement | null) => {
                        if (ref && this.iconUrlRef.current !== ref) {
                          ;(this.iconUrlRef as any).current = ref
                        }
                      }}
                      onChange={this.handleIconUrlChange}
                      messages={showMessages && !this.state.isIconUrlValid ? validationMessage : []}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      name="text"
                      value={additionalSettings.text}
                      renderLabel={I18n.t('Text')}
                      onChange={this.handleTextChange}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      name="selection_height"
                      value={
                        additionalSettings.selection_height !== undefined
                          ? additionalSettings.selection_height.toString()
                          : ''
                      }
                      renderLabel={I18n.t('Selection Height')}
                      onChange={this.handleSelectionHeightChange}
                    />
                  </Grid.Col>
                  <Grid.Col>
                    <TextInput
                      name="selection_width"
                      value={
                        additionalSettings.selection_width !== undefined
                          ? additionalSettings.selection_width.toString()
                          : ''
                      }
                      renderLabel={I18n.t('Selection Width')}
                      onChange={this.handleSelectionWidthChange}
                    />
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col>
                    <TextArea
                      label={I18n.t('Custom Fields')}
                      maxHeight="10rem"
                      messages={[{text: I18n.t('One per line. Format: name=value'), type: 'hint'}]}
                      name="custom_fields"
                      value={custom_fields}
                      onChange={this.handleCustomFieldsChange}
                    />
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col>
                    <RadioInputGroup
                      name="privacy_level"
                      value={additionalSettings.privacy_level || 'anonymous'}
                      description={I18n.t('Privacy Level')}
                      variant="toggle"
                      onChange={this.handlePrivacyLevelChange}
                    >
                      <RadioInput label={I18n.t('Public')} value="public" />
                      <RadioInput label={I18n.t('Private')} value="anonymous" />
                    </RadioInputGroup>
                  </Grid.Col>
                </Grid.Row>
              </Grid>
            </FormFieldGroup>
          </View>
        </ToggleDetails>
      </View>
    )
  }
}
