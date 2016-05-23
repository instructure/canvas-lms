define([
  'react',
  'underscore',
  'i18n!grading_periods',
  'jsx/grading/AccountGradingPeriod'
], function(React, _, I18n, GradingPeriod) {
  const types = React.PropTypes;

  const sortPeriods = function(periods) {
    return _.sortBy(periods, "startDate");
  };

  let GradingPeriodSet = React.createClass({
    propTypes: {
      set: types.shape({
        id: types.string,
        title: types.string.isRequired
      }).isRequired,
      gradingPeriods: types.array.isRequired
    },

    getInitialState() {
      return { expanded: true };
    },

    toggleSetBody() {
      this.setState({ expanded: !this.state.expanded });
    },

    promptDeleteSet(e) {
      e.stopPropagation();
    },

    editSet(e) {
      e.stopPropagation();
    },

    renderEditAndDeleteIcons() {
      return (
        <div className="ItemGroup__header__admin">
          <button ref="editButton"
                  className="Button Button--icon-action edit_grading_period_set_button"
                  type="button"
                  onClick={this.editSet}>
            <span className="screenreader-only">{I18n.t("Edit Grading Period Set")}</span>
            <i className="icon-edit"/>
          </button>
          <button ref="deleteButton"
                  className="Button Button--icon-action delete_grading_period_set_button"
                  type="button"
                  onClick={this.promptDeleteSet}>
             <span className="screenreader-only">{I18n.t("Delete Grading Period Set")}</span>
            <i className="icon-trash"/>
          </button>
        </div>
      );
    },

    renderSetBody() {
      return (
        <div ref="setBody" className="ig-body">
          <div className="GradingPeriodList" ref="gradingPeriodList">
            {this.renderGradingPeriods()}
          </div>
        </div>
      );
    },

    renderGradingPeriods() {
      const sortedPeriods = sortPeriods(this.props.gradingPeriods);
      return _.map(sortedPeriods, function(period) {
        return (
          <GradingPeriod key={period.id} period={period} />
        );
      });
    },

    render() {
      const setStateSuffix = this.state.expanded ? "expanded" : "collapsed";
      const arrow = this.state.expanded ? "down" : "right";
      return (
        <div className={"GradingPeriodSet--" + setStateSuffix}>
          <div className="ItemGroup__header"
               ref="toggleSetBody"
               onClick={this.toggleSetBody}>
            <div className="ItemGroup__header__title">
              <button className={"Button Button--icon-action GradingPeriodSet__toggle"}
                      aria-expanded={this.state.expanded}
                      aria-label="Toggle grading period visibility">
                <i className={"icon-mini-arrow-" + arrow}/>
              </button>
              <span className="screenreader-only">{I18n.t("Grading period title")}</span>
              <h2 tabIndex="0" className="GradingPeriodSet__title">
                {this.props.set.title}
              </h2>
            </div>
            {this.renderEditAndDeleteIcons()}
          </div>
          {this.state.expanded && this.renderSetBody()}
        </div>
      );
    }
  });

  return GradingPeriodSet;
});
