/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'jsx/gradebook/SISGradePassback/assignmentUtils',
  'jsx/gradebook/SISGradePassback/PostGradesDialogCorrectionsPage',
  'jsx/gradebook/SISGradePassback/PostGradesDialogNeedsGradingPage',
  'jsx/gradebook/SISGradePassback/PostGradesDialogSummaryPage'
], (_, React, assignmentUtils,
    PostGradesDialogCorrectionsPage,
    PostGradesDialogNeedsGradingPage,
    PostGradesDialogSummaryPage) => {

  var PostGradesDialog = React.createClass({
    componentDidMount () {
      this.boundForceUpdate = this.forceUpdate.bind(this)
      this.props.store.addChangeListener(this.boundForceUpdate)
    },

    componentWillUnmount () {
      this.props.store.removeChangeListener(this.boundForceUpdate)
    },


    // Page advance callbacks
    advanceToNeedsGradingPage () {
      this.props.store.setState({ pleaseShowNeedsGradingPage: true })
    },

    leaveNeedsGradingPage () {
      this.props.store.setState({ pleaseShowNeedsGradingPage: false })
    },

    advanceToSummaryPage () {
      this.props.store.setState({ pleaseShowSummaryPage: true })
    },

    postGrades () {
      this.props.store.postGrades()
    },

    render () {
      var store = this.props.store
      var page = store.getPage()
      switch (page) {
        case "corrections":
          return (
            <PostGradesDialogCorrectionsPage
              store={this.props.store}
              advanceToSummaryPage={this.advanceToSummaryPage}
            /> ///
          )
        case "summary":
          var assignments = store.getState().assignments
          var postCount = assignmentUtils.notIgnored(assignments).length;
          var needsGradingCount = assignmentUtils.needsGrading(assignments).length;
          return (
            <PostGradesDialogSummaryPage
              postCount={postCount}
              needsGradingCount={needsGradingCount}
              advanceToNeedsGradingPage={this.advanceToNeedsGradingPage}
              postGrades={this.postGrades}
            /> ///
          )
        case "needsGrading":
          var assignments = store.getState().assignments
          var needsGrading = assignmentUtils.needsGrading(assignments);
          return (
            <PostGradesDialogNeedsGradingPage
              needsGrading={needsGrading}
              leaveNeedsGradingPage={this.leaveNeedsGradingPage}
            /> ///
          )
      }
    }
  });

  return PostGradesDialog;
});
