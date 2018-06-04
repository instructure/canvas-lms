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
import React from 'react'
import PropTypes from 'prop-types'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Select from '@instructure/ui-core/lib/components/Select'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import propTypes from '../propTypes'

const { func } = PropTypes
const MIN_SEACH = 3 // min search term length for API

export default class CourseFilter extends React.Component {
  static propTypes = {
    onChange: func,
    onActivate: func,
    terms: propTypes.termList.isRequired,
    subAccounts: propTypes.accountList.isRequired,
  }

  static defaultProps = {
    onChange: () => {},
    onActivate: () => {},
  }

  constructor (props) {
    super(props)
    this.state = {
      isActive: false,
      search: '',
      term: '',
      subAccount: '',
    }
  }

  componentDidUpdate (prevProps, prevState) {
    if (prevState.search !== this.state.search ||
        prevState.term !== this.state.term ||
        prevState.subAccount !== this.state.subAccount) {
      this.props.onChange(this.state)
    }
  }

  onChange = () => {
    this.setState({
      search: this.getSearchText(),
      term: this.termInput.value,
      subAccount: this.subAccountInput.value,
    })
  }

  getSearchText () {
    const searchText = this.searchInput.value.trim().toLowerCase()
    return searchText.length >= MIN_SEACH ? searchText : ''
  }

  handleFocus = () => {
    if (!this.state.isActive) {
      this.setState({
        isActive: true,
      }, () => {
        this.props.onActivate()
      })
    }
  }

  handleBlur = () => {
    // the timeout prevents the courses from jumping between open between and close when you tab through the form elements
    setTimeout(() => {
      if (this.state.isActive) {
        const search = this.searchInput.value
        const term = this.termInput.value
        const subAccount = this.subAccountInput.value
        const isEmpty = !search && !term && !subAccount

        if (isEmpty && !this.wrapper.contains(document.activeElement)) {
          this.setState({
            isActive: false,
          })
        }
      }
    }, 0)
  }

  render () {
    return (
      <div className="bca-course-filter" ref={(c) => { this.wrapper = c }}>
        <Grid colSpacing="none">
          <GridRow>
            <GridCol width={7}>
              <TextInput
                ref={(c) => { this.searchInput = c }}
                type="search"
                onChange={this.onChange}
                onFocus={this.handleFocus}
                onBlur={this.handleBlur}
                placeholder={I18n.t('Search by title, short name, or SIS ID')}
                label={
                  <ScreenReaderContent>{I18n.t('Search Courses')}</ScreenReaderContent>
                }
              />
            </GridCol>
            <GridCol width={2}>
              <Select
                selectRef={(c) => { this.termInput = c }}
                key="terms"
                onChange={this.onChange}
                onFocus={this.handleFocus}
                onBlur={this.handleBlur}
                label={
                  <ScreenReaderContent>{I18n.t('Select Term')}</ScreenReaderContent>
                }
              >
                <option key="all" value="">{I18n.t('Any Term')}</option>
                {this.props.terms.map(term => (
                  <option key={term.id} value={term.id}>{term.name}</option>
                ))}
              </Select>
            </GridCol>
            <GridCol width={3}>
              <Select
                selectRef={(c) => { this.subAccountInput = c }}
                key="subAccounts"
                onChange={this.onChange}
                onFocus={this.handleFocus}
                onBlur={this.handleBlur}
                label={
                  <ScreenReaderContent>{I18n.t('Select Sub-Account')}</ScreenReaderContent>
                }
              >
                <option key="all" value="">{I18n.t('Any Sub-Account')}</option>
                {this.props.subAccounts.map(account => (
                  <option key={account.id} value={account.id}>{account.name}</option>
                ))}
              </Select>
            </GridCol>
          </GridRow>
        </Grid>
      </div>
    )
  }
}
