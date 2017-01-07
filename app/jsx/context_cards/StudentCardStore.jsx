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
        analytics: {}
      };
    }

    getState() {
      return this.state;
    }

    loadDataForStudent() {
      Promise.all([
        this.loadCourse(this.courseId),
        this.loadUser(this.studentId, this.courseId),
        this.loadAnalytics(this.studentId, this.courseId),
        this.loadRecentlyGradedSubmissions(this.studentId, this.courseId)
      ]).then(() => this.setState({loading: false}))
    }

    loadCourse(courseId) {
      return axios.get(`/api/v1/courses/${courseId}?include[]=sections`)
        .then(response => this.setState({course: response.data}))
        .catch(() => {})
    }

    loadUser(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/users/${studentId}?include[]=avatar_url&include[]=enrollments`
      ).then(response => this.setState({user: response.data}))
      .catch(() => {})
    }

    loadAnalytics(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/analytics/student_summaries?student_id=${studentId}`
      ).then(response => this.setState({analytics: response.data[0]}))
      .catch(() => {})
    }

    loadRecentlyGradedSubmissions(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/students/submissions?student_ids[]=${studentId}&order=graded_at&order_direction=descending&include[]=assignment&per_page=20`
      ).then(result => {
        const submissions = result.data.filter(s => s.graded_at).slice(0, 10);
        this.setState({submissions});
      })
      .catch(() => {})
    }

    setState(newState) {
      this.state = {...this.state, ...newState};
      if (typeof this.onChange === "function") {
        this.onChange(this.state);
      }
    }
  }

  return StudentCardStore;
});
