define([
  'react',
  'i18n!student_context_tray',
  'instructure-ui'
], (React, I18n, { MetricsList: InstUIMetricsList, MetricsListItem }) => {
  class MetricsList extends React.Component {
    static propTypes = {
      analytics: React.PropTypes.object,
      user: React.PropTypes.object
    }

    static defaultProps = {
      analytics: {},
      user: {}
    }

    get grade () {
      if (typeof this.props.user.enrollments === 'undefined') {
        return null
      }

      const enrollment = this.props.user.enrollments[0]
      const grades = enrollment.grades
      if (grades.current_grade) {
        return grades.current_grade
      } else if (grades.current_score) {
        return `${grades.current_score}%`
      } else {
        return '-'
      }
    }

    get missingCount () {
      if (typeof this.props.analytics.tardiness_breakdown === 'undefined') {
        return null
      }

      return `${this.props.analytics.tardiness_breakdown.missing}`
    }

    get lateCount () {
      if (typeof this.props.analytics.tardiness_breakdown === 'undefined') {
        return null
      }

      return `${this.props.analytics.tardiness_breakdown.late}`
    }

    render () {
      if (
        typeof this.props.user.enrollments !== 'undefined' &&
        Object.keys(this.props.analytics).length > 0
      ) {
        return (
          <section
            className="StudentContextTray__Section StudentContextTray-MetricsList">
            <InstUIMetricsList>
              <MetricsListItem label={I18n.t('Grade')} value={this.grade} />
              <MetricsListItem label={I18n.t('Missing')} value={this.missingCount} />
              <MetricsListItem label={I18n.t('Late')} value={this.lateCount} />
            </InstUIMetricsList>
          </section>
        )
      } else { return null }
    }
  }

  return MetricsList
})
