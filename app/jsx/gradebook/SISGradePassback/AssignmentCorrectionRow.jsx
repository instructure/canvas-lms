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

    handleDateChanged(e) {
      //send date chosen in jquery date-picker so that
      //the assignment or assignment override due_at is set
      var $picker = $(this.refs.due_at.getDOMNode())
      this.props.onDateChanged($picker.data('date'))
    },

    initDueAtDateTimeField() {
      var $picker = $(this.refs.due_at.getDOMNode())
      $picker.datetime_field().change(this.handleDateChanged)
    },

    ignoreAssignment(e) {
      e.preventDefault()
      this.props.updateAssignment({please_ignore: true})
    },

    // The real 'change' event for due_at happens in initDueAtDateTimeField,
    // but we need to check a couple of things during keypress events to
    // maintain assignment state consistency
    checkDueAtChange(e) {
      if(this.props.assignment.overrideForThisSection != undefined) {
        if (e.target.value == "") {
          $picker = $(this.refs.due_at.getDOMNode()).data("date", null)
          this.props.assignment.due_at = null
        }
        // When a user edits the due_at datetime field, we should reset any
        // previous "please_ignore" request
        this.props.updateAssignment({please_ignore: false})
      }
      else {
        if (e.target.value == "") {
          $picker = $(this.refs.due_at.getDOMNode()).data("date", null)
          this.props.updateAssignment({due_at: null})
        }
        // When a user edits the due_at datetime field, we should reset any
        // previous "please_ignore" request
        this.props.updateAssignment({please_ignore: false})
      }

    },

    updateAssignmentName(e) {
      this.props.updateAssignment({name: e.target.value, please_ignore: false})
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
      var default_value = null
      var place_holder = null

      //dueAtError will always return true when assignments have overrides so we want to check and see if the
      //assignment override in the section has a due_at date
      if(assignment.overrideForThisSection != undefined && assignment.overrideForThisSection.due_at != null){
        dueAtError = false
      }

      //handles data being filled in the inputs if there are name issues on an assignment with an assignment override
      if(assignment.overrideForThisSection != undefined){
        default_value = $.datetimeString(assignment.overrideForThisSection.due_at, {format: 'medium'})
        place_holder = assignment.overrideForThisSection.due_at ? null : I18n.t('No Due Date')
      }
      else{
        default_value = $.datetimeString(assignment.due_at, {format: 'medium'})
        place_holder = assignment.due_at ? null : I18n.t("No Due Date")
      }
      var anyError = nameError || dueAtError || nameTooLongError
      return (
        <div className={rowClass}>
          <div className="span3 input-container">
            {anyError || assignment.please_ignore ? null : <i className="success-mark icon-check" />}
            <div
              className={React.addons.classSet({
                "error-circle": nameError || nameTooLongError
              })}
            >
              <label className="screenreader-only">{I18n.t("Name Error")}</label>
            </div>
            <input
              ref="name"
              type="text"
              aria-label={I18n.t("Assignment Name")}
              className="input-mlarge assignment-name"
              placeholder={assignment.name ? null : I18n.t("No Assignment Name")}
              defaultValue={assignment.name}
              onChange={this.updateAssignmentName}
            />
            {nameError ? <div className="hint-text">The assignment name must be unique</div> : ""}
            {nameTooLongError ? <div className="hint-text">The name must be under 30 characters</div> : ""}
          </div>

          <div className="span2 date_field_container input-container assignment_correction_input">
            <div
              className={React.addons.classSet({
                "error-circle": dueAtError
              })}
            >
              <label className="screenreader-only">{I18n.t("Date Error")}</label>
            </div>
            <input
              ref="due_at"
              type="text"
              aria-label={I18n.t("Due Date")}
              className="input-medium assignment-due-at"
              placeholder={place_holder}
              defaultValue={default_value}
              onChange={this.checkDueAtChange}
            />
            <button
              style={{visibility: assignment.please_ignore ? 'hidden' : ''}}
              className="btn btn-link btn-ignore assignment_correction_ignore"
              aria-label={I18n.t("Ignore %{name}", {name: assignment.name})}
              title={I18n.t("Ignore Assignment")}
              onClick={this.ignoreAssignment}
            ><i className="icon-minimize" /></button>
          </div>
        </div>
      )
    }
  })

  return AssignmentCorrectionRow;
});
