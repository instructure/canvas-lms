define(['axios'], (axios) => {
  class StudentCardStore {
    constructor(studentId, courseId) {
      this.state = {
        loading: true,
        user: {},
        course: {},
        submissions: [],
        analytics: {}
      };
      this.loadDataForStudent(studentId, courseId);
    }

    getState() {
      return this.state;
    }

    loadDataForStudent(studentId, courseId) {
      Promise.all([
        this.loadCourse(courseId),
        this.loadUser(studentId, courseId),
        this.loadAnalytics(studentId, courseId),
        this.loadRecentlyGradedSubmissions(studentId, courseId)
      ]).then(() => this.setState({loading: false}))
    }

    loadCourse(courseId) {
      return axios.get(`/api/v1/courses/${courseId}`)
        .then(response => this.setState({course: response.data}))
    }

    loadUser(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/users/${studentId}?include[]=avatar_url&include[]=enrollments`
      ).then(response => this.setState({user: response.data}))
    }

    loadAnalytics(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/analytics/student_summaries?student_id=${studentId}`
      ).then(response => this.setState({analytics: response.data[0]}))
    }

    loadRecentlyGradedSubmissions(studentId, courseId) {
      return axios.get(
        `/api/v1/courses/${courseId}/students/submissions?student_ids[]=${studentId}&order=graded_at&order_direction=descending&include[]=assignment&per_page=20`
      ).then(result => {
        const submissions = result.data.filter(s => s.graded_at).slice(0, 10);
        this.setState({submissions});
      });
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
