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
import I18n from 'i18n!assignments_2'
import {OverrideShape, requiredIfDetail} from '../../assignmentData'
import TeacherViewContext from '../TeacherViewContext'
import SubmitAny from './SubmissionTypes/SubmitAny'
import Button from '@instructure/ui-buttons/lib/components/Button'
import FormFieldGroup from '@instructure/ui-form-field/lib/components/FormFieldGroup'
import Menu, {MenuItem} from '@instructure/ui-menu/lib/components/Menu'
import Select from '@instructure/ui-forms/lib/components/Select'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import View from '@instructure/ui-layout/lib/components/View'

import IconAttachMedia from '@instructure/ui-icons/lib/Line/IconAttachMedia'
import IconDocument from '@instructure/ui-icons/lib/Line/IconDocument'
import IconEssay from '@instructure/ui-icons/lib/Line/IconEssay'
import IconImage from '@instructure/ui-icons/lib/Line/IconImage'
import IconLink from '@instructure/ui-icons/lib/Line/IconLink'
import IconMaterialsRequired from '@instructure/ui-icons/lib/Line/IconMaterialsRequired'
import IconPlus from '@instructure/ui-icons/lib/Line/IconPlus'
import IconQuestion from '@instructure/ui-icons/lib/Line/IconQuestion'
import IconUnpublished from '@instructure/ui-icons/lib/Line/IconUnpublished'
import IconWindows from '@instructure/ui-icons/lib/Line/IconWindows'
import IconPlaceholder from '@instructure/ui-icons/lib/Line/IconTrouble'

export default class OverrideSubmissionTypes extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape,
    onChangeOverride: requiredIfDetail,
    readOnly: bool,
    variant: oneOf(['summary', 'detail'])
  }

  static defaultProps = {
    readOnly: false,
    variant: 'summary'
  }

  static submissionTypesUnsorted = [
    {name: 'Arc', icon: IconPlaceholder, value: 'arc'},
    {name: I18n.t('No Submission'), icon: IconUnpublished, value: 'none'},
    {name: I18n.t('External Tool'), icon: IconMaterialsRequired, value: 'external_tool'},
    {name: I18n.t('O365 Template'), icon: IconWindows, value: 'o365'},
    {name: I18n.t('File'), icon: IconDocument, value: 'online_upload'},
    {name: I18n.t('On Paper'), icon: IconEssay, value: 'on_paper'},
    {name: I18n.t('Google Template'), icon: IconPlaceholder, value: 'google'},
    {name: I18n.t('Text Entry'), icon: IconDocument, value: 'online_text_entry'},
    {name: I18n.t('Image'), icon: IconImage, value: 'image'},
    {name: I18n.t('Url'), icon: IconLink, value: 'online_url'},
    {name: I18n.t('Media'), icon: IconAttachMedia, value: 'media_recording'},
    {name: I18n.t('Student Choice'), icon: IconDocument, value: 'any'}
  ]

  static unknownSubmissionType = {name: I18n.t('Other'), icon: IconQuestion, value: '*'}

  static submissionTypes = null

  constructor(props) {
    super(props)

    this.state = {
      currentSubmissionRequirement: 'any'
    }
  }

  sortTypeByName = (a, b) => {
    if (!a) return -1
    if (!b) return 1
    return a.name.localeCompare(b.name, this.context.locale)
  }

  componentWillMount() {
    // sort the list of possible submission types
    if (OverrideSubmissionTypes.submissionTypes === null) {
      OverrideSubmissionTypes.submissionTypes = OverrideSubmissionTypes.submissionTypesUnsorted.sort(
        this.sortTypeByName
      )
    }
  }

  onSelectSubmissionType = (_event, value) => {
    const currentSubmissionTypes = [...this.props.override.submissionTypes]
    currentSubmissionTypes.push(value)
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

  // TODO: this is wrong. it doesn't manage focus like we want
  // fix it when we actually support editing
  onDismissSubmissionTypesMenu = () => {
    if (this._submitComponent) {
      this._submitComponent.focus()
    }
  }

  onSelectSubmissionRequirement = (_event, selection) => {
    this.setState({
      currentSubmissionRequirement: selection.value
    })
  }

  getSortedCurrentTypes() {
    return this.props.override.submissionTypes
      .map(typeSelection =>
        OverrideSubmissionTypes.submissionTypes.find(t => typeSelection === t.value)
      )
      .sort(this.sortTypeByName)
  }

  getOverrideSubmissionTypeItems() {
    const currentSubmissionTypes = this.props.override.submissionTypes

    return OverrideSubmissionTypes.submissionTypes.map(t => {
      const Icon = t.icon
      const alreadySelected =
        currentSubmissionTypes.findIndex(currentType => t.value === currentType) >= 0
      return (
        <MenuItem key={t.value} value={t.value} disabled={alreadySelected}>
          <div>
            <Icon />
            <View margin="0 0 0 x-small">{t.name}</View>
          </div>
        </MenuItem>
      )
    })
  }

  renderSummary() {
    return (
      <span data-testid="OverrideSubmissionTypes">
        {this.getSortedCurrentTypes()
          .map(type => (type ? type.name : OverrideSubmissionTypes.unknownSubmissionType.name))
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
          <Button
            variant="light"
            icon={IconPlus}
            margin="0 0 x-small 0"
            data-testid="AddTypeButton"
          >
            <ScreenReaderContent>{I18n.t('Add submission type')}</ScreenReaderContent>
          </Button>
        }
      >
        {this.getOverrideSubmissionTypeItems()}
      </Menu>
    )
  }

  renderCurrentSubmissionTypes() {
    return this.getSortedCurrentTypes().map(type => {
      if (!type) {
        type = OverrideSubmissionTypes.unknownSubmissionType
      }
      const Icon = type.icon
      let typename = type.name
      if (
        type.value === 'online_upload' &&
        this.props.override.allowedExtensions &&
        this.props.override.allowedExtensions.length > 0
      ) {
        typename = this.props.override.allowedExtensions.join(', ')
      }
      return (
        <View key={type.value} as="span" display="inline-block" margin="0 x-small x-small 0">
          <SubmitAny
            icon={<Icon />}
            name={typename}
            value={type.value}
            onDelete={this.onDeleteSubmissionType}
            ref={comp => (this._submitComponent = comp)}
            readOnly={this.props.readOnly}
          />
        </View>
      )
    })
  }

  // TODO: what are the real values?
  renderSubmissionRequirement() {
    return (
      <Select
        label={I18n.t('Submission Requirement')}
        selectedOption={this.state.currentSubmissionRequirement}
        allowEmpty={false}
        onChange={this.onSelectSubmissionRequirement}
      >
        <option value="one">{I18n.t('Student can choose only one submission type')}</option>
        <option value="any">
          {I18n.t('Student can choose any combination of submission types')}
        </option>
        <option value="all">{I18n.t('Student is required to do all submission types')}</option>
      </Select>
    )
  }

  renderDetail() {
    const currentSubmissionTypes = this.props.override.submissionTypes
    return (
      <View as="div" margin="0 0 small 0" data-testid="OverrideSubmissionTypes">
        <FormFieldGroup description={I18n.t('Submission Type')} layout="columns">
          <div>
            {this.renderCurrentSubmissionTypes()}
            {this.renderAddSubmissionTypeButton()}
          </div>
        </FormFieldGroup>
        {currentSubmissionTypes.length > 1 ? this.renderSubmissionRequirement() : null}
      </View>
    )
  }

  render() {
    return this.props.variant === 'summary' ? this.renderSummary() : this.renderDetail()
  }
}
