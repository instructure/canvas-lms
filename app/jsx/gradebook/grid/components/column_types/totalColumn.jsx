/** @jsx React.DOM */
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

  function generateGroupHasNoPointsWarning(groupNames) {
    return I18n.t({
      one: 'Score does not include %{groups} because it has no points possible',
      other: 'Score does not include %{groups} becuase they have no points possible'
    }, {
      groups: $.toSentence(groupNames),
      count: groupNames.length
    });
  }

  var TotalColumn = React.createClass({
    propTypes: {
      rowData: React.PropTypes.object.isRequired
    },

    mixins: [
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions')
    ],

    statics: {
      displayWarning: null,

      getWarning(assignmentGroups) {
        if (!_.isNull(TotalColumn.displayWarning)) {
          return TotalColumn.displayWarning;
        }

        if (ENV.GRADEBOOK_OPTIONS.group_weighting_scheme === 'percent') {
          var invalidGroups = _.filter(assignmentGroups, group  => group.shouldShowNoPointsWarning);

          if (invalidGroups.length > 0) {
            var groupNames = _.pluck(invalidGroups, 'name');
            TotalColumn.displayWarning = generateGroupHasNoPointsWarning(groupNames);
          }
        } else {
          var assignments = _.flatten(_.pluck(assignmentGroups, 'assignments')),
              pointsPossible = _.inject(assignments, (sum, a) => (a.points_possible || 0), 0);

          if (pointsPossible === 0) {
            TotalColumn.displayWarning = I18n.t("Can't compute score until an assignment has points possible");
          }
        }

        if (_.isNull(TotalColumn.displayWarning)) TotalColumn.displayWarning = "";
        return TotalColumn.displayWarning;
      }
    },

    render() {
      var submissions, assignmentGroups, assignmentGroupsForSubmissions,
          groupWeightingScheme, totalGradeData, gradeFormatter, total, toolbarOptions,
          showPoints;

      submissions = this.props.rowData.submissions;
      submissions = SubmissionsStore.submissionsInCurrentPeriod(submissions);

      assignmentGroups = this.props.rowData.assignmentGroups;
      assignmentGroupsForSubmissions = SubmissionsStore.assignmentGroupsForSubmissions(submissions,
                                                                                       assignmentGroups);
      groupWeightingScheme = ENV.GRADEBOOK_OPTIONS.group_weighting_scheme;
      totalGradeData = GradeCalculator.calculate(submissions, assignmentGroupsForSubmissions,
                                                 groupWeightingScheme);
      toolbarOptions = this.state.toolbarOptions;
      showPoints = toolbarOptions.showTotalGradeAsPoints;
      total = totalGradeData[currentOrFinal(toolbarOptions)];

      gradeFormatter = new GradeFormatter(total.score, total.possible, showPoints);
      return (
        <div className='gradebook-cell' ref="cell" title={TotalColumn.getWarning(assignmentGroups)}>
          { TotalColumn.getWarning(assignmentGroups) && <i ref="icon" className='icon-warning final-warning' />}
          <span ref="totalGrade">{ gradeFormatter.toString() }</span>
        </div>
      );
    }
  });

  return TotalColumn;
});
