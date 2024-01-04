/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import classnames from 'classnames'
import {isEmpty, isObject} from 'lodash'
import CourseEpubExportStore from './CourseStore'

const I18n = useI18nScope('epub_exports')

class GenerateLink extends React.Component {
  static displayName = 'GenerateLink'

  static propTypes = {
    course: PropTypes.object.isRequired,
  }

  //
  // Preparation
  //

  state = {
    triggered: false,
  }

  epubExport = () => this.props.course.epub_export || {}

  showGenerateLink = () =>
    isEmpty(this.epubExport()) ||
    (isObject(this.epubExport().permissions) && this.epubExport().permissions.regenerate)

  //
  // Rendering
  //

  render() {
    const text = {}

    if (!this.showGenerateLink() && !this.state.triggered) return null

    text[I18n.t('Regenerate ePub')] =
      isObject(this.props.course.epub_export) && !this.state.triggered
    text[I18n.t('Generate ePub')] =
      !isObject(this.props.course.epub_export) && !this.state.triggered
    text[I18n.t('Generating...')] = this.state.triggered

    if (this.state.triggered) {
      return (
        <span>
          <i className="icon-refresh" aria-hidden="true" />
          {classnames(text)}
        </span>
      )
    } else {
      return (
        <button type="button" className="Button Button--link" onClick={this._onClick}>
          <i className="icon-refresh" aria-hidden="true" />
          {classnames(text)}
        </button>
      )
    }
  }

  //
  // Event handling
  //

  _onClick = e => {
    e.preventDefault()
    this.setState({
      triggered: true,
    })
    setTimeout(() => {
      this.setState({
        triggered: false,
      })
    }, 800)
    CourseEpubExportStore.create(this.props.course.id)
  }
}

export default GenerateLink
