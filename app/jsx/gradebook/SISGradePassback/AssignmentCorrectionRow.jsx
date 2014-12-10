/** @jsx React.DOM */

define([
  'underscore',
  'i18n!modules',
  'react',
  'jsx/gradebook/SISGradePassback/assignmentUtils'
], (_, I18n, React, assignmentUtils) => {

  var AssignmentCorrectionRow = React.createClass({
    componentDidMount() {
      this.initDueAtDateTimeField()
    },

    initDueAtDateTimeField() {
      var $picker = $(this.refs.due_at.getDOMNode())
      $picker.datetime_field().change((e) => {
        this.props.updateAssignment({due_at: $picker.data('date'), please_ignore: false})
      })
    },

    ignoreAssignment(e) {
      e.preventDefault()
      this.props.updateAssignment({please_ignore: true})
    },

    // The real 'change' event for due_at happens in initDueAtDateTimeField,
    // but we need to check a couple of things during keypress events to
    // maintain assignment state consistency
    checkDueAtChange(e) {
      if (e.target.value == "") {
        $picker = $(this.refs.due_at.getDOMNode()).data("date", null)
        this.props.updateAssignment({due_at: null})
      }
      // When a user edits the due_at datetime field, we should reset any
      // previous "please_ignore" request
      this.props.updateAssignment({please_ignore: false})
    },

    updateAssignmentName(e) {
      this.props.updateAssignment({name: e.target.value, please_ignore: false})
    },

    render() {
      var assignment = this.props.assignment;
      var assignmentList = this.props.assignmentList;
      var rowClass = React.addons.classSet({
        "row": true,
        "correction-row": true,
        "ignore-row": assignment.please_ignore
      })
      var nameTooLongError = assignmentUtils.nameTooLong(assignment) && !assignment.please_ignore
      var nameError = assignmentUtils.notUniqueName(assignmentList, assignment) && !assignment.please_ignore
      var dueAtError = !assignment.due_at && !assignment.please_ignore
      var anyError = nameError || dueAtError || nameTooLongError
      return (
        <div className={rowClass}>
          <div className="span3 input-container">
            {anyError || assignment.please_ignore ? null : <i className="success-mark icon-check" />}
            <div
              className={React.addons.classSet({
                "error-circle": nameError || nameTooLongError
              })}
            />
            <input
              ref="name"
              type="text"
              className="input-mlarge assignment-name"
              placeholder={I18n.t("No Assignment Name")}
              defaultValue={assignment.name}
              onChange={this.updateAssignmentName}
            />
            {nameError ? <div className="hint-text">The assignment name must be unique</div> : ""}
            {nameTooLongError ? <div className="hint-text">The name must be under 30 characters</div> : ""}
          </div>

          <div className="span2 date_field_container input-container">
            <button
              style={{visibility: assignment.please_ignore ? 'hidden' : ''}}
              className="btn btn-link btn-ignore"
              aria-label={I18n.t("Ignore Assignment")}
              title={I18n.t("Ignore Assignment")}
              onClick={this.ignoreAssignment}
            ><i className="icon-minimize" /></button>
            <div
              className={React.addons.classSet({
                "error-circle": dueAtError
              })}
            />
            <input
              ref="due_at"
              type="text"
              className="input-medium assignment-due-at"
              placeholder={assignment.due_at ? null : 'No Due Date'}
              defaultValue={assignment.due_at ? assignment.due_at.toString($.datetime.defaultFormat) : null}
              onChange={this.checkDueAtChange}
            />
          </div>
        </div>
      )
    }
  })

  return AssignmentCorrectionRow;
});