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

import React from 'react'
import PropTypes from 'prop-types'
import moment from 'moment'
import axios from 'axios'
import I18n from 'i18n!last_attended'

import Container from '@instructure/ui-core/lib/components/Container'
import DateInput from '@instructure/ui-core/lib/components/DateInput'
import Text from '@instructure/ui-core/lib/components/Text'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

import {showFlashError} from '../shared/FlashAlert'

export default class StudentLastAttended extends React.Component {
  static propTypes = {
    defaultDate: PropTypes.string,
    courseID: PropTypes.number.isRequired,
    studentID: PropTypes.number.isRequired
  }

  static defaultProps = {
    defaultDate: null
  }

  constructor(props) {
    super(props)
    const currentDate = new Date(moment(this.props.defaultDate).toString())
    this.state = {
      selectedDate: currentDate || null,
      messages: [],
      loading: false
    }
  }

  componentDidMount() {
    this.createCancelToken()
  }

  onDateSubmit = (e, date) => {
    const currentDate = new Date(date)
    const messages = this.checkDateValidations(currentDate)
    if (!messages.length) {
      this.postDateToBackend(currentDate)
    } else {
      this.setState({messages})
    }
  }

  componentWillUnMount() {
    this.source.cancel()
  }

  // Used to allow us to cancel the axios call when posting date
  createCancelToken() {
    const cancelToken = axios.CancelToken
    this.source = cancelToken.source()
  }

  checkDateValidations(date) {
    if (date.toString() === 'Invalid Date') {
      return [{text: I18n.t('Enter a valid date'), type: 'error'}]
    } else {
      return []
    }
  }

  postDateToBackend(currentDate) {
    this.setState({loading: true})
    axios
      .put(`/api/v1/courses/${this.props.courseID}/users/${this.props.studentID}/last_attended`, {
        date: currentDate,
        cancelToken: this.source.token
      })
      .then(() => {
        this.setState({loading: false, selectedDate: currentDate})
      })
      .catch(() => {
        this.setState({loading: false})
        showFlashError(I18n.t('Failed To Change Last Attended Date'))
      })
  }

  renderTitle() {
    return (
      <Container display="block" margin="small 0">
        <Text margin="small 0">{I18n.t('Last day attended')}</Text>
      </Container>
    )
  }

  render() {
    if (this.state.loading) {
      return (
        <Container display="block" margin="small x-small">
          {this.renderTitle()}
          <Container display="block" margin="small">
            <Spinner
              margin="small 0"
              display="block"
              title={I18n.t('Loading last attended date')}
              size="small"
            />
          </Container>
        </Container>
      )
    }
    return (
      <Container display="block" margin="small x-small">
        {this.renderTitle()}
        <DateInput
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          label={<ScreenReaderContent>{I18n.t('Set Last Attended Date')}</ScreenReaderContent>}
          onDateChange={this.onDateSubmit}
          messages={this.state.messages}
          dateValue={
            !this.state.selectedDate || this.state.selectedDate.toString() === 'Invalid Date'
              ? null
              : this.state.selectedDate.toISOString()
          }
          validationFeedback={false}
        />
      </Container>
    )
  }
}
