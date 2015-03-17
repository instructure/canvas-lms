/** @jsx React.DOM */

define([
  'underscore',
  'i18n!modules',
  'old_unsupported_dont_use_react'
], (_, I18n, React) => {

  var PostGradesDialogNeedsGradingPage = React.createClass({
    onClickRow(assignment_id) {
      window.location = "gradebook/speed_grader?assignment_id=" + assignment_id
    },

    render () {
      return (
        <div>
          <small>
            <em className="text-left" style={{color: "#555555"}}>
              {I18n.t("NOTE: Students have submitted work for these assignments" +
              "that has not been graded. If you post these grades now, you" +
              "will need to re-post their scores after grading their" +
              "latest submissions.")}
            </em>
          </small>
          <br/><br/>
          <table className="table table-hover table-condensed">
            <tbody>
              <thead>
                <td>{I18n.t("Assignment Name")}</td>
                <td>{I18n.t("Due Date")}</td>
                <td>{I18n.t("Ungraded Submissions")}</td>
              </thead>
              {this.props.needsGrading.map((a) => {
                return (
                  <tr
                    className="clickable-row"
                    onClick={this.onClickRow.bind(this, a.id)}
                  >
                    <td>{a.name}</td>
                    <td>{a.due_at.toString($.datetime.defaultFormat)}</td>
                    <td>{a.needs_grading_count}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
          <form className="form-horizontal form-dialog form-inline">
            <div className="form-controls">
              <button
                type="button"
                className="btn btn-primary"
                onClick={ this.props.leaveNeedsGradingPage }
              >
                {I18n.t("Continue")}&nbsp;<i className="icon-arrow-right" />
              </button>
            </div>
          </form>
        </div>
      )
    }
  })

  return PostGradesDialogNeedsGradingPage
})
