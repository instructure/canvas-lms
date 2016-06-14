define([
  'bower/reflux/dist/reflux',
  'react',
  'jquery',
  'underscore',
  'i18n!gradebook2',
  'compiled/grade_calculator',
  'jsx/gradebook/grid/constants',
  'compiled/gradebook2/gradeFormatter',
  '../../stores/gradebookToolbarStore',
  '../../stores/submissionsStore',
  '../../helpers/currentOrFinal',
], function (Reflux, React, $, _, I18n, GradeCalculator, GRADEBOOK_CONSTANTS,
             GradeFormatter, GradebookToolbarStore, SubmissionsStore, currentOrFinal) {

  function _generateGroupHasNoPointsWarning(groupNames) {
    return I18n.t({
      one: 'Score does not include %{groups} because it has no points possible',
      other: 'Score does not include %{groups} because they have no points possible'
    }, {
      groups: $.toSentence(groupNames),
      count: groupNames.length // TODO: delete me?
    });
  }

  var TotalColumn = React.createClass({
    propTypes: {
      rowData: React.PropTypes.object.isRequired
    },

    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions')
    ],

    assignments() {
      return _.flatten(_.pluck(this.assignmentGroups(), 'assignments'));
    },

    visibleAssignments() {
      return _.reject(this.assignments(), (a) =>
        _.contains(a.submission_types, 'not_graded'));
    },

    getWarning() {
      let result = '';

      if (this.anyMutedAssignments()) {
        result = I18n.t("This grade differs from the student's view of the grade because some assignments are muted");
      } else if (ENV.GRADEBOOK_OPTIONS.group_weighting_scheme === 'percent') {
        const invalidGroups = _.filter(this.assignmentGroups(), group  => group.shouldShowNoPointsWarning);

        if (invalidGroups.length > 0) {
          const groupNames = _.pluck(invalidGroups, 'name');
          result = _generateGroupHasNoPointsWarning(groupNames);
        }

      } else if (this.noPointsPossible()) {
        result = I18n.t("Can't compute score until an assignment has points possible");
      }

      return result;
    },

    anyMutedAssignments() {
      return _.any(this.visibleAssignments(), (va) => va.muted);
    },

    noPointsPossible() {
      const pointsPossible = _.inject(
        this.assignments(),
        (sum, a) => sum + (a.points_possible || 0), 0
      );

      return pointsPossible === 0;
    },

    iconClassNames() {
      let result = '';

      if (this.anyMutedAssignments()) {
        result = 'icon-muted final-warning';
      } else if (this.noPointsPossible()) {
        result = 'icon-warning final-warning';
      }

      return result;
    },

    submissions() {
      return SubmissionsStore.submissionsInCurrentPeriod(_.flatten(_.values(this.props.rowData.submissions)));
    },

    assignmentGroups() {
      return this.props.rowData.assignmentGroups;
    },

    assignmentGroupsForSubmissions() {
      return SubmissionsStore.assignmentGroupsForSubmissions(
        this.submissions(),
        this.assignmentGroups()
      );
    },

    totalGradeData() {
      const groupWeightingScheme = ENV.GRADEBOOK_OPTIONS.group_weighting_scheme;
      return GradeCalculator.calculate(
        this.submissions(),
        this.assignmentGroupsForSubmissions(),
        groupWeightingScheme
      );
    },

    toolbarOptions() {
      return this.state.toolbarOptions;
    },

    total() {
      return this.totalGradeData()[currentOrFinal(this.toolbarOptions())];
    },

    gradeFormatter() {
      const showPoints = this.toolbarOptions().showTotalGradeAsPoints,
            score = this.total().score,
            possible = this.total().possible;
      return new GradeFormatter(score, possible, showPoints);
    },

    render() {
      return (
        <div ref="cell" title={this.getWarning()}>
          <i ref="icon" className={this.iconClassNames()} />
          <span className="total-grade" ref="totalGrade">{ this.gradeFormatter().toString() }</span>
        </div>
      );
    }
  });

  return TotalColumn;
});
