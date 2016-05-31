define([
  'react',
  'underscore',
  'jquery',
  'axios',
  'i18n!grading_periods',
  'convert_case',
  'jsx/grading/GradingPeriodSet',
  'jsx/grading/SearchGradingPeriodsField',
  'jsx/grading/EnrollmentTermsDropdown',
  'jsx/shared/helpers/searchHelpers',
  'jsx/gradebook/grid/helpers/datesHelper'
], function(React, _, $, axios, I18n, ConvertCase, GradingPeriodSet, SearchGradingPeriodsField, EnrollmentTermsDropdown, SearchHelpers, DatesHelper) {

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
        let started = DatesHelper.formatDateForDisplay(newTerm.startAt);
        newTerm.displayName = I18n.t("Term starting ") + started;
      } else {
        let created = DatesHelper.formatDateForDisplay(newTerm.createdAt);
        newTerm.displayName = I18n.t("Term created ") + created;
      }

      return newTerm;
    });
  };

  const types = React.PropTypes;

  let GradingPeriodSetCollection = React.createClass({
    propTypes: {
      readOnly: types.bool.isRequired,
      urls: types.shape({
        gradingPeriodSetsURL:    types.string.isRequired,
        gradingPeriodsUpdateURL: types.string.isRequired,
        enrollmentTermsURL: types.string.isRequired
      }).isRequired
    },

    getInitialState() {
      return {
        enrollmentTerms: [],
        sets: [],
        searchText: "",
        selectedTermID: 0
      };
    },

    componentWillMount() {
      this.getTerms();
      this.getSets();
    },

    getSets() {
      axios.get(this.props.urls.gradingPeriodSetsURL)
           .then((response) => {
              this.setState({
                sets: deserializeSets(response.data.grading_period_sets)
              });
            })
            .catch((_) => {
              $.flashError(I18n.t("An error occured while fetching grading period sets."));
            });
    },

    getTerms() {
      axios.get(this.props.urls.enrollmentTermsURL)
           .then((response) => {
              const enrollmentTerms = deserializeEnrollmentTerms(response.data.enrollment_terms);
              this.setState({ enrollmentTerms: enrollmentTerms });
            })
           .catch(function (response) {
              $.flashError(I18n.t("An error occured while fetching enrollment terms."));
            });
     },

    setAndGradingPeriodTitles(set) {
      let titles = _.pluck(set.gradingPeriods, 'title');
      titles.unshift(set.title);
      return _.compact(titles);
    },

    searchTextMatchesTitles(titles) {
      return _.any(titles, (title) => {
        return SearchHelpers.substringMatchRegex(this.state.searchText).test(title);
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
      let setsFilteredBySearchText = this.filterSetsBySearchText(this.state.sets, this.state.searchText);
      let filterByTermArgs = [setsFilteredBySearchText, this.state.enrollmentTerms, this.state.selectedTermID];
      return this.filterSetsByActiveTerm(...filterByTermArgs);
    },

    renderSets() {
      const urls = { batchUpdateUrl: this.props.urls.gradingPeriodsUpdateURL };
      let visibleSets = this.getVisibleSets();
      return _.map(visibleSets, set => {
        return (
          <GradingPeriodSet key={set.id}
                            set={set}
                            gradingPeriods={set.gradingPeriods}
                            urls={urls}
                            readOnly={this.props.readOnly}
                            permissions={set.permissions}
                            terms={this.state.enrollmentTerms} />
        );
      });
    },

    render() {
      return (
        <div>
          <div className="GradingPeriodSets__toolbar header-bar no-line">
            <EnrollmentTermsDropdown
              terms={this.state.enrollmentTerms}
              changeSelectedEnrollmentTerm={this.changeSelectedEnrollmentTerm} />
            <SearchGradingPeriodsField changeSearchText={this.changeSearchText} />
          </div>
          <div>
            {this.renderSets()}
          </div>
        </div>
      );
    }
  });

  return GradingPeriodSetCollection;
});
