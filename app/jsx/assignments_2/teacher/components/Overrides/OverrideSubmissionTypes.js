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
import {bool, string} from 'prop-types'
import I18n from 'i18n!assignments_2'
import {OverrideShape} from '../../assignmentData'
import TeacherViewContext from '../TeacherViewContext'

// TODO: this is a placeholder until the real deal is built
export default class OverrideSubmissionTypes extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape,
    readOnly: bool,
    variant: string
  }

  static defaultProps = {
    readOnly: true,
    variant: 'simple'
  }

  static submissionTypesUnsorted = [
    {name: 'Arc', value: 'arc'},
    {name: I18n.t('No Submission'), value: 'none'},
    {name: I18n.t('External Tool'), value: 'external_tool'},
    {name: I18n.t('O365 Template'), value: 'o365'},
    {name: I18n.t('File'), value: 'online_upload'},
    {name: I18n.t('On Paper'), value: 'on_paper'},
    {name: I18n.t('Google Template'), value: 'google'},
    {name: I18n.t('Text Entry'), value: 'online_text_entry'},
    {name: I18n.t('Image'), value: 'image'},
    {name: I18n.t('Url'), value: 'online_url'},
    {name: I18n.t('Media'), value: 'media_recording'},
    {name: I18n.t('Student Choice'), value: 'any'}
  ]

  static unknownSubmissionType = {name: I18n.t('Other'), value: '*'}

  static submissionTypes = null

  componentWillMount() {
    if (OverrideSubmissionTypes.submissionTypes === null) {
      OverrideSubmissionTypes.submissionTypes = OverrideSubmissionTypes.submissionTypesUnsorted.sort(
        (a, b) => a.name.localeCompare(b.name, this.context.locale)
      )
    }
  }

  renderSimple() {
    if (this.props.override.submissionTypes) {
      return this.props.override.submissionTypes
        .map(typeSelection => {
          const type = OverrideSubmissionTypes.submissionTypes.find(t => typeSelection === t.value)
          return type ? type.name : OverrideSubmissionTypes.unknownSubmissionType.name
        })
        .join(' & ')
    }
    return null
  }

  render() {
    return this.props.variant === 'simple' ? this.renderSimple() : null
  }
}
