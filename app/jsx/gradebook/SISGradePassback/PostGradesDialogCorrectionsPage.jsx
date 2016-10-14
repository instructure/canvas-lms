define([
  'underscore',
  'i18n!modules',
  'react',
  'jsx/gradebook/SISGradePassback/assignmentUtils',
  'jsx/gradebook/SISGradePassback/AssignmentCorrectionRow'
], (_, I18n, React, assignmentUtils, AssignmentCorrectionRow) => {

  var PostGradesDialogCorrectionsPage = React.createClass({
    componentDidMount () {
      this.props.store.addChangeListener(this.handleStoreChange);
    },

    componentWillUnmount () {
      this.props.store.removeChangeListener(this.handleStoreChange);
    },

    handleStoreChange () {
      this.setState(this.props.store.getState());
    },

    ignoreErrors () {
      var assignments = assignmentUtils.withErrors(this.props.store.getAssignments())
      _.each(assignments, (a) => this.props.store.updateAssignment(a.id, {please_ignore: true}) )  
    },

    ignoreErrorsThenProceed () {
      this.ignoreErrors()
      this.props.store.saveAssignments()
      this.props.advanceToSummaryPage()
    },

    invalidAssignmentsForCorrection(assignments){
      var original_error_assignments = assignmentUtils.withOriginalErrors(assignments, this.props.store)
      var invalid_assignments = []
      _.each(assignments, (a) => {
        if(original_error_assignments.length > 0 && this.props.store.validCheck(a)){ return }
        else if(original_error_assignments.length == 0 && this.props.store.validCheck(a)){ return }
        else{ invalid_assignments.push(a) }
      });
      return invalid_assignments
    },

    render () {
      var assignments = _.filter(this.props.store.getAssignments(), (a) => {
        return a.overrides == undefined || a.overrides.length == 0 || (a.overrideForThisSection != undefined) || a.selectedSectionForEveryone != undefined || (a.selectedSectionForEveryone == undefined && a.currentlySelected.type == 'course')
      });
      var errorCount = Object.keys(assignmentUtils.withErrors(assignments)).length;
      var store = this.props.store;
      var correctionRow = this.invalidAssignmentsForCorrection(assignments)
      var originalErrorAssignments = assignmentUtils.withOriginalErrors(assignments, this.props.store)

      var assignmentRow;
      if(originalErrorAssignments.length != 0){
        assignmentRow = originalErrorAssignments
      }else if(correctionRow.length != 0){
        assignmentRow = correctionRow
      }else if(errorCount == 0 && correctionRow.length == 0 && originalErrorAssignments.length == 0){
        assignmentRow = []
      }
      else{
        assignmentRow = []
      }

      return (
        <div id="assignment-errors">
          <form className="form-horizontal form-dialog form-inline">
            <div className="form-dialog-content">
              <legend className="lead">
                {
                  I18n.t({
                    zero: "No Assignments with Errors, Click Continue",
                    one: '1 Assignment with Errors',
                    other: '%{count} Assignments with Errors'
                  }, { count: errorCount })
                }
              </legend>
              <div className="row title-row">
                <h5 className="muted span3" aria-hidden="true">{I18n.t("Assignment Name")}</h5>
                <h5 className="muted span2" aria-hidden="true">{I18n.t("Due Date")}</h5>
              </div>

              {assignmentRow.map((a) => {
                return (
                  <AssignmentCorrectionRow
                    assignment={ a }
                    assignmentList={ assignments }
                    updateAssignment={ store.updateAssignment.bind(store, a.id)}
                    onDateChanged={store.updateAssignmentDate.bind(store, a.id)}
                    store={store}
                  />
                )
              })}
            </div>
            <div className="form-controls">
              <button
                type="button"
                className="btn btn-primary"
                onClick={ this.ignoreErrorsThenProceed }
              >
                {errorCount > 0 ? I18n.t("Ignore These") : I18n.t("Continue")}
                &nbsp;<i className="icon-arrow-right" />
              </button>
            </div>
          </form>
        </div>
      )
    }
  });

  return PostGradesDialogCorrectionsPage;
});
