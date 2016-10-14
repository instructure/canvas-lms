define([
  'react',
  'underscore',
  'jquery',
  'instructure-ui/Button',
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
], function(React, _, $, { default: Button }, I18n, ConvertCase, GradingPeriodSet, SearchGradingPeriodsField, SearchHelpers, DateHelper, EnrollmentTermsDropdown, NewGradingPeriodSetForm, EditGradingPeriodSetForm, SetsApi, TermsApi) {

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
        expandedSetIDs: [],
        showNewSetForm: false,
        searchText: "",
        selectedTermID: "0",
        editSet: {
          id:     null,
          saving: false
        }
      };
    },

    componentDidUpdate(prevProps, prevState) {
      if (prevState.editSet.id && (prevState.editSet.id !== this.state.editSet.id)) {
        let set = {id: prevState.editSet.id};
        this.refs[getShowGradingPeriodSetRef(set)].refs.editButton.focus();
      }
    },

    addGradingPeriodSet(set, termIDs) {
      this.setState({
        sets: [set].concat(this.state.sets),
        expandedSetIDs: this.state.expandedSetIDs.concat([set.id]),
        enrollmentTerms: this.associateTermsWithSet(set.id, termIDs),
        showNewSetForm: false
      }, () => {
        this.refs.addSetFormButton.focus();
      });
    },

    associateTermsWithSet(setID, termIDs) {
      return _.map(this.state.enrollmentTerms, function(term) {
        if (_.contains(termIDs, term.id)) {
          let newTerm = _.extend({}, term);
          newTerm.gradingPeriodGroupId = setID;
          return newTerm;
        } else {
          return term;
        }
      });
    },

    componentWillMount() {
      this.getSets();
      this.getTerms();
    },

    getSets() {
      SetsApi.list()
        .then((sets) => { this.onSetsLoaded(sets); })
        .catch((_) => {
          $.flashError(I18n.t(
            "An error occured while fetching grading period sets."
          ));
        });
    },

    getTerms() {
      TermsApi.list()
        .then((terms) => { this.onTermsLoaded(terms); })
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
      const sortedSets = _.sortBy(sets, "createdAt").reverse();
      this.setState({ sets: sortedSets });
    },

    onSetUpdated(updatedSet) {
      let sets = _.map(this.state.sets, (set) => {
        return (set.id === updatedSet.id) ? _.extend({}, set, updatedSet) : set;
      });

      let terms = _.map(this.state.enrollmentTerms, function(term) {
        if (_.contains(updatedSet.enrollmentTermIDs, term.id)) {
          return _.extend({}, term, { gradingPeriodGroupId: updatedSet.id });
        } else if (term.gradingPeriodGroupId === updatedSet.id) {
          return _.extend({}, term, { gradingPeriodGroupId: null });
        } else {
          return term;
        }
      });

      this.setState({ sets: sets, enrollmentTerms: terms });
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

    filterSetsBySelectedTerm(sets, terms, selectedTermID) {
      if (selectedTermID === "0") return sets;

      const activeTerm = _.findWhere(terms, { id: selectedTermID });
      const setID = activeTerm.gradingPeriodGroupId;
      return _.where(sets, { id: setID });
    },

    changeSelectedEnrollmentTerm(event) {
      this.setState({ selectedTermID: event.target.value });
    },

    alertForMatchingSets(numSets) {
      let msg;
      if (this.state.selectedTermID === "0" && this.state.searchText === "") {
        msg = I18n.t("Showing all sets of grading periods.");
      } else {
        msg = I18n.t({
            one: "1 set of grading periods found.",
            other: "%{count} sets of grading periods found.",
            zero: "No matching sets of grading periods found."
          }, {count: numSets}
        );
      }
      $.screenReaderFlashMessageExclusive(msg);
    },

    getVisibleSets() {
      let setsFilteredBySearchText =
        this.filterSetsBySearchText(this.state.sets, this.state.searchText);
      let filterByTermArgs = [
        setsFilteredBySearchText,
        this.state.enrollmentTerms,
        this.state.selectedTermID
      ];
      let visibleSets = this.filterSetsBySelectedTerm(...filterByTermArgs);
      this.alertForMatchingSets(visibleSets.length);
      return visibleSets;
    },

    toggleSetBody(setId) {
      if (_.contains(this.state.expandedSetIDs, setId)) {
        this.setState({ expandedSetIDs: _.without(this.state.expandedSetIDs, setId) });
      } else {
        this.setState({ expandedSetIDs: this.state.expandedSetIDs.concat([setId]) });
      }
    },

    editGradingPeriodSet(set) {
      this.setState({ editSet: {id: set.id, saving: false} });
    },

    nodeToFocusOnAfterSetDeletion(setID) {
      const index = this.state.sets.findIndex(set => set.id === setID);
      if (index < 1) {
        return this.refs.addSetFormButton;
      } else {
        const setRef = getShowGradingPeriodSetRef(this.state.sets[index - 1]);
        const setToFocus = this.refs[setRef];
        return setToFocus.refs.title;
      }
    },

    removeGradingPeriodSet(setID) {
      let newSets = _.reject(this.state.sets, set => set.id === setID);
      const nodeToFocus = this.nodeToFocusOnAfterSetDeletion(setID);
      this.setState({ sets: newSets }, () => nodeToFocus.focus());
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
      this.setState({ showNewSetForm: false }, () => {
        this.refs.addSetFormButton.focus();
      });
    },

    termsBelongingToActiveSets() {
      const setIDs = _.pluck(this.state.sets, "id");
      return _.filter(this.state.enrollmentTerms, function(term) {
        const setID = term.gradingPeriodGroupId;
        return setID && _.contains(setIDs, setID);
      });
    },

    termsNotBelongingToActiveSets() {
      return _.difference(this.state.enrollmentTerms, this.termsBelongingToActiveSets());
    },

    selectableTermsForEditSetForm(setID) {
      const termsBelongingToThisSet = _.where(this.termsBelongingToActiveSets(), { gradingPeriodGroupId: setID });
      return _.union(this.termsNotBelongingToActiveSets(), termsBelongingToThisSet);
    },

    closeEditSetForm(id) {
      this.setState({ editSet: {id: null, saving: false} });
    },

    renderEditGradingPeriodSetForm(set) {
      let cancelCallback = () => {
        this.closeEditSetForm(set.id);
      };

      let saveCallback = (set) => {
        let editSet = _.extend({}, this.state.editSet, {saving: true});
        this.setState({editSet: editSet});
        SetsApi.update(set)
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
          enrollmentTerms = {this.selectableTermsForEditSetForm(set.id)}
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
              expanded        = {_.contains(this.state.expandedSetIDs, set.id)}
              onEdit          = {this.editGradingPeriodSet}
              onDelete        = {this.removeGradingPeriodSet}
              onPeriodsChange = {this.updateSetPeriods}
              onToggleBody    = {() => { this.toggleSetBody(set.id) }}
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
            enrollmentTerms     = {this.termsNotBelongingToActiveSets()}
            readOnly            = {this.props.readOnly}
            addGradingPeriodSet = {this.addGradingPeriodSet}
          />
        );
      }
    },

    renderAddSetFormButton() {
      let disable = this.state.showNewSetForm || !!this.state.editSet.id;
      if (!this.props.readOnly) {
        return (
          <Button
            ref            = 'addSetFormButton'
            variant        = 'primary'
            disabled       = {disable}
            onClick        = {this.openNewSetForm}
            aria-label     = {I18n.t("Add Set of Grading Periods")}
          >
            <i className="icon-plus"/>
            &nbsp;
            <span aria-hidden="true">{I18n.t("Set of Grading Periods")}</span>
          </Button>
        );
      }
    },

    render() {
      return (
        <div>
          <div className="GradingPeriodSets__toolbar header-bar no-line ic-Form-action-box">
            <div className="ic-Form-action-box__Form">
              <div className="ic-Form-control">
                <EnrollmentTermsDropdown
                  terms={this.termsBelongingToActiveSets()}
                  changeSelectedEnrollmentTerm={this.changeSelectedEnrollmentTerm} />
              </div>

              <SearchGradingPeriodsField changeSearchText={this.changeSearchText} />
            </div>

            <div className="ic-Form-action-box__Actions">
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
