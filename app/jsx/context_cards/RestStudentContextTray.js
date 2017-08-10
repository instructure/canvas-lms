import React from "react";
import PropTypes from "prop-types";
import StudentContextTray from "jsx/context_cards/StudentContextTray";
import StudentCardStore from "jsx/context_cards/StudentCardStore";

export default class RestStudentContextTray extends React.Component {
  static propTypes = {
    studentId: PropTypes.string.isRequired,
    courseId: PropTypes.string.isRequired
  };

  constructor(props) {
    super(props);
    this.state = {
      loading: true
    };
    this.store = new StudentCardStore(
      this.props.studentId,
      this.props.courseId
    );
    this.store.load();
    this.store.onChange = () =>
      this.setState(this.mungeState(this.store.getState()));
  }

  componentWillUnmount() {
    this.store.onChange = null;
  }

  mungeState(state) {
    const {
      loading,
      course,
      user,
      submissions,
      permissions,
      analytics
    } = state;

    const sectionsById = course.sections.reduce((obj, section) => {
      obj[section.id] = section;
      return obj;
    }, {});

    return {
      loading: loading,
      course: {
        _id: course.id,
        submissionsConnection: {
          edges: submissions.map(submission => ({
            submission: {
              user: { _id: submission.user_id },
              ...submission
            }
          }))
        },
        permissions: permissions,
        ...course
      },
      user: {
        ...user,
        _id: user.id,
        analytics: analytics
          ? {
              page_views: {
                total: analytics.page_views,
                max: analytics.max_page_views,
                level: analytics.page_views_level
              },
              participations: {
                total: analytics.participations,
                max: analytics.max_participations,
                level: analytics.participations_level
              },
              tardiness_breakdown: analytics.tardiness_breakdown
            }
          : null,
        enrollments: user.enrollments.map(e => ({
          last_activity_at: e.last_activity_at,
          section: sectionsById[e.course_section_id],
          grades: e.grades
        }))
      }
    };
  }

  render() {
    return <StudentContextTray {...this.props} data={this.state} />;
  }
}
