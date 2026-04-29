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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {debounce} from 'es-toolkit/compat'
import React from 'react'
import {connect} from 'react-redux'
import type {Dispatch} from 'redux'
import {bindActionCreators} from 'redux'
import select from '@canvas/obj-select'
import '@canvas/rails-flash-notifications'

import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {PresentationContent} from '@instructure/ui-a11y-content'

import type CoursePicker from './CoursePicker'
import CoursePickerComponent from './CoursePicker'
import AssociationsTable from './AssociationsTable'

import actions from '@canvas/blueprint-courses/react/actions'
import FocusManager from '../focusManager'
import type {Term, Account, Course} from '../types'

const I18n = createI18nScope('BlueprintAssociations')

export interface BlueprintAssociationsProps {
  loadCourses: () => void
  addAssociations: (courses: string[]) => void
  removeAssociations: (courses: string[]) => void
  terms: Term[]
  subAccounts: Account[]
  courses: Course[]
  existingAssociations: Course[]
  addedAssociations: Course[]
  removedAssociations: Course[]
  hasLoadedCourses: boolean
  isLoadingCourses: boolean
  isLoadingAssociations: boolean
  isSavingAssociations: boolean
  hasUnsyncedChanges: boolean
  isExpanded?: boolean
}

interface SelectionChanges {
  added: string[]
  removed: string[]
}

export default class BlueprintAssociations extends React.Component<BlueprintAssociationsProps> {
  static defaultProps = {
    isExpanded: false,
  }

  coursePicker: CoursePicker | null = null
  focusManager = new FocusManager()

  componentDidMount(): void {
    if (!this.props.hasLoadedCourses) {
      this.props.loadCourses()
    }
  }

  UNSAFE_componentWillReceiveProps(nextProps: BlueprintAssociationsProps): void {
    if (!this.props.isSavingAssociations && nextProps.isSavingAssociations) {
      $.screenReaderFlashMessage(I18n.t('Saving associations started'))
    }

    if (this.props.isSavingAssociations && !nextProps.isSavingAssociations) {
      $.screenReaderFlashMessage(I18n.t('Saving associations complete'))

      // when saving is done, reload courses in course picker
      // this will remove courses we just associated from the picker
      this.coursePicker?.reloadCourses()
    }
  }

  onSelectedChanged = (selected: string[] | SelectionChanges): void => {
    const changes = Array.isArray(selected)
      ? ({added: selected, removed: []} as SelectionChanges)
      : selected
    const {added, removed} = changes
    if (added.length) this.props.addAssociations(added)
    if (removed.length) this.props.removeAssociations(removed)
  }

  maybeRenderSyncWarning(): React.JSX.Element | null {
    const {hasUnsyncedChanges, existingAssociations, addedAssociations} = this.props
    if (hasUnsyncedChanges && existingAssociations.length > 0 && addedAssociations.length > 0) {
      return (
        <Alert variant="warning" renderCloseButtonLabel={I18n.t('Close')} margin="0 0 large">
          <p style={{margin: '0 -10px'}}>
            <Text weight="bold">{I18n.t('Warning:')}</Text>&nbsp;
            <Text>
              {I18n.t(
                'You have unsynced changes that will sync to all associated courses when a new association is saved.',
              )}
            </Text>
          </p>
        </Alert>
      )
    }

    return null
  }

  renderLoadingOverlay(): React.JSX.Element | null {
    if (this.props.isSavingAssociations) {
      const title = I18n.t('Saving Associations')
      return (
        <div className="bca__overlay">
          <div className="bca__overlay__save-wrapper">
            <Spinner renderTitle={title} />
            <Text as="p">{title}</Text>
          </div>
        </div>
      )
    }

    return null
  }

  render(): React.JSX.Element {
    return (
      <div className="bca__wrapper">
        {this.maybeRenderSyncWarning()}
        {this.renderLoadingOverlay()}
        <Heading level="h3">{I18n.t('Search Courses')}</Heading>
        <br />
        <div className="bca-course-associations">
          <CoursePickerComponent
            ref={c => {
              this.coursePicker = c
            }}
            courses={this.props.courses}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            loadCourses={debounce(this.props.loadCourses, 200)}
            isLoadingCourses={this.props.isLoadingCourses}
            selectedCourses={this.props.addedAssociations
              .map(course => course.id)
              .filter((id): id is string => Boolean(id))}
            onSelectedChanged={this.onSelectedChanged}
            isExpanded={this.props.isExpanded}
            detailsRef={this.focusManager.registerBeforeRef}
          />
          <PresentationContent>
            <hr />
          </PresentationContent>
          <Heading level="h3">{I18n.t('Associated')}</Heading>
          <AssociationsTable
            existingAssociations={this.props.existingAssociations}
            addedAssociations={this.props.addedAssociations}
            removedAssociations={this.props.removedAssociations}
            onRemoveAssociations={this.props.removeAssociations}
            onRestoreAssociations={this.props.addAssociations}
            isLoadingAssociations={this.props.isLoadingAssociations}
            focusManager={this.focusManager}
          />
        </div>
      </div>
    )
  }
}

const connectState = (state: Record<string, unknown>) =>
  Object.assign(
    select(state, [
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
    ]),
    {
      hasUnsyncedChanges:
        !(state as {hasLoadedUnsyncedChanges?: boolean}).hasLoadedUnsyncedChanges ||
        ((state as {unsyncedChanges?: unknown[]}).unsyncedChanges?.length ?? 0) > 0,
    },
  )
const connectActions = (dispatch: Dispatch) => bindActionCreators(actions, dispatch)
export const ConnectedBlueprintAssociations = connect(
  connectState,
  connectActions,
)(BlueprintAssociations) as unknown as React.ComponentType<Record<string, unknown>>
