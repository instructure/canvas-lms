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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {arrayOf, func, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import moment from 'moment'
import {debounce} from 'lodash'
import {Checkbox} from '@instructure/ui-checkbox'
import CanvasAsyncSelect from '@canvas/instui-bindings/react/AsyncSelect'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import SearchFormActions from './actions/SearchFormActions'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import environment from './environment'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'

const I18n = useI18nScope('gradebook_history')

const DEBOUNCE_DELAY = 500 // milliseconds

const recordShape = shape({
  fetchStatus: string.isRequired,
  items: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired,
    })
  ),
  nextPage: string.isRequired,
})

const formatDate = date => tz.format(date, 'date.formats.medium_with_weekday')

class SearchFormComponent extends Component {
  static propTypes = {
    fetchHistoryStatus: string.isRequired,
    assignments: recordShape.isRequired,
    graders: recordShape.isRequired,
    students: recordShape.isRequired,
    getGradebookHistory: func.isRequired,
    clearSearchOptions: func.isRequired,
    getSearchOptions: func.isRequired,
    getSearchOptionsNextPage: func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      selected: {
        assignment: '',
        grader: '',
        student: '',
        from: {value: ''},
        to: {value: ''},
        showFinalGradeOverridesOnly: false,
      },
      messages: {
        assignments: I18n.t('Type a few letters to start searching'),
        graders: I18n.t('Type a few letters to start searching'),
        students: I18n.t('Type a few letters to start searching'),
      },
    }
    this.debouncedGetSearchOptions = debounce(props.getSearchOptions, DEBOUNCE_DELAY)
  }

  componentDidMount() {
    this.props.getGradebookHistory(this.state.selected)
  }

  UNSAFE_componentWillReceiveProps({fetchHistoryStatus, assignments, graders, students}) {
    if (this.props.fetchHistoryStatus === 'started' && fetchHistoryStatus === 'failure') {
      showFlashAlert({message: I18n.t('Error loading gradebook history. Try again?')})
    }

    if (assignments.fetchStatus === 'success' && assignments.items.length === 0) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          assignments: I18n.t('No artifacts with that name found'),
        },
      }))
    }
    if (graders.fetchStatus === 'success' && !graders.items.length) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          graders: I18n.t('No graders with that name found'),
        },
      }))
    }
    if (students.fetchStatus === 'success' && !students.items.length) {
      this.setState(prevState => ({
        messages: {
          ...prevState.messages,
          students: I18n.t('No students with that name found'),
        },
      }))
    }
    if (assignments.nextPage) {
      this.props.getSearchOptionsNextPage('assignments', assignments.nextPage)
    }
    if (graders.nextPage) {
      this.props.getSearchOptionsNextPage('graders', graders.nextPage)
    }
    if (students.nextPage) {
      this.props.getSearchOptionsNextPage('students', students.nextPage)
    }
  }

  setSelectedFrom = from => {
    const value = from == null ? null : moment(from).startOf('day').toISOString()

    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        from: {value},
      },
    }))
  }

  setSelectedTo = to => {
    const value = to == null ? null : moment(to).endOf('day').toISOString()

    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        to: {value},
      },
    }))
  }

  setSelectedAssignment = (_event, selectedOption) => {
    const selname = this.props.assignments.items.find(e => e.id === selectedOption)?.name
    if (selname) this.props.getSearchOptions('assignments', selname)
    this.setState(prevState => {
      const selected = {
        ...prevState.selected,
        assignment: selectedOption || '',
      }

      // If we selected an assignment, uncheck the "show final grade overrides
      // only" checkbox
      if (selectedOption) {
        selected.showFinalGradeOverridesOnly = false
      }

      return {selected}
    })
  }

  setSelectedGrader = (_event, selected) => {
    const selname = this.props.graders.items.find(e => e.id === selected)?.name
    if (selname) this.props.getSearchOptions('graders', selname)
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        grader: selected || '',
      },
    }))
  }

  setSelectedStudent = (_event, selected) => {
    const selname = this.props.students.items.find(e => e.id === selected)?.name
    if (selname) this.props.getSearchOptions('students', selname)
    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        student: selected || '',
      },
    }))
  }

  hasToBeforeFrom() {
    return (
      moment(this.state.selected.from.value).diff(
        moment(this.state.selected.to.value),
        'seconds'
      ) >= 0
    )
  }

  hasDateInputErrors() {
    return this.dateInputErrors().length > 0
  }

  dateInputErrors = () => {
    if (this.hasToBeforeFrom()) {
      return [
        {
          type: 'error',
          text: I18n.t("'From' date must be before 'To' date"),
        },
      ]
    }

    return []
  }

  promptUserEntry = () => {
    const emptyMessage = I18n.t('Type a few letters to start searching')
    this.setState({
      messages: {
        assignments: emptyMessage,
        graders: emptyMessage,
        students: emptyMessage,
      },
    })
  }

  handleAssignmentChange = (_event, value) => {
    this.handleSearchEntry('assignments', value)
  }

  handleGraderChange = (_event, value) => {
    this.handleSearchEntry('graders', value)
  }

  handleStudentChange = (_event, value) => {
    this.handleSearchEntry('students', value)
  }

  handleShowFinalGradeOverridesOnlyChange = _event => {
    const enabled = !this.state.selected.showFinalGradeOverridesOnly

    if (enabled) {
      // If we checked the checkbox, clear any assignments we were filtering by
      this.props.clearSearchOptions('assignments')
    }

    this.setState(prevState => ({
      selected: {
        ...prevState.selected,
        assignment: enabled ? '' : prevState.selected.assignment,
        showFinalGradeOverridesOnly: enabled,
      },
    }))
  }

  handleSearchEntry = (target, searchTerm) => {
    if (searchTerm.length <= 2) {
      if (this.props[target].items.length > 0) {
        this.props.clearSearchOptions(target)
        this.promptUserEntry()
      }

      return
    }

    this.debouncedGetSearchOptions(target, searchTerm)
  }

  handleSubmit = () => {
    this.props.getGradebookHistory(this.state.selected)
  }

  renderAsOptions = data =>
    data.map(i => (
      <CanvasAsyncSelect.Option key={i.id} id={i.id}>
        {i.name}
      </CanvasAsyncSelect.Option>
    ))

  render() {
    return (
      <View as="div" margin="0 0 xx-large">
        <Grid>
          <Grid.Row>
            <Grid.Col>
              <View as="div">
                <FormFieldGroup
                  description={<ScreenReaderContent>{I18n.t('Search Form')}</ScreenReaderContent>}
                  as="div"
                  layout="columns"
                  colSpacing="small"
                  vAlign="top"
                  startAt="large"
                >
                  <FormFieldGroup
                    description={<ScreenReaderContent>{I18n.t('Users')}</ScreenReaderContent>}
                    as="div"
                    layout="columns"
                    vAlign="top"
                    startAt="medium"
                  >
                    <CanvasAsyncSelect
                      id="students"
                      renderLabel={I18n.t('Student')}
                      isLoading={this.props.students.fetchStatus === 'started'}
                      selectedOptionId={this.state.selected.student}
                      noOptionsLabel={this.state.messages.students}
                      onBlur={this.promptUserEntry}
                      onOptionSelected={this.setSelectedStudent}
                      onInputChange={this.handleStudentChange}
                    >
                      {this.renderAsOptions(this.props.students.items)}
                    </CanvasAsyncSelect>
                    <CanvasAsyncSelect
                      id="graders"
                      renderLabel={I18n.t('Grader')}
                      isLoading={this.props.graders.fetchStatus === 'started'}
                      selectedOptionId={this.state.selected.grader}
                      noOptionsLabel={this.state.messages.graders}
                      onBlur={this.promptUserEntry}
                      onOptionSelected={this.setSelectedGrader}
                      onInputChange={this.handleGraderChange}
                    >
                      {this.renderAsOptions(this.props.graders.items)}
                    </CanvasAsyncSelect>
                    <CanvasAsyncSelect
                      id="assignments"
                      renderLabel={I18n.t('Artifact')}
                      isLoading={this.props.assignments.fetchStatus === 'started'}
                      selectedOptionId={this.state.selected.assignment}
                      noOptionsLabel={this.state.messages.assignments}
                      onBlur={this.promptUserEntry}
                      onOptionSelected={this.setSelectedAssignment}
                      onInputChange={this.handleAssignmentChange}
                    >
                      {this.renderAsOptions(this.props.assignments.items)}
                    </CanvasAsyncSelect>
                  </FormFieldGroup>

                  <FormFieldGroup
                    description={<ScreenReaderContent>{I18n.t('Dates')}</ScreenReaderContent>}
                    layout="columns"
                    startAt="small"
                    vAlign="top"
                    messages={this.dateInputErrors()}
                    width="auto"
                  >
                    <CanvasDateInput
                      renderLabel={I18n.t('Start Date')}
                      formatDate={formatDate}
                      selectedDate={this.state.selected.from.value}
                      onSelectedDateChange={this.setSelectedFrom}
                      withRunningValue={true}
                    />
                    <CanvasDateInput
                      renderLabel={I18n.t('End Date')}
                      formatDate={formatDate}
                      selectedDate={this.state.selected.to.value}
                      onSelectedDateChange={this.setSelectedTo}
                      withRunningValue={true}
                    />
                  </FormFieldGroup>
                </FormFieldGroup>
              </View>

              {environment.overrideGradesEnabled() && (
                <View
                  as="div"
                  margin="medium 0"
                  data-testid="show-final-grade-overrides-only-checkbox"
                >
                  <Checkbox
                    checked={this.state.selected.showFinalGradeOverridesOnly}
                    id="show_final_grade_overrides_only"
                    label={I18n.t('Show Final Grade Overrides Only')}
                    onChange={this.handleShowFinalGradeOverridesOnlyChange}
                  />
                </View>
              )}
            </Grid.Col>

            <Grid.Col width="auto">
              <div style={{margin: '1.9rem 0 0 0'}}>
                <Button
                  onClick={this.handleSubmit}
                  type="submit"
                  color="primary"
                  disabled={this.hasDateInputErrors()}
                >
                  {I18n.t('Filter')}
                </Button>
              </div>
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </View>
    )
  }
}

