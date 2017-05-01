/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_settings'
import $ from 'jquery'
import React from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from 'jsx/shared/select'
import 'compiled/jquery.rails_flash_notifications'

import Heading from 'instructure-ui/lib/components/Heading'
import Typography from 'instructure-ui/lib/components/Typography'
import Spinner from 'instructure-ui/lib/components/Spinner'

import actions from '../actions'
import propTypes from '../propTypes'
import CoursePicker from './CoursePicker'
import AssociationsTable from './AssociationsTable'

const { string, arrayOf, func, bool } = React.PropTypes

export default class BlueprintAssociations extends React.Component {
  static propTypes = {
    loadCourses: func.isRequired,
    addAssociations: func.isRequired,
    removeAssociations: func.isRequired,

    terms: propTypes.termList.isRequired,
    subAccounts: propTypes.accountList.isRequired,
    courses: propTypes.courseList.isRequired,
    existingAssociations: propTypes.courseList.isRequired,
    addedAssociations: propTypes.courseList.isRequired,
    removedAssociations: arrayOf(string).isRequired,

    hasLoadedCourses: bool.isRequired,
    isLoadingCourses: bool.isRequired,
    isLoadingAssociations: bool.isRequired,
    isSavingAssociations: bool.isRequired,

    isExpanded: bool,
  }

  static defaultProps = {
    isExpanded: false,
  }

  componentDidMount () {
    if (!this.props.hasLoadedCourses) {
      this.props.loadCourses()
    }
  }

  componentWillReceiveProps (nextProps) {
    if (!this.props.isSavingAssociations && nextProps.isSavingAssociations) {
      $.screenReaderFlashMessage(I18n.t('Saving associations started'))
    }

    if (this.props.isSavingAssociations && !nextProps.isSavingAssociations) {
      $.screenReaderFlashMessageExclusive(I18n.t('Saving associations complete'))

      // when saving is done, reload courses in course picker
      // this will remove courses we just associated from the picker
      this.coursePicker.reloadCourses()
    }
  }

  onSelectedChanged = ({ added, removed }) => {
    if (added.length) this.props.addAssociations(added)
    if (removed.length) this.props.removeAssociations(removed)
  }

  renderLoadingOverlay () {
    if (this.props.isSavingAssociations) {
      const title = I18n.t('Saving Associations')
      return (
        <div className="bca__overlay">
          <div className="bca__overlay__save-wrapper">
            <Spinner title={title} />
            <Typography as="p">{title}</Typography>
          </div>
        </div>
      )
    }

    return null
  }

  render () {
    return (
      <div className="bca__wrapper">
        {this.renderLoadingOverlay()}
        <Heading level="h3">{I18n.t('Search Courses')}</Heading>
        <br />
        <div className="bca-course-associations">
          <CoursePicker
            ref={(c) => { this.coursePicker = c }}
            courses={this.props.courses}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            loadCourses={this.props.loadCourses}
            isLoadingCourses={this.props.isLoadingCourses}
            selectedCourses={this.props.addedAssociations.map(course => course.id)}
            onSelectedChanged={this.onSelectedChanged}
            isExpanded={this.props.isExpanded}
          />
          <hr />
          <Heading level="h3">{I18n.t('Associated')}</Heading>
          <AssociationsTable
            existingAssociations={this.props.existingAssociations}
            addedAssociations={this.props.addedAssociations}
            removedAssociations={this.props.removedAssociations}
            onRemoveAssociations={this.props.removeAssociations}
            isLoadingAssociations={this.props.isLoadingAssociations}
          />
        </div>
      </div>
    )
  }
}

const connectState = state =>
  select(state, [
    'existingAssociations',
    'addedAssociations',
    'removedAssociations',
    'courses',
    'terms',
    'subAccounts',
    'errors',
    'hasLoadedCourses',
    'isLoadingCourses',
    'isLoadingAssociations',
    'isSavingAssociations',
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedBlueprintAssociations = connect(connectState, connectActions)(BlueprintAssociations)
