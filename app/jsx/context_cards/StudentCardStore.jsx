define(['axios'], (axios) => {
  class StudentCardStore {
    constructor(studentId, courseId) {
      this.studentId = studentId
      this.courseId = courseId
      this.state = {
        loading: true,
        user: {},
        course: {},
        submissions: [],
        analytics: {},
        permissions: {
          manage_grades: false,
          send_messages: false,
          view_all_grades: false,
          view_analytics: false,
          become_user: false,
        }
      };
    }

    getState () {
      return this.state;
    }

    load () {
      Promise.all([
        this.loadCourse(this.courseId),
        this.loadUser(this.studentId, this.courseId),
        this.loadAnalytics(this.studentId, this.courseId),
        this.loadRecentlyGradedSubmissions(this.studentId, this.courseId),
        this.loadPermissions(this.courseId)
      ]).then(() => this.setState({loading: false}))
    }

    loadPermissions (courseId) {
      const permissions = Object.keys(this.state.permissions).map(permission =>
        `permissions[]=${permission}`
      ).join('&')

      return axios.get(`/api/v1/courses/${courseId}/permissions?${permissions}`)
        .then(response =>
          this.setState({permissions: response.data})
        ).catch(() => {})
    }

    loadCourse (courseId) {
      return axios.get(`/api/v1/courses/${courseId}?include[]=sections`)
        .then(response => this.setState({course: response.data}))
        .catch(() => {})
    }

    loadUser (studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/users/${studentId}?include[]=avatar_url&include[]=enrollments&include[]=current_grading_period_scores`
      ).then(response => this.setState({user: response.data}))
      .catch(() => {})
    }

    loadAnalytics (studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/analytics/student_summaries?student_id=${studentId}`
      ).then(response => this.setState({analytics: response.data[0]}))
      .catch(() => {})
    }

    MAX_SUBMISSIONS = 10

    loadRecentlyGradedSubmissions (studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/students/submissions?student_ids[]=${studentId}&order=graded_at&order_direction=descending&include[]=assignment&per_page=20`
      ).then((result) => {
        const submissions = result.data
          .filter(s => s.grade != null)
          .slice(0, this.MAX_SUBMISSIONS)
        this.setState({submissions})
      })
      .catch(() => {})
    }

    setState (newState) {
      this.state = {...this.state, ...newState}
      if (typeof this.onChange === 'function') {
        this.onChange(this.state)
      }
    }
  }

  return StudentCardStore;
});
