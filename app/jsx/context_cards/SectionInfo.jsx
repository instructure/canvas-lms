define([
  'react',
  'underscore',
  'i18n!student_context_tray'
], (React, _, I18n) => {

  class SectionInfo extends React.Component {
    static propTypes = {
      course: React.PropTypes.object,
      user: React.PropTypes.object
    }

    static defaultProps = {
      course: {},
      user: {}
    }

    get sections () {
      if (
        typeof this.props.user.enrollments === 'undefined' ||
        typeof this.props.course.sections === 'undefined'
      ) {
        return []
      }

      const sectionIds = this.props.user.enrollments.map((enrollment) => {
        return enrollment.course_section_id
      })

      return this.props.course.sections.filter((section) => {
        return _.contains(sectionIds, section.id)
      })
    }

    render () {
      const sections = this.sections

      if (sections.length > 0) {
        const sectionNames = sections.map((section) => {
          return section.name
        }).sort()
        return (
          <span>{I18n.t("Section: %{section_names}", { section_names: sectionNames.join(', ') })}</span>
        )
      } else { return null }
    }
  }

  return SectionInfo
})
