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
import axios from 'axios'
import I18n from 'i18n!conversations'
import Autocomplete from 'instructure-ui/lib/components/Autocomplete'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import React from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import {showFlashError} from 'jsx/shared/FlashAlert'

export default class CoursesGroupsAutocomplete extends React.Component {
  static propTypes = {
    onChange: PropTypes.func.isRequired,
    placeholder: PropTypes.string.isRequired,
    allowEmpty: PropTypes.bool,
    className: PropTypes.string,
    maxCoursesToFetch: PropTypes.number,
    initialSelectedOption: PropTypes.shape({
      entityType: PropTypes.oneOf(['course', 'group']).isRequired,
      entityId: PropTypes.number.isRequired
    })
  }

  static defaultProps = {
    allowEmpty: true,
    className: "",
    maxCoursesToFetch: 100,
    initialSelectedOption: ""
  }

  state = {
    courseOptions: [],
    groupOptions: [],
    selectedOption: "",
    loadedCourses: false,
    loadedGroups: false
  }

  componentDidMount() {
    // It's possible to show an error if the axios requests are pending when
    // the component unmounts.  This shouldn't normally happen, but might
    // happen if the user navigates away really quickly.  So don't show errors
    // just if a cancel happens.
    this.loadedCourses = false
    this.loadedGroups = false
    this.createCancelToken()
    this.loadCourses()
    this.loadGroups()
  }

  componentWillReceiveProps(nextProps) {
    const newOption = nextProps.initialSelectedOption
    if (newOption) {
      if (newOption.entityType === 'course' || newOption.entityType === 'group') {
        const optionKey = `${newOption.entityType}_${newOption.entityId}`
        const entityArray =
          newOption.entityType === 'course' ? this.state.courseOptions : this.state.groupOptions
        this.setStateFromParam(entityArray, optionKey)
      } else {
        this.setState({selectedOption: ""})
      }
    } else {
      // FELIX: WHY DOES THIS NOT CLEAR OUT THE COURSE GROUP FILTER LABEL?
      this.setState({selectedOption: ""})
    }
  }

  componentWillUnmount() {
    // Don't show errors just because we are canceling
    this.shouldShowErrors = false
    this.source.cancel()
  }

  setStateFromParam(entityArray, param) {
    const matchingEntity = entityArray.find(entity => entity.value === param)
    if (matchingEntity) {
      this.setState({selectedOption: param})
    } else {
      this.setState({selectedOption: ""})
    }
  }

  getCourseUrl() {
    const courseUrlBase = '/api/v1/courses/?'
    const params = {
      state: ['unpublished', 'available', 'completed'],
      include: ['term'],
      per_page: this.props.maxCoursesToFetch
    }
    return `${courseUrlBase}${$.param(params)}`
  }

  loadCourses() {
    axios
      .get(this.getCourseUrl(), {
        cancelToken: this.source.token
      })
      .then(response => {
        this.processEntityResponse('course', response.data)
      })
      .catch(error => {
        // Only show error if this wasn't a cancel
        if (this.shouldShowErrors) {
          showFlashError(I18n.t('Error loading courses'))(error)
        }
      })
  }

  loadGroups() {
    axios
      .get('/api/v1/users/self/groups', {
        cancelToken: this.source.token
      })
      .then(response => {
        this.processEntityResponse('group', response.data)
      })
      .catch(error => {
        // Only show error if this wasn't a cancel
        if (this.shouldShowGroups) {
          showFlashError(I18n.t('Error loading groups'))(error)
        }
      })
  }

  processEntityResponse(entityType, response) {
    const generatedOptions = response.map(entity => ({
      value: `${entityType}_${entity.id}`,
      label: entity.name ? entity.name : ""
    }))
    const stateObject = {}
    stateObject[`${entityType}Options`] = generatedOptions
    const capitalizedEntityType = entityType.charAt(0).toUpperCase() + entityType.slice(1);
    stateObject[`loaded${capitalizedEntityType}s`] = true
    const selectedOption = this.props.initialSelectedOption
    if (selectedOption) {
      const optionAsValue = `${selectedOption.entityType}_${selectedOption.entityId}`
      const matchingOption = generatedOptions.find(option => option.value === optionAsValue)
      if (matchingOption) {
        stateObject.selectedOption = matchingOption
      }
    }
    stateObject.loaded = this.state
    this.setState(stateObject)
  }
  // Used to allow us to cancel the fetch group/course requests if this component unmounts
  // before these requests finish.
  createCancelToken() {
    const cancelToken = axios.CancelToken
    this.source = cancelToken.source()
  }

  // TODO: There is a bug in instui where, in some cases, if you hit the "back"
  // browser button *from* a page where a selection was made, and the "back"
  // button takes you to the same page (but with different params) where a
  // selecton was *not* made, the chosen selection doesn't clear out (but
  // the correct filtering still occurs).  Instead for now we render to an
  // explicit "empty" option to force a proper render.  We should clear this
  // out once instui fixes this bug and we upgrade to the needed version.
  emptyOption() {
    return (
      <option key={""} value={""}>
        {this.props.placeholder}
      </option>
    )
  }

  arrayToOptions(prefix, entityArray) {
    return entityArray.map(entity => (
      <option key={entity.value} value={entity.value}>
        {entity.label}
      </option>
    ))
  }

  shouldEnable() {
    const result = this.state.loadedCourses && this.state.loadedGroups
    return result
  }

  render() {
    return (
      <Autocomplete
        multiple={false}
        width="211"
        className={this.props.className}
        allowEmpty={this.props.allowEmpty}
        label={<ScreenReaderContent>{ I18n.t("Filter conversations by course or group") }</ScreenReaderContent>}
        disabled={false}
        editable={true}
        onChange={this.props.onChange}
        selectedOption={this.state.selectedOption}
        placeholder={this.props.placeholder}
      >
        {this.emptyOption()}
        {this.arrayToOptions('course', this.state.courseOptions)}
        {this.arrayToOptions('group', this.state.groupOptions)}
      </Autocomplete>
    )
  }
}
