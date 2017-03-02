define([
  'i18n!blueprint_config',
  'jquery',
  'react',
  'instructure-ui/Heading',
  'instructure-ui/Alert',
  'instructure-ui/Button',
  'instructure-ui/Typography',
  'instructure-ui/Spinner',
  '../propTypes',
  './CoursePicker',
  './AssociationsTable',
  'compiled/jquery.rails_flash_notifications',
], (I18n, $, React, {default: Heading}, {default: Alert}, {default: Button}, {default: Typography}, {default: Spinner},
  propTypes, CoursePicker, AssociationsTable) => {
  const { string, arrayOf, func, bool } = React.PropTypes

  return class BlueprintSettings extends React.Component {
    static propTypes = {
      loadCourses: func.isRequired,
      addAssociations: func.isRequired,
      removeAssociations: func.isRequired,
      saveAssociations: func.isRequired,
      cancel: func.isRequired,

      terms: propTypes.termList.isRequired,
      subAccounts: propTypes.accountList.isRequired,
      courses: propTypes.courseList.isRequired,
      existingAssociations: propTypes.courseList.isRequired,
      addedAssociations: propTypes.courseList.isRequired,
      removedAssociations: arrayOf(string).isRequired,

      isLoadingCourses: bool.isRequired,
      isLoadingAssociations: bool.isRequired,
      isSavingAssociations: bool.isRequired,

      errors: arrayOf(string),
      isExpanded: bool,
    }

    static defaultProps = {
      errors: [],
      isExpanded: false,
    }

    componentWillReceiveProps (nextProps) {
      if (!this.props.isSavingAssociations && nextProps.isSavingAssociations) {
        $.screenReaderFlashMessage(I18n.t('Saving associations started'))
      }

      if (this.props.isSavingAssociations && !nextProps.isSavingAssociations) {
        $.screenReaderFlashMessageExclusive(I18n.t('Saving associations complete'))

        // when saving is done, reload courses in course picker
        // this will remove courses we just associated from the picker
        this.coursePicker.reloadCourses()
      }
    }

    selectCourses = (selected) => {
      const added = this.props.addedAssociations.map(course => course.id)
      const courseIds = Object.keys(selected).filter(courseId => selected[courseId] && !added.includes(courseId))
      this.props.addAssociations(courseIds)
    }

    renderHeader () {
      return (
        <header>
          <Heading level="h2">{I18n.t('Blueprint Settings')}</Heading>
          <br />
          <Heading level="h3">{I18n.t('Associated Courses')}</Heading>
          <hr />
          <Heading level="h3">{I18n.t('Search Courses')}</Heading>
        </header>
      )
    }

    renderFooter () {
      return (
        <footer className="bps__footer">
          <Button onClick={this.props.cancel}>{I18n.t('Cancel')}</Button>
          &nbsp;&nbsp;
          <Button variant="primary" onClick={this.props.saveAssociations}>{I18n.t('Save')}</Button>
        </footer>
      )
    }

    renderLoadingOverlay () {
      if (this.props.isSavingAssociations) {
        const title = I18n.t('Saving Associations')
        return (
          <div className="bps__overlay bps__overlay__save">
            <Spinner title={title} />
            <Typography tag="p">{title}</Typography>
          </div>
        )
      }

      return null
    }

    render () {
      return (
        <div className="bps__wrapper">
          {this.renderLoadingOverlay()}
          {this.props.errors.map(err => <Alert key={err} variant="warning">Error: {err}</Alert>)}
          {this.props.errors.length ? <br /> : null}
          {this.renderHeader()}
          <br />
          <div className="bps-course-associations">
            <CoursePicker
              ref={(c) => { this.coursePicker = c }}
              courses={this.props.courses}
              excludeCourses={this.props.addedAssociations.map(c => c.id)}
              terms={this.props.terms}
              subAccounts={this.props.subAccounts}
              loadCourses={this.props.loadCourses}
              isLoadingCourses={this.props.isLoadingCourses}
              onSelectedChanged={this.selectCourses}
              isExpanded={this.props.isExpanded}
            />
            <hr />
            <Heading level="h3">{I18n.t('Associated')}</Heading>
            <AssociationsTable
              existingAssociations={this.props.existingAssociations}
              addedAssociations={this.props.addedAssociations}
              removedAssociations={this.props.removedAssociations}
              onRemoveAssociations={this.props.removeAssociations}
              isLoadingAssociations={this.props.isLoadingAssociations}
            />
          </div>
          <hr />
          {this.renderFooter()}
        </div>
      )
    }
  }
})
