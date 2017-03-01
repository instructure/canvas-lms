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

  return class CourseFilter extends React.Component {
    static propTypes = {
      onChange: func,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
    }

    static defaultProps = {
      onChange: () => {},
    }

    constructor () {
      super()
      this.state = {
        course: '',
        term: '0',
        subAccount: '0',
      }
    }

    onChange = () => {
      this.setState({
        course: this.courseInput.value,
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
              <GridCol width={8}>
                <TextInput
                  ref={(c) => { this.courseInput = c }}
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
                  <option key="0" value="0">{I18n.t('Term')}</option>
                  {this.props.terms.map(term => (
                    <option key={term.id} value={term.id}>{term.name}</option>
                  ))}
                </Select>
              </GridCol>
              <GridCol width={2}>
                <Select
                  selectRef={(c) => { this.subAccountInput = c }}
                  key="subAccounts"
                  onChange={this.onChange}
                  label={
                    <ScreenReaderContent>{I18n.t('Select Subaccount')}</ScreenReaderContent>
                  }
                >
                  <option key="0" value="0">{I18n.t('Subaccount')}</option>
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
