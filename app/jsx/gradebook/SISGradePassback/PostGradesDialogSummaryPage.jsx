/** @jsx React.DOM */

define([
  'underscore',
  'i18n!modules',
  'react'
], (_, I18n, React) => {

  var PostGradesDialogSummaryPage = React.createClass({
    render () {
      return (
        <div
          className="post-summary text-center"
        >
          <h1
            className="lead"
          >
            <span className="assignments-to-post-count">
              {I18n.t('assignments_to_post', {
                 one: 'You are ready to post 1 assignment.',
                 other: 'You are ready to post %{count} assignments.'
              }, { count: this.props.postCount })}
            </span>
          </h1>

          <h4
            style={{color: "#AAAAAA"}}
          >
            {this.props.needsGradingCount > 0 ?
              <button
                className="btn btn-link"
                onClick={this.props.advanceToNeedsGradingPage}
              >
                {I18n.t('assignments_to_grade', {
                   one: '1 assignment has ungraded submissions',
                   other: '%{count} assignments have ungraded submissions'
                }, { count: this.props.needsGradingCount })}
              </button> : null}
          </h4>
          <form className="form-horizontal form-dialog form-inline">
            <div className="form-controls">
              <button
                type="button"
                className="btn btn-primary"
                onClick={ this.props.postGrades }
              >
                {I18n.t("Post Grades")}
              </button>
            </div>
          </form>

        </div>
      )
    }
  })

  return PostGradesDialogSummaryPage
})