const mapStateToProps = state => ({
  fetchHistoryStatus: state.history.fetchHistoryStatus || '',
  assignments: {
    fetchStatus: state.searchForm.records.assignments.fetchStatus || '',
    items: state.searchForm.records.assignments.items || [],
    nextPage: state.searchForm.records.assignments.nextPage || '',
  },
  graders: {
    fetchStatus: state.searchForm.records.graders.fetchStatus || '',
    items: state.searchForm.records.graders.items || [],
    nextPage: state.searchForm.records.graders.nextPage || '',
  },
  students: {
    fetchStatus: state.searchForm.records.students.fetchStatus || '',
    items: state.searchForm.records.students.items || [],
    nextPage: state.searchForm.records.students.nextPage || '',
  },
})

const mapDispatchToProps = dispatch => ({
  getGradebookHistory: input => {
    dispatch(SearchFormActions.getGradebookHistory(input))
  },
  getSearchOptions: (recordType, searchTerm) => {
    dispatch(SearchFormActions.getSearchOptions(recordType, searchTerm))
  },
  getSearchOptionsNextPage: (recordType, url) => {
    dispatch(SearchFormActions.getSearchOptionsNextPage(recordType, url))
  },
  clearSearchOptions: recordType => {
    dispatch(SearchFormActions.clearSearchOptions(recordType))
  },
})

export default connect(mapStateToProps, mapDispatchToProps)(SearchFormComponent)

export {SearchFormComponent}
