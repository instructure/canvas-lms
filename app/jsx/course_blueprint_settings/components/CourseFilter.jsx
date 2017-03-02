define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/TextInput',
  'instructure-ui/Select',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/Grid',
  'instructure-ui/ApplyTheme',
  '../propTypes',
], (I18n, React, {default: TextInput}, {default: Select}, {default: ScreenReaderContent}, {default: Grid, GridCol, GridRow},
  {default: ApplyTheme}, propTypes) => {
  const { func } = React.PropTypes
  const MIN_SEACH = 3 // min search term length for API

  return class CourseFilter extends React.Component {
    static propTypes = {
      onChange: func,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
    }

    static defaultProps = {
      onChange: () => {},
    }

    constructor (props) {
      super(props)
      this.state = {
        search: '',
        term: '',
        subAccount: '',
      }
    }

    getSearchText () {
      const searchText = this.searchInput.value.trim().toLowerCase()
      return searchText.length >= MIN_SEACH ? searchText : ''
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

    render () {
      return (
        <div className="bps-course-filter">
          <Grid colSpacing="none">
            <GridRow>
              <GridCol width={7}>
                <TextInput
                  ref={(c) => { this.searchInput = c }}
                  type="search"
                  onChange={this.onChange}
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
})
