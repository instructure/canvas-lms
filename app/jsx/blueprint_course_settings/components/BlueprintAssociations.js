import I18n from 'i18n!blueprint_settings'
import $ from 'jquery'
import React from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import 'compiled/jquery.rails_flash_notifications'

import Heading from 'instructure-ui/lib/components/Heading'
import Alert from 'instructure-ui/lib/components/Alert'
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

    isLoadingCourses: bool.isRequired,
    isLoadingAssociations: bool.isRequired,
    isSavingAssociations: bool.isRequired,

    errors: arrayOf(string),
    isExpanded: bool,
  }

  static defaultProps = {
    errors: [],
    isExpanded: false,
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

  selectCourses = (selected) => {
    const added = this.props.addedAssociations.map(course => course.id)
    const courseIds = Object.keys(selected).filter(courseId => selected[courseId] && !added.includes(courseId))
    this.props.addAssociations(courseIds)
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
        {this.props.errors.map(err => <Alert key={err} variant="warning">Error: {err}</Alert>)}
        {this.props.errors.length ? <br /> : null}
        <Heading level="h3">{I18n.t('Search Courses')}</Heading>
        <br />
        <div className="bca-course-associations">
          <CoursePicker
            ref={(c) => { this.coursePicker = c }}
            courses={this.props.courses}
            excludeCourses={this.props.addedAssociations.map(c => c.id)}
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            loadCourses={this.props.loadCourses}
            isLoadingCourses={this.props.isLoadingCourses}
            onSelectedChanged={this.selectCourses}
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
  [
    'existingAssociations',
    'addedAssociations',
    'removedAssociations',
    'courses',
    'terms',
    'subAccounts',
    'errors',
    'isLoadingCourses',
    'isLoadingAssociations',
    'isSavingAssociations',
  ].reduce((propSet, prop) => Object.assign(propSet, { [prop]: state[prop] }), {})
const connectActions = dispatch => bindActionCreators(actions, dispatch)

export const ConnectedBlueprintAssociations = connect(connectState, connectActions)(BlueprintAssociations)
