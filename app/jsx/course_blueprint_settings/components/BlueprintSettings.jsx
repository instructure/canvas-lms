define([
  'i18n!blueprint_config',
  'react',
  'instructure-ui/Heading',
  '../propTypes',
  './CoursePicker',
], (I18n, React, {default: Heading}, propTypes, CoursePicker) => {

  return class BlueprintSettings extends React.Component {
    static propTypes = {
      course: propTypes.course.isRequired,
      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
    }

    render () {
      return (
        <div className="bps__wrapper">
          <Heading level="h2">{I18n.t('Blueprint Settings')}</Heading>
          <br />
          <Heading level="h3">{I18n.t('Associated Courses')}</Heading>
          <hr />
          <Heading level="h3">{I18n.t('Search Courses')}</Heading>
          <br />
          <CoursePicker
            terms={this.props.terms}
            subAccounts={this.props.subAccounts}
          />
        </div>
      )
    }
  }
})
