define([
  'react',
  'jquery',
  'underscore',
  'axios',
  'convert_case',
  'i18n!grading_periods',
  'jsx/grading/AccountGradingPeriod',
  'jsx/grading/GradingPeriodForm',
  'compiled/api/gradingPeriodsApi',
  'jquery.instructure_misc_helpers'
], function(React, $, _, axios, ConvertCase, I18n, GradingPeriod, GradingPeriodForm, gradingPeriodsApi) {

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
    if (_.any(periods, (period) => { return !(period.title || "").trim() })) {
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

  const isEditingPeriod = function(state) {
    return !!state.editPeriod.id;
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

  const { shape, number, string, array, bool, func } = React.PropTypes;

  let GradingPeriodSet = React.createClass({
    propTypes: {
      gradingPeriods:  array.isRequired,
      terms:           array.isRequired,
      readOnly:        bool.isRequired,
      expanded:        bool,
      actionsDisabled: bool,
      onEdit:          func.isRequired,
      onDelete:        func.isRequired,
      onPeriodsChange: func.isRequired,
      onToggleBody:    func.isRequired,

      set: shape({
        id:    string.isRequired,
        title: string.isRequired
      }).isRequired,

      urls: shape({
        batchUpdateURL: string.isRequired,
        deleteGradingPeriodURL: string.isRequired,
        gradingPeriodSetsURL: string.isRequired
      }).isRequired,

      permissions: shape({
        read:   bool.isRequired,
        create: bool.isRequired,
        update: bool.isRequired,
        delete: bool.isRequired
      }).isRequired
    },

    getInitialState() {
      return {
        title: this.props.set.title,
        gradingPeriods: sortPeriods(this.props.gradingPeriods),
        newPeriod: {
          period: null,
          saving: false
        },
        editPeriod: {
          id:     null,
          saving: false
        }
      };
    },

    componentDidUpdate(prevProps, prevState) {
      if (prevState.newPeriod.period && !this.state.newPeriod.period) {
        setFocus(this.refs.addPeriodButton);
      } else if (isEditingPeriod(prevState) && !isEditingPeriod(this.state)) {
        let period = { id: prevState.editPeriod.id };
        setFocus(this.refs[getShowGradingPeriodRef(period)].refs.editButton);
      }
    },

    toggleSetBody() {
      if (!isEditingPeriod(this.state)) {
        this.props.onToggleBody();
      }
    },

    promptDeleteSet(event) {
      event.stopPropagation();
      const confirmMessage = I18n.t("Are you sure you want to delete this grading period set?");
      if (!window.confirm(confirmMessage)) return null;

      const url = this.props.urls.gradingPeriodSetsURL + "/" + this.props.set.id;
      axios.delete(url)
           .then(() => {
             $.flashMessage(I18n.t('The grading period set was deleted'));
             this.props.onDelete(this.props.set.id);
           })
           .catch(() => {
             $.flashError(I18n.t("An error occured while deleting the grading period set"));
           });
    },

    setTerms() {
      return _.where(this.props.terms, { gradingPeriodGroupId: this.props.set.id });
    },

    termNames() {
      const names = _.pluck(this.setTerms(), "displayName");
      return I18n.t("Terms: ") + names.join(", ");
    },

    editSet(e) {
      e.stopPropagation();
      this.props.onEdit(this.props.set);
    },

    changePeriods(periods) {
      let sortedPeriods = sortPeriods(periods);
      this.setState({ gradingPeriods: sortedPeriods });
      this.props.onPeriodsChange(this.props.set.id, sortedPeriods);
    },

    removeGradingPeriod(idToRemove) {
      let periods = _.reject(this.state.gradingPeriods, period => period.id === idToRemove);
      this.setState({ gradingPeriods: periods });
    },

    showNewPeriodForm() {
      this.setNewPeriod({ period: {} });
    },

    saveNewPeriod(period) {
      let periods = this.state.gradingPeriods.concat([period]);
      let validations = validatePeriods(periods);
      if (_.isEmpty(validations)) {
        this.setNewPeriod({saving: true});
        gradingPeriodsApi.batchUpdate(this.props.set.id, periods)
             .then((periods) => {
               $.flashMessage(I18n.t('All changes were saved'));
               this.removeNewPeriodForm();
               this.changePeriods(periods);
             })
             .catch((_) => {
               $.flashError(I18n.t('There was a problem saving the grading period'));
               this.setNewPeriod({ saving: false });
             });
      } else {
        _.each(validations, function(message) {
          $.flashError(message);
        });
      }
    },

    removeNewPeriodForm() {
      this.setNewPeriod({ saving: false, period: null });
    },

    setNewPeriod(attr) {
      let period = $.extend(true, {}, this.state.newPeriod, attr);
      this.setState({ newPeriod: period });
    },

    editPeriod(period) {
      this.setEditPeriod({ id: period.id, saving: false });
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
               this.changePeriods(periods);
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
      this.setState({ editPeriod: period });
    },

    renderEditButton() {
      if (!this.props.readOnly && this.props.permissions.update) {
        let disabled = !!(this.props.actionsDisabled || isEditingPeriod(this.state));
        let baseClasses = 'Button Button--icon-action edit_grading_period_set_button';
        return (
          <button ref="editButton"
                  className={baseClasses + (disabled ? " disabled" : "")}
                  aria-disabled={disabled}
                  type="button"
                  onClick={this.editSet}>
            <span className="screenreader-only">{I18n.t("Edit Grading Period Set")}</span>
            <i className="icon-edit"/>
          </button>
        );
      }
    },

    renderDeleteButton() {
      if (!this.props.readOnly && this.props.permissions.delete) {
        let disabled = !!(this.props.actionsDisabled || isEditingPeriod(this.state));
        let baseClasses = 'Button Button--icon-action delete_grading_period_set_button';
        return (
          <button ref="deleteButton"
                  className={baseClasses + (disabled ? " disabled" : "")}
                  aria-disabled={disabled}
                  type="button"
                  onClick={this.promptDeleteSet}>
            <span className="screenreader-only">{I18n.t("Delete Grading Period Set")}</span>
            <i className="icon-trash"/>
          </button>
        );
      }
    },

    renderEditAndDeleteButtons() {
      return (
        <div className="ItemGroup__header__admin">
          {this.renderEditButton()}
          {this.renderDeleteButton()}
        </div>
      );
    },

    renderSetBody() {
      if (!this.props.expanded) return null;

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
      let actionsDisabled = !!(this.props.actionsDisabled || isEditingPeriod(this.state) || this.state.newPeriod.period);
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
                           onDelete={this.removeGradingPeriod}
                           deleteGradingPeriodURL={this.props.urls.deleteGradingPeriodURL}
                           permissions={this.props.permissions} />
          );
        }
      });
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
      let disabled = !!(this.props.actionsDisabled || isEditingPeriod(this.state));
      let classList = 'Button Button--link GradingPeriodList__new-period__add-button' + (disabled ? " disabled" : "");
      return (
        <div className='GradingPeriodList__new-period center-xs border-rbl border-round-b'>
          <button className={classList}
                  ref='addPeriodButton'
                  aria-disabled={disabled}
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

    render() {
      const setStateSuffix = this.props.expanded ? "expanded" : "collapsed";
      const arrow = this.props.expanded ? "down" : "right";
      return (
        <div className={"GradingPeriodSet--" + setStateSuffix}>
          <div className="ItemGroup__header"
               ref="toggleSetBody"
               onClick={this.toggleSetBody}>
            <div>
              <div className="ItemGroup__header__title">
                <button className={"Button Button--icon-action GradingPeriodSet__toggle"}
                        aria-expanded={this.props.expanded}
                        aria-label="Toggle grading period visibility">
                  <i className={"icon-mini-arrow-" + arrow}/>
                </button>
                <span className="screenreader-only">{I18n.t("Grading period title")}</span>
                <h2 ref="title" tabIndex="0" className="GradingPeriodSet__title">
                  {this.props.set.title}
                </h2>
              </div>
              {this.renderEditAndDeleteButtons()}
            </div>
            <div className="EnrollmentTerms__list" tabIndex="0">
              {this.termNames()}
            </div>
          </div>
          {this.renderSetBody()}
        </div>
      );
    }
  });

  return GradingPeriodSet;
});
