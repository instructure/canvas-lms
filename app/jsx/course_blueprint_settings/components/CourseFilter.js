import I18n from 'i18n!blueprint_config'
import React from 'react'
import TextInput from 'instructure-ui/TextInput'
import Select from 'instructure-ui/Select'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import Grid, {GridCol, GridRow} from 'instructure-ui/Grid'
import propTypes from '../propTypes'

const { func } = React.PropTypes
const MIN_SEACH = 3 // min search term length for API

export default class CourseFilter extends React.Component {
  static propTypes = {
    onChange: func,
    onActivate: func,
    onDeactivate: func,
    terms: propTypes.termList.isRequired,
    subAccounts: propTypes.accountList.isRequired,
  }

  static defaultProps = {
    onChange: () => {},
    onActivate: () => {},
    onDeactivate: () => {},
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

  onChange = () => {
    this.setState({
      search: this.getSearchText(),
      term: this.termInput.value,
      subAccount: this.subAccountInput.value,
    }, () => {
      this.props.onChange(this.state)
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
          }, () => {
            this.props.onDeactivate()
          })
        }
      }
    }, 0)
  }

  render () {
    return (
      <div className="bps-course-filter" ref={(c) => { this.wrapper = c }}>
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
