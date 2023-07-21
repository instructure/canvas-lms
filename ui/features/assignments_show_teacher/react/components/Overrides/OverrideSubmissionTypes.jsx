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
import {bool, oneOf} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {OverrideShape, requiredIfDetail} from '../../assignmentData'
import TeacherViewContext from '../TeacherViewContext'
import ExternalToolType from './ExternalToolType'
import FileType from './FileType'
import NonCanvasType from './NonCanvasType'
import OperatorType from './OperatorType'
import SimpleType from './SimpleType'
import {Pill} from '@instructure/ui-pill'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import AddHorizontalRuleButton from '../AddHorizontalRuleButton'

import {
  IconAttachMediaLine,
  IconDocumentLine,
  IconIntegrationsLine,
  IconImageLine,
  IconLinkLine,
  IconUnpublishedLine,
} from '@instructure/ui-icons'

const I18n = useI18nScope('assignments_2')

export default class OverrideSubmissionTypes extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape,
    onChangeOverride: requiredIfDetail,
    readOnly: bool,
    variant: oneOf(['summary', 'detail']),
  }

  static defaultProps = {
    readOnly: false,
    variant: 'summary',
  }

  static docTypeOptions = [
    {key: 'all', display: I18n.t('All Types Allowed')},
    {key: 'doc', display: I18n.t('DOC')},
    {key: 'csv', display: I18n.t('CSV')},
    {key: 'pdf', display: I18n.t('PDF')},
    {key: 'ppt', display: I18n.t('PPT')},
    {key: 'txt', display: I18n.t('TXT')},
    {key: 'xls', display: I18n.t('XLS')},
    {key: 'rtf', display: I18n.t('RTF')},
  ]

  static imageTypeOptions = [
    {key: 'all', display: I18n.t('All Image Types Allowed')},
    {key: 'jpg', display: I18n.t('JPG')},
    {key: 'png', display: I18n.t('PNG')},
    {key: 'tiff', display: I18n.t('TIFF')},
    {key: 'bmp', display: I18n.t('BMP')},
    {key: 'gif', display: I18n.t('GIF')},
    {key: 'psd', display: I18n.t('PSD')},
    {key: 'svg', display: I18n.t('SVG')},
    {key: 'eps', display: I18n.t('EPS')},
  ]

  static mediaTypeOptions = [
    {key: 'all', display: I18n.t('All Media Types Allowed')},
    {key: 'avi', display: I18n.t('AVI')},
    {key: 'flv', display: I18n.t('FLV')},
    {key: 'wmv', display: I18n.t('WMV')},
    {key: 'mp4', display: I18n.t('MP4')},
    {key: 'mp3', display: I18n.t('MP3')},
    {key: 'mov', display: I18n.t('MOV')},
    {key: 'arc', display: I18n.t('ARC')},
  ]

  static nonCanvasOptions = [
    {key: 'in_class', display: I18n.t('In Class')},
    {key: 'on_paper', display: I18n.t('On Paper')},
    {key: 'none', display: I18n.t('No Submission')},
  ]

  static appType = {
    name: I18n.t('App'),
    icon: IconIntegrationsLine,
    value: 'external_tool',
    slotType: ExternalToolType,
  }

  static fileType = {
    name: I18n.t('File'),
    icon: IconDocumentLine,
    value: 'online_upload',
    options: OverrideSubmissionTypes.docTypeOptions,
    slotType: FileType,
  }

  static imageType = {
    name: I18n.t('Image'),
    icon: IconImageLine,
    value: 'image',
    options: OverrideSubmissionTypes.imageTypeOptions,
    slotType: FileType,
  }

  static mediaType = {
    name: I18n.t('Media'),
    icon: IconAttachMediaLine,
    value: 'media_recording',
    options: OverrideSubmissionTypes.mediaTypeOptions,
    slotType: FileType,
  }

  static nonCanvasType = {
    name: I18n.t('Non Canvas'),
    icon: IconUnpublishedLine,
    value: 'non_canvas',
    options: OverrideSubmissionTypes.nonCanvasOptions,
    slotType: NonCanvasType,
  }

  static textType = {
    name: I18n.t('Text Entry'),
    icon: IconDocumentLine,
    value: 'online_text_entry',
    slotType: SimpleType,
  }

  static urlType = {
    name: I18n.t('URL'),
    icon: IconLinkLine,
    value: 'online_url',
    slotType: SimpleType,
  }

  static submissionTypes = [
    OverrideSubmissionTypes.appType,
    OverrideSubmissionTypes.fileType,
    OverrideSubmissionTypes.imageType,
    OverrideSubmissionTypes.mediaType,
    OverrideSubmissionTypes.nonCanvasType,
    OverrideSubmissionTypes.textType,
    OverrideSubmissionTypes.urlType,
  ]

  onSelectSubmissionType = (_event, value) => {
    const currentSubmissionTypes = [...this.props.override.submissionTypes]
    currentSubmissionTypes.push(value[0])
    this.props.onChangeOverride('submissionTypes', currentSubmissionTypes)
  }

  onDeleteSubmissionType = type => {
    const index = this.props.override.submissionTypes.findIndex(t => t === type)
    if (index >= 0) {
      const currentSubmissionTypes = [...this.props.override.submissionTypes]
      currentSubmissionTypes.splice(index, 1)
      this.props.onChangeOverride('submissionTypes', currentSubmissionTypes)
    }
  }

  getCurrentTypes() {
    return this.props.override.submissionTypes.map(typeSelection => {
      if (OverrideSubmissionTypes.nonCanvasType.options.find(opt => opt.key === typeSelection)) {
        return OverrideSubmissionTypes.nonCanvasType
      } else {
        return OverrideSubmissionTypes.submissionTypes.find(t => typeSelection === t.value)
      }
    })
  }

  getMenuItems() {
    return OverrideSubmissionTypes.submissionTypes.map(t => {
      const Icon = t.icon
      return (
        <Menu.Item key={t.value} value={t.value}>
          <div>
            <Icon />
            <View margin="0 0 0 x-small">{t.name}</View>
          </div>
        </Menu.Item>
      )
    })
  }

  renderSummary() {
    return (
      <span data-testid="OverrideSubmissionTypes">
        {this.props.override.submissionTypes
          .map(typeSelection => {
            const nonCanvasType = OverrideSubmissionTypes.nonCanvasType.options.find(
              opt => opt.key === typeSelection
            )
            if (nonCanvasType) {
              return nonCanvasType.display
            } else {
              return OverrideSubmissionTypes.submissionTypes.find(t => typeSelection === t.value)
                .name
            }
          })
          .join(' & ')}
      </span>
    )
  }

  renderAddSubmissionTypeButton() {
    if (this.props.readOnly) return null
    return (
      <Menu
        onSelect={this.onSelectSubmissionType}
        trigger={
          <AddHorizontalRuleButton label={I18n.t('Add submission type')} onClick={() => {}} />
        }
      >
        <Menu.Group label={I18n.t('Submission Type')} onSelect={this.onSelectSubmissionType}>
          {this.getMenuItems()}
        </Menu.Group>
        <Menu.Separator />
        <Menu.Group label={I18n.t('Default')} onSelect={() => {}} selected={['or']}>
          <Menu.Item key="or" value="or">
            <div>{I18n.t('Or')}</div>
          </Menu.Item>
          <Menu.Item key="and" value="and" disabled={true}>
            <div>
              {I18n.t('And')}
              <View margin="0 0 0 small">
                <Pill color="info">{I18n.t('COMING SOON')}</Pill>
              </View>
            </div>
          </Menu.Item>
        </Menu.Group>
      </Menu>
    )
  }

  renderCurrentSubmissionTypes() {
    const slots = []

    for (const [index, value] of this.getCurrentTypes().entries()) {
      const type = value

      if (index > 0) {
        slots.push(<OperatorType key={`or_${index}`} value="or" />)
      }

      let selectedOptions = []
      if (
        type.value === 'online_upload' ||
        type.value === 'media_recording' ||
        type.value === 'image'
      ) {
        if (
          this.props.override.allowedExtensions &&
          this.props.override.allowedExtensions.length > 0
        ) {
          selectedOptions = this.props.override.allowedExtensions
        } else {
          selectedOptions = ['all']
        }
      } else if (type === OverrideSubmissionTypes.nonCanvasType) {
        selectedOptions = OverrideSubmissionTypes.nonCanvasType.options.find(
          opt => opt.key === this.props.override.submissionTypes[0]
        )
        selectedOptions = selectedOptions ? selectedOptions.key : null
      }

      slots.push(
        <View key={type.value} as="div" margin="0 x-small x-small 0">
          <Heading level="h4">{I18n.t('Item %{count}', {count: index + 1})}</Heading>
          <type.slotType
            icon={<type.icon />}
            name={type.name}
            value={type.value}
            onDelete={this.onDeleteSubmissionType}
            ref={comp => (this._submitComponent = comp)}
            readOnly={this.props.readOnly}
            options={type.options}
            initialSelection={selectedOptions}
          />
        </View>
      )
    }
    return slots
  }

  renderDetail() {
    return (
      <View as="div" margin="0 0 small 0" data-testid="OverrideSubmissionTypes">
        <FormFieldGroup description={I18n.t('Submission Items')} layout="columns">
          <div>{this.renderCurrentSubmissionTypes()}</div>
        </FormFieldGroup>
        {this.renderAddSubmissionTypeButton()}
      </View>
    )
  }

  render() {
    return this.props.variant === 'summary' ? this.renderSummary() : this.renderDetail()
  }
}
