define([
  'react',
  'jquery',
  'underscore',
  'convert_case',
  'i18n!grading_periods',
  'jsx/grading/AccountGradingPeriod',
  'jsx/grading/GradingPeriodForm',
  'compiled/api/gradingPeriodsApi',
  'jquery.instructure_misc_helpers'
], function(React, $, _, ConvertCase, I18n, GradingPeriod, GradingPeriodForm, gradingPeriodsApi) {
  const types = React.PropTypes;

  const sortPeriods = function(periods) {
    return _.sortBy(periods, "startDate");
  };

  const anyPeriodsOverlap = function(periods) {
    if (_.isEmpty(periods)) {
      return false;
    }
    let firstPeriod = _.first(periods);
    let otherPeriods = _.rest(periods);
    let overlapping = _.some(otherPeriods, function(otherPeriod) {
      return otherPeriod.startDate < firstPeriod.endDate && firstPeriod.startDate < otherPeriod.endDate;
    });
    return overlapping || anyPeriodsOverlap(otherPeriods);
  };

  const isValidDate = function(date) {
    return Object.prototype.toString.call(date) === "[object Date]" &&
           !isNaN(date.getTime());
  };

  const validatePeriods = function(periods) {
    if (_.any(periods, (period) => { return !period.title })) {
      return [I18n.t('All grading periods must have a title')];
    }

    let validDates = _.all(periods, (period) => {
      return isValidDate(period.startDate) && isValidDate(period.endDate);
    });

    if (!validDates) {
      return [I18n.t('All dates fields must be present and formatted correctly')];
    }

    let orderedDates = _.all(periods, (period) => {
      return period.startDate < period.endDate;
    });

    if (!orderedDates) {
      return [I18n.t('All start dates must be before the end date')];
    }

    if (anyPeriodsOverlap(periods)) {
      return [I18n.t('Grading periods must not overlap')];
    }
  };

  const setFocus = function(ref) {
    React.findDOMNode(ref).focus();
  };

  const getShowGradingPeriodRef = function(period) {
    return "show-grading-period-" + period.id;
  };

  const getEditGradingPeriodRef = function(period) {
    return "edit-grading-period-" + period.id;
  };

  let GradingPeriodSet = React.createClass({
    propTypes: {
      set: types.shape({
        id: types.string,
        title: types.string
      }).isRequired,
      gradingPeriods: types.array.isRequired,
      terms: types.array.isRequired,
      urls:           types.shape({
        batchUpdateUrl: types.string.isRequired
      }).isRequired,
      readOnly: types.bool.isRequired,
      permissions: types.shape({
        read:   types.bool.isRequired,
        create: types.bool.isRequired,
        update: types.bool.isRequired,
        delete: types.bool.isRequired
      }).isRequired
    },

    getInitialState() {
      return {
        title: this.props.set.title,
        gradingPeriods: sortPeriods(this.props.gradingPeriods),
        expanded: this.props.expanded,
        newPeriod: {
          period: null,
          saving: false
        },
        editPeriod: {
          id:     null,
          saving: false
        },
        batchUpdateUrl: $.replaceTags(this.props.urls.batchUpdateUrl, 'set_id', this.props.set.id)
      };
    },

    componentDidUpdate(prevProps, prevState) {
      if (prevState.newPeriod.period && !this.state.newPeriod.period) {
        setFocus(this.refs.addPeriodButton);
      } else if (prevState.editPeriod.id && !this.state.editPeriod.id) {
        let period = {id: prevState.editPeriod.id};
        setFocus(this.refs[getShowGradingPeriodRef(period)].refs.editButton);
      }
    },

    toggleSetBody() {
      this.setState({ expanded: !this.state.expanded });
    },

    promptDeleteSet(e) {
      e.stopPropagation();
    },

    setTerms() {
      return _.filter(this.props.terms, (term) => {
        return term.gradingPeriodGroupId === parseInt(this.props.set.id);
      });
    },

    termNames() {
      const names = _.pluck(this.setTerms(), "displayName");
      return I18n.t("Terms: ") + names.join(", ");
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
      if(!this.state.expanded) return null;

      return (
        <div ref="setBody" className="ig-body">
          <div className="GradingPeriodList" ref="gradingPeriodList">
            {this.renderGradingPeriods()}
          </div>
          {this.renderNewPeriod()}
        </div>
      );
    },

    renderGradingPeriods() {
      let actionsDisabled = !!(this.state.editPeriod.id || this.state.newPeriod.period);
      return _.map(this.state.gradingPeriods, (period) => {
        if (period.id === this.state.editPeriod.id) {
          return (
            <div key       = {"edit-grading-period-" + period.id}
                 className = 'GradingPeriodList__period--editing pad-box'>
              <GradingPeriodForm ref      = "editPeriodForm"
                                 period   = {period}
                                 disabled = {this.state.editPeriod.saving}
                                 onSave   = {this.updatePeriod}
                                 onCancel = {this.cancelEditPeriod} />
            </div>
          );
        } else {
          return (
            <GradingPeriod key={"show-grading-period-" + period.id}
                           ref={getShowGradingPeriodRef(period)}
                           period={period}
                           actionsDisabled={actionsDisabled}
                           onEdit={this.editPeriod}
                           readOnly={this.props.readOnly}
                           permissions={this.props.permissions} />
          );
        }
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
            <div>
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
            <div className="EnrollmentTerms__list" tabIndex="0">
              {this.termNames()}
            </div>
          </div>
          {this.renderSetBody()}
        </div>
      );
    },

    renderNewPeriod() {
      if (this.props.permissions.create && !this.props.readOnly) {
        if (this.state.newPeriod.period) {
          return this.renderNewPeriodForm();
        } else {
          return this.renderNewPeriodButton();
        }
      }
    },

    renderNewPeriodButton() {
      return (
        <div className='GradingPeriodList__new-period center-md border-rbl border-round-b'>
          <button className='Button--link GradingPeriodList__new-period__add-button'
                  ref='addPeriodButton'
                  disabled={!!this.state.editPeriod.id}
                  aria-label={I18n.t('Add Grading Period')}
                  onClick={this.showNewPeriodForm}>
            <i className='icon-plus GradingPeriodList__new-period__add-icon'/>
            {I18n.t('Grading Period')}
          </button>
        </div>
      );
    },

    renderNewPeriodForm() {
      return (
        <div className='GradingPeriodList__new-period--editing border border-rbl border-round-b pad-box'>
          <GradingPeriodForm key      = 'new-grading-period'
                             ref      = 'newPeriodForm'
                             disabled = {this.state.newPeriod.saving}
                             onSave   = {this.saveNewPeriod}
                             onCancel = {this.removeNewPeriodForm} />
        </div>
      );
    },

    showNewPeriodForm() {
      this.setNewPeriod({period: {}});
    },

    saveNewPeriod(period) {
      let periods = this.state.gradingPeriods.concat([period]);
      let validations = validatePeriods(periods);
      if (_.isEmpty(validations)) {
        this.setNewPeriod({saving: true});
        gradingPeriodsApi.batchUpdate(this.props.set.id, periods)
             .then((periods) => {
               $.flashMessage(I18n.t('All changes were saved'));
               this.setState({
                 gradingPeriods: sortPeriods(periods)
               });
               this.removeNewPeriodForm();
             })
             .catch((_) => {
               $.flashError(I18n.t('There was a problem saving the grading period'));
               this.setNewPeriod({saving: false});
             });
      } else {
        _.each(validations, function(message) {
          $.flashError(message);
        });
      }
    },

    removeNewPeriodForm() {
      this.setNewPeriod({saving: false, period: null});
    },

    setNewPeriod(attr) {
      let period = $.extend(true, {}, this.state.newPeriod, attr);
      this.setState({newPeriod: period});
    },

    editPeriod(period) {
      this.setEditPeriod({id: period.id, saving: false});
    },

    updatePeriod(period) {
      let periods = _.reject(this.state.gradingPeriods, function(_period) {
        return period.id === _period.id;
      }).concat([period]);
      let validations = validatePeriods(periods);
      if (_.isEmpty(validations)) {
        this.setEditPeriod({ saving: true });
        gradingPeriodsApi.batchUpdate(this.props.set.id, periods)
             .then((periods) => {
               $.flashMessage(I18n.t('All changes were saved'));
               this.setEditPeriod({ id: null, saving: false });
               this.setState({
                 gradingPeriods: sortPeriods(periods)
               });
             })
             .catch((_) => {
               $.flashError(I18n.t('There was a problem saving the grading period'));
               this.setNewPeriod({saving: false});
             });
      } else {
        _.each(validations, function(message) {
          $.flashError(message);
        });
      }
    },

    cancelEditPeriod() {
      this.setEditPeriod({ id: null, saving: false });
    },

    setEditPeriod(attr) {
      let period = $.extend(true, {}, this.state.editPeriod, attr);
      this.setState({editPeriod: period});
    },
  });

  return GradingPeriodSet;
});
