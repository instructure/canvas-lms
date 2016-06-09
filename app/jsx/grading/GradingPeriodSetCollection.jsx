define([
  'react',
  'underscore',
  'jquery',
  'i18n!grading_periods',
  'convert_case',
  'jsx/grading/GradingPeriodSet',
  'jsx/grading/SearchGradingPeriodsField',
  'jsx/shared/helpers/searchHelpers',
  'jsx/shared/helpers/dateHelper',
  'jsx/grading/EnrollmentTermsDropdown',
  'jsx/grading/NewGradingPeriodSetForm',
  'jsx/grading/EditGradingPeriodSetForm',
  'compiled/api/gradingPeriodSetsApi',
  'compiled/api/enrollmentTermsApi',
  'jquery.instructure_misc_plugins'
], function(React, _, $, I18n, ConvertCase, GradingPeriodSet, SearchGradingPeriodsField, SearchHelpers, DateHelper, EnrollmentTermsDropdown, NewGradingPeriodSetForm, EditGradingPeriodSetForm, setsApi, termsApi) {
  const deserializeSets = function(sets) {
    return _.map(sets, function(set) {
      let newSet = ConvertCase.camelize(set);
      newSet.id = set.id.toString();
      newSet.gradingPeriods = deserializePeriods(set.grading_periods);
      return newSet;
    });
  };

  const deserializePeriods = function(periods) {
    return _.map(periods, function(period) {
      let newPeriod = ConvertCase.camelize(period);
      newPeriod.id = period.id.toString();
      newPeriod.startDate = new Date(period.start_date);
      newPeriod.endDate = new Date(period.end_date);
      return newPeriod;
    });
  };

  const presentEnrollmentTerms = function(enrollmentTerms) {
    return _.map(enrollmentTerms, term => {
      let newTerm = _.extend({}, term);

      if (newTerm.name) {
        newTerm.displayName = newTerm.name;
      } else if (_.isDate(newTerm.startAt)) {
        let started = DateHelper.formatDateForDisplay(newTerm.startAt);
        newTerm.displayName = I18n.t("Term starting ") + started;
      } else {
        let created = DateHelper.formatDateForDisplay(newTerm.createdAt);
        newTerm.displayName = I18n.t("Term created ") + created;
      }

      return newTerm;
    });
  };

  const getShowGradingPeriodSetRef = function(set) {
    return "show-grading-period-set-" + set.id;
  };

  const getEditGradingPeriodSetRef = function(set) {
    return "edit-grading-period-set-" + set.id;
  };

  const setFocus = function(ref) {
    React.findDOMNode(ref).focus();
  };

  const { bool, string, shape } = React.PropTypes;

  let GradingPeriodSetCollection = React.createClass({
    propTypes: {
      readOnly: bool.isRequired,

      urls: shape({
        gradingPeriodSetsURL:    string.isRequired,
        gradingPeriodsUpdateURL: string.isRequired,
        enrollmentTermsURL:      string.isRequired,
        deleteGradingPeriodURL:  string.isRequired
      }).isRequired,
    },

    getInitialState() {
      return {
        enrollmentTerms: [],
        sets: [],
        showNewSetForm: false,
        searchText: "",
        selectedTermID: 0,
        editSet: {
          id:          null,
          saving:      false,
          wasExpanded: false
        }
      };
    },

    componentDidUpdate(prevProps, prevState) {
      if (prevState.editSet.id && (prevState.editSet.id !== this.state.editSet.id)) {
        let set = {id: prevState.editSet.id};
        this.refs[getShowGradingPeriodSetRef(set)].setState({expanded: prevState.editSet.wasExpanded});
        setFocus(this.refs[getShowGradingPeriodSetRef(set)].refs.editButton);
      }
    },

    addGradingPeriodSet(sets) {
      if (!this.props.readOnly) {
        this.setState({
          sets: this.state.sets.concat(deserializeSets(sets))
        }, this.getTerms());
      }
    },

    componentWillMount() {
      this.getSets();
      this.getTerms();
    },

    getSets() {
      setsApi.list()
        .then((sets) => {
          this.onSetsLoaded(sets);
        })
        .catch((_) => {
          $.flashError(I18n.t(
            "An error occured while fetching grading period sets."
          ));
        });
    },

    getTerms() {
      termsApi.list()
        .then((terms) => {
          this.onTermsLoaded(terms);
        })
        .catch((_) => {
           $.flashError(I18n.t(
             "An error occured while fetching enrollment terms."
           ));
        });
    },

    onTermsLoaded(terms) {
      this.setState({ enrollmentTerms: presentEnrollmentTerms(terms) });
    },

    onSetsLoaded(sets) {
      this.setState({ sets: sets });
    },

    onSetUpdated(updatedSet) {
      let sets = _.map(this.state.sets, (set) => {
        return (set.id === updatedSet.id) ? _.extend({}, set, updatedSet) : set;
      });
      this.setState({ sets: sets });
      this.getTerms();
      $.flashMessage(I18n.t("The grading period set was updated successfully."));
    },

    setAndGradingPeriodTitles(set) {
      let titles = _.pluck(set.gradingPeriods, 'title');
      titles.unshift(set.title);
      return _.compact(titles);
    },

    searchTextMatchesTitles(titles) {
      return _.any(titles, (title) => {
        return SearchHelpers
          .substringMatchRegex(this.state.searchText).test(title);
      });
    },

    filterSetsBySearchText(sets, searchText) {
      if (searchText === "") return sets;

      return _.filter(sets, (set) => {
        let titles = this.setAndGradingPeriodTitles(set);
        return this.searchTextMatchesTitles(titles);
      });
    },

    changeSearchText(searchText) {
      if (searchText !== this.state.searchText) {
        this.setState({ searchText: searchText });
      }
    },

    filterSetsByActiveTerm(sets, terms, selectedTermID) {
      if (selectedTermID === 0) return sets;

      const activeTerm = _.findWhere(terms, { id: selectedTermID });
      const setID = activeTerm.gradingPeriodGroupId;
      return _.where(sets, { id: setID.toString() });
    },

    changeSelectedEnrollmentTerm(event) {
      this.setState({ selectedTermID: parseInt(event.target.value) });
    },

    getVisibleSets() {
      let setsFilteredBySearchText =
        this.filterSetsBySearchText(this.state.sets, this.state.searchText);
      let filterByTermArgs = [
        setsFilteredBySearchText,
        this.state.enrollmentTerms,
        this.state.selectedTermID
      ];
      return this.filterSetsByActiveTerm(...filterByTermArgs);
    },

    editGradingPeriodSet(set) {
      let setComponent = this.refs[getShowGradingPeriodSetRef(set)];
      this.setState({ editSet: {id: set.id, saving: false, wasExpanded: setComponent.state.expanded }});
    },

    removeGradingPeriodSet(setID) {
      let newSets = _.reject(this.state.sets, set => set.id === setID);
      this.setState({ sets: newSets });
    },

    updateSetPeriods(setID, gradingPeriods) {
      let newSets = _.map(this.state.sets, (set) => {
        if (set.id === setID) {
          return _.extend({}, set, { gradingPeriods: gradingPeriods });
        }
        return set;
      });
      this.setState({ sets: newSets });
    },

    openNewSetForm() {
      this.setState({ showNewSetForm: true });
    },

    closeNewSetForm() {
      this.setState(
        { showNewSetForm: false },
        React.findDOMNode(this.refs.addSetFormButton).focus()
      );
    },

    closeEditSetForm(id) {
      this.setState({ editSet: {id: null, saving: false, wasExpanded: false }});
    },

    renderEditGradingPeriodSetForm(set) {
      let cancelCallback = () => {
        this.closeEditSetForm(set.id);
      };

      let saveCallback = (set) => {
        let editSet = _.extend({}, this.state.editSet, {saving: true});
        this.setState({editSet: editSet});
        setsApi.update(set)
               .then((updated) => {
                 this.onSetUpdated(updated);
                 this.closeEditSetForm(set.id);
               })
               .catch((_) => {
                 $.flashError(I18n.t(
                   "An error occured while updating the grading period set."
                 ));
               });
      };

      return (
        <EditGradingPeriodSetForm
          key             = {set.id}
          ref             = {getEditGradingPeriodSetRef(set)}
          set             = {set}
          enrollmentTerms = {this.state.enrollmentTerms}
          disabled        = {this.state.editSet.saving}
          onCancel        = {cancelCallback}
          onSave          = {saveCallback} />
      );
    },

    renderSets() {
      const urls = {
        batchUpdateURL: this.props.urls.gradingPeriodsUpdateURL,
        gradingPeriodSetsURL: this.props.urls.gradingPeriodSetsURL,
        deleteGradingPeriodURL: this.props.urls.deleteGradingPeriodURL
      };

      return _.map(this.getVisibleSets(), set => {
        if (this.state.editSet.id === set.id) {
          return this.renderEditGradingPeriodSetForm(set);
        } else {
          return (
            <GradingPeriodSet
              key             = {set.id}
              ref             = {getShowGradingPeriodSetRef(set)}
              set             = {set}
              gradingPeriods  = {set.gradingPeriods}
              urls            = {urls}
              actionsDisabled = {!!this.state.editSet.id}
              readOnly        = {this.props.readOnly}
              permissions     = {set.permissions}
              terms           = {this.state.enrollmentTerms}
              onEdit          = {this.editGradingPeriodSet}
              onDelete        = {this.removeGradingPeriodSet}
              onPeriodsChange = {this.updateSetPeriods}
            />
          );
        }
      });
    },

    renderNewGradingPeriodSetForm() {
      if (this.state.showNewSetForm) {
        return (
          <NewGradingPeriodSetForm
            ref                 = "newSetForm"
            closeForm           = {this.closeNewSetForm}
            urls                = {this.props.urls}
            enrollmentTerms     = {this.state.enrollmentTerms}
            addGradingPeriodSet = {this.addGradingPeriodSet}
          />
        );
      }
    },

    renderAddSetFormButton() {
      let disable = this.state.showNewSetForm || !!this.state.editSet.id;
      if (!this.props.readOnly) {
        return (
          <button
            ref            = 'addSetFormButton'
            className      = {disable ? 'Button Button--primary disabled' : 'Button Button--primary'}
            aria-disabled  = {disable}
            onClick        = {this.openNewSetForm}
          >
            <i className="icon-plus"/>
            &nbsp;
            {I18n.t("Set of Grading Periods")}
          </button>
        );
      }
    },

    render() {
      return (
        <div>
          <div className="GradingPeriodSets__toolbar header-bar no-line">
            <EnrollmentTermsDropdown
              terms={this.state.enrollmentTerms}
              changeSelectedEnrollmentTerm={this.changeSelectedEnrollmentTerm} />
            <SearchGradingPeriodsField changeSearchText={this.changeSearchText} />
            <div className="header-bar-right">
              {this.renderAddSetFormButton()}
            </div>
          </div>
          {this.renderNewGradingPeriodSetForm()}
          <div id="grading-period-sets">
            {this.renderSets()}
          </div>
        </div>
      );
    }
  });

  return GradingPeriodSetCollection;
});
