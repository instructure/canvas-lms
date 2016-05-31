define([
  'react',
  'underscore',
  'jquery',
  'axios',
  'i18n!grading_periods',
  'convert_case',
  'jsx/grading/GradingPeriodSet',
  'jsx/grading/SearchGradingPeriodsField',
  'jsx/shared/helpers/searchHelpers',
  'jsx/shared/helpers/dateHelper',
  'jsx/grading/EnrollmentTermsDropdown',
  'jsx/grading/NewGradingPeriodSetForm',
  'jquery.instructure_misc_plugins'
], function(React, _, $, axios, I18n, ConvertCase, GradingPeriodSet, SearchGradingPeriodsField, SearchHelpers, DateHelper, EnrollmentTermsDropdown, NewGradingPeriodSetForm ) {

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

  const deserializeEnrollmentTerms = function(enrollmentTerms) {
    return _.map(enrollmentTerms, term => {
      let newTerm = ConvertCase.camelize(term);
      if(term.start_at) newTerm.startAt = new Date(term.start_at);
      if(term.end_at) newTerm.endAt = new Date(term.end_at);
      if(term.created_at) newTerm.createdAt = new Date(term.created_at);

      if(newTerm.name) {
        newTerm.displayName = newTerm.name;
      } else if(_.isDate(newTerm.startAt)) {
        let started = DateHelper.formatDateForDisplay(newTerm.startAt);
        newTerm.displayName = I18n.t("Term starting ") + started;
      } else {
        let created = DateHelper.formatDateForDisplay(newTerm.createdAt);
        newTerm.displayName = I18n.t("Term created ") + created;
      }

      return newTerm;
    });
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
        selectedTermID: 0
      };
    },

    addGradingPeriodSet(sets) {
      if(!this.props.readOnly) {
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
      axios.get(this.props.urls.gradingPeriodSetsURL)
        .then((response) => {
          this.setState({
            sets: deserializeSets(response.data.grading_period_sets)
          });
        })
        .catch((_) => {
          $.flashError(I18n.t(
                "An error occured while fetching grading period sets."
          ));
        });
    },

    getTerms() {
      axios.get(this.props.urls.enrollmentTermsURL)
        .then((response) => {
           const enrollmentTerms =
             deserializeEnrollmentTerms(response.data.enrollment_terms);
           this.setState({ enrollmentTerms: enrollmentTerms });
         })
        .catch(function (response) {
           $.flashError(I18n.t(
                 "An error occured while fetching enrollment terms."
           ));
         });
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

    removeGradingPeriodSet(setID) {
      let newSets = _.reject(this.state.sets, set => set.id === setID);
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

    renderSets() {
      const urls = {
        batchUpdateURL: this.props.urls.gradingPeriodsUpdateURL,
        gradingPeriodSetsURL: this.props.urls.gradingPeriodSetsURL,
        deleteGradingPeriodURL: this.props.urls.deleteGradingPeriodURL
      };

      return _.map(this.getVisibleSets(), set => {
        return (
          <GradingPeriodSet key={set.id}
                            set={set}
                            gradingPeriods={set.gradingPeriods}
                            urls={urls}
                            readOnly={this.props.readOnly}
                            permissions={set.permissions}
                            terms={this.state.enrollmentTerms}
                            onDelete={this.removeGradingPeriodSet} />
        );
      });
    },

    renderNewGradingPeriodSetForm() {
      if(!this.state.showNewSetForm) return;
      return (
        <NewGradingPeriodSetForm
          ref                 = "newSetForm"
          closeForm           = {this.closeNewSetForm}
          urls                = {this.props.urls}
          enrollmentTerms     = {this.state.enrollmentTerms}
          addGradingPeriodSet = {this.addGradingPeriodSet}
        />
      );
    },

    renderAddSetFormButton() {
      if(this.props.readOnly) return;
      return (
        <button
          ref       = 'addSetFormButton'
          className = {this.state.showNewSetForm ? 'Button Button--primary disabled' : 'Button Button--primary'}
          aria-disabled  = {this.state.showNewSetForm}
          onClick   = {this.openNewSetForm}
        >
          <i className="icon-plus"/>
          &nbsp;
          {I18n.t("Set of Grading Periods")}
        </button>
      );
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
