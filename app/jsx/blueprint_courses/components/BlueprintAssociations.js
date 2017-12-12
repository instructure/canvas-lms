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
import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from '../../shared/select'
import 'compiled/jquery.rails_flash_notifications'

import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Alert from '@instructure/ui-core/lib/components/Alert'
import PresentationContent from '@instructure/ui-core/lib/components/PresentationContent'

import CoursePicker from './CoursePicker'
import AssociationsTable from './AssociationsTable'

import actions from '../actions'
import propTypes from '../propTypes'
import FocusManager from '../focusManager'

const { string, arrayOf, func, bool } = PropTypes

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
    removedAssociations: propTypes.courseList.isRequired,

    hasLoadedCourses: bool.isRequired,
    isLoadingCourses: bool.isRequired,
    isLoadingAssociations: bool.isRequired,
    isSavingAssociations: bool.isRequired,
    hasUnsyncedChanges: bool.isRequired,

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

  focusManager = new FocusManager()

  maybeRenderSyncWarning () {
    const { hasUnsyncedChanges, existingAssociations, addedAssociations } = this.props
    if (hasUnsyncedChanges && existingAssociations.length > 0 && addedAssociations.length > 0) {
      return (
        <Alert variant="warning" closeButtonLabel={I18n.t('Close')} margin="0 0 large">
          <p style={{margin: '0 -10px'}}>
            <Text weight="bold">{I18n.t('Warning:')}</Text>&nbsp;
            <Text>{I18n.t('You have unsynced changes that will sync to all associated courses when a new association is saved.')}</Text>
          </p>
        </Alert>
      )
    }

    return null
  }

  renderLoadingOverlay () {
    if (this.props.isSavingAssociations) {
      const title = I18n.t('Saving Associations')
      return (
        <div className="bca__overlay">
          <div className="bca__overlay__save-wrapper">
            <Spinner title={title} />
            <Text as="p">{title}</Text>
          </div>
        </div>
      )
    }

    return null
  }

  render () {
    return (
      <div className="bca__wrapper">
        {this.maybeRenderSyncWarning()}
        {this.renderLoadingOverlay()}
        <Heading level="h3">{I18n.t('Search Courses')}</Heading>
        <br />
        <div className="bca-course-associations">
          <CoursePicker
            ref={(c) => { this.coursePicker = c }}
            courses={this.props.courses}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            loadCourses={_.debounce(this.props.loadCourses, 200)}
            isLoadingCourses={this.props.isLoadingCourses}
            selectedCourses={this.props.addedAssociations.map(course => course.id)}
            onSelectedChanged={this.onSelectedChanged}
            isExpanded={this.props.isExpanded}
            detailsRef={this.focusManager.registerBeforeRef}
          />
          <PresentationContent><hr /></PresentationContent>
          <Heading level="h3">{I18n.t('Associated')}</Heading>
          <AssociationsTable
            existingAssociations={this.props.existingAssociations}
            addedAssociations={this.props.addedAssociations}
            removedAssociations={this.props.removedAssociations}
            onRemoveAssociations={this.props.removeAssociations}
            onRestoreAssociations={this.props.addAssociations}
            isLoadingAssociations={this.props.isLoadingAssociations}
            handleFocusLoss={this.catchAssociationsFocus}
            focusManager={this.focusManager}
          />
        </div>
      </div>
    )
  }
}

const connectState = state =>
  Object.assign(select(state, [
    'existingAssociations',
    'addedAssociations',
    'removedAssociations',
    'courses',
    'terms',
    'subAccounts',
    'hasLoadedCourses',
    'isLoadingCourses',
    'isLoadingAssociations',
    'isSavingAssociations',
  ]), {
    hasUnsyncedChanges: !state.hasLoadedUnsyncedChanges || state.unsyncedChanges.length > 0,
  })
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedBlueprintAssociations = connect(connectState, connectActions)(BlueprintAssociations)
