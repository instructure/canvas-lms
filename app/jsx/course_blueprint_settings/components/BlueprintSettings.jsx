define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Heading',
  'instructure-ui/Alert',
  '../propTypes',
  './CoursePicker',
], (I18n, React, {default: Heading}, {default: Alert}, propTypes, CoursePicker) => {
  const { string, arrayOf, func, bool } = React.PropTypes

  return class BlueprintSettings extends React.Component {
    static propTypes = {
      loadCourses: func.isRequired,
      courses: propTypes.courseList.isRequired,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
      errors: arrayOf(string),
      isLoadingCourses: bool.isRequired,
    }

    static defaultProps = {
      errors: [],
    }

    componentWillMount () {
      this.props.loadCourses()
    }

    render () {
      return (
        <div className="bps__wrapper">
          {this.props.errors.map(err => <Alert key={err} variant="warning">Error: {err}</Alert>)}
          {this.props.errors.length ? <br /> : null}
          <Heading level="h2">{I18n.t('Blueprint Settings')}</Heading>
          <br />
          <Heading level="h3">{I18n.t('Associated Courses')}</Heading>
          <hr />
          <Heading level="h3">{I18n.t('Search Courses')}</Heading>
          <br />
          <CoursePicker
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
            courses={this.props.courses}
            loadCourses={this.props.loadCourses}
            isLoadingCourses={this.props.isLoadingCourses}
          />
        </div>
      )
    }
  }
})
