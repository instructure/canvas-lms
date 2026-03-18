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
import React from 'react'
import PropTypes from 'prop-types'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import propTypes from '@canvas/blueprint-courses/react/propTypes'
import type {Account, CourseFilterFilters, Term} from '../types'

const I18n = createI18nScope('blueprint_settingsCourseFilter')

const {func} = PropTypes
const MIN_SEACH = 3 // min search term length for API

interface CourseFilterProps {
  onChange?: (filters: CourseFilterFilters) => void
  onActivate?: () => void
  terms: Term[]
  subAccounts: Account[]
}

export default class CourseFilter extends React.Component<CourseFilterProps, CourseFilterFilters> {
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

  searchInput: TextInput | null = null
  wrapper: HTMLDivElement | null = null

  constructor(props: CourseFilterProps) {
    super(props)
    this.state = {
      isActive: false,
      search: '',
      term: '',
      subAccount: '',
    }
  }

  componentDidUpdate(_prevProps: CourseFilterProps, prevState: CourseFilterFilters) {
    if (
      prevState.search !== this.state.search ||
      prevState.term !== this.state.term ||
      prevState.subAccount !== this.state.subAccount
    ) {
      this.props.onChange?.(this.state)
    }
  }

  onChange = () => {
    this.setState({
      search: this.getSearchText(),
    })
  }

  getSearchText() {
    const searchInput = this.searchInput as unknown as {value?: string} | null
    const searchText = searchInput?.value?.trim().toLowerCase() ?? ''
    return searchText.length >= MIN_SEACH ? searchText : ''
  }

  handleFocus = () => {
    if (!this.state.isActive) {
      this.setState(
        {
          isActive: true,
        },
        () => {
          this.props.onActivate?.()
        },
      )
    }
  }

  handleBlur = () => {
    // the timeout prevents the courses from jumping between open between and close when you tab through the form elements
    setTimeout(() => {
      if (this.state.isActive) {
        const searchInput = this.searchInput as unknown as {value?: string} | null
        const search = searchInput?.value
        const isEmpty = !search

        if (isEmpty && this.wrapper && !this.wrapper.contains(document.activeElement)) {
          this.setState({
            isActive: false,
          })
        }
      }
    }, 0)
  }

  render() {
    const termOptions = [
      <CanvasSelect.Option key="all" id="all" value="">
        {I18n.t('Any Term')}
      </CanvasSelect.Option>,
      ...this.props.terms.map(term => (
        <CanvasSelect.Option key={term.id} id={term.id} value={term.id}>
          {term.name}
        </CanvasSelect.Option>
      )),
    ]

    const subAccountOptions = [
      <CanvasSelect.Option key="all" id="all" value="">
        {I18n.t('Any Sub-Account')}
      </CanvasSelect.Option>,
      ...this.props.subAccounts.map(account => (
        <CanvasSelect.Option key={account.id} id={account.id} value={account.id}>
          {account.name}
        </CanvasSelect.Option>
      )),
    ]

    return (
      <div
        className="bca-course-filter"
        ref={c => {
          this.wrapper = c
        }}
      >
        <Flex wrap="wrap">
          <Flex.Item shouldGrow={true} padding="0 x-small x-small 0">
            <TextInput
              ref={c => {
                this.searchInput = c
              }}
              type="search"
              onChange={this.onChange}
              onFocus={this.handleFocus}
              onBlur={this.handleBlur}
              placeholder={I18n.t('Search by title, short name, or SIS ID')}
              renderLabel={<ScreenReaderContent>{I18n.t('Search Courses')}</ScreenReaderContent>}
            />
          </Flex.Item>
          <Flex.Item padding="0 x-small x-small 0">
            <CanvasSelect
              id="termsFilter"
              key="terms"
              value={this.state.term}
              onChange={(_e: unknown, value: string) => this.setState({term: value})}
              label={<ScreenReaderContent>{I18n.t('Select Term')}</ScreenReaderContent>}
            >
              {termOptions}
            </CanvasSelect>
          </Flex.Item>
          <Flex.Item padding="0 0 x-small 0">
            <CanvasSelect
              id="subAccountsFilter"
              key="subAccounts"
              value={this.state.subAccount}
              onChange={(_e: unknown, value: string) => this.setState({subAccount: value})}
              label={<ScreenReaderContent>{I18n.t('Select Sub-Account')}</ScreenReaderContent>}
            >
              {subAccountOptions}
            </CanvasSelect>
          </Flex.Item>
        </Flex>
      </div>
    )
  }
}
