define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./TermsStore",
  "./AccountsTreeStore",
  "./NewCourseModal",
  "./IcInput",
  "./IcSelect",
  "./IcCheckbox"
], function(React, I18n, _, TermsStore, AccountsTreeStore, NewCourseModal, IcInput, IcSelect, IcCheckbox) {

  var { string, bool, func, object, arrayOf, shape } = React.PropTypes;

  var CoursesToolbar = React.createClass({
    propTypes: {
      onUpdateFilters: func.isRequired,
      onApplyFilters: func.isRequired,
      isLoading: bool,

      with_students: bool.isRequired,
      search_term: string,
      enrollment_term_id: string,
      errors: object,

      terms: arrayOf(TermsStore.PropType),
      accounts: arrayOf(AccountsTreeStore.PropType)
    },

    applyFilters(e) {
      e.preventDefault();
      this.props.onApplyFilters();
    },

    renderTerms() {
      var { terms } = this.props;

      if (terms) {
        return [
          <option key="all" value="">
            {I18n.t("All Terms")}
          </option>
        ].concat(terms.map((term) => {
          return (
            <option key={term.id} value={term.id}>
              {term.name}
            </option>
          );
        }));
      } else {
        return <option value="">{I18n.t("Loading...")}</option>;
      }
    },

    addCourse() {
      this.refs.addCourse.openModal();
    },

    render() {
      var { terms, accounts, onUpdateFilters, isLoading, with_students, search_term, enrollment_term_id, errors } = this.props;

      return (
        <div>
          <form
            className="ic-Form-group ic-Form-group--inline course_search_bar"
            style={{alignItems: "center", opacity: isLoading ? 0.5 : 1}}
            onSubmit={this.applyFilters}
            disabled={isLoading}
          >
            <IcSelect
              value={enrollment_term_id}
              onChange={(e) => onUpdateFilters({enrollment_term_id: e.target.value})}
            >
              {this.renderTerms()}
            </IcSelect>

            <IcInput
              value={search_term}
              placeholder={I18n.t("Search courses...")}
              onChange={(e) => onUpdateFilters({search_term: e.target.value})}
              error={errors.search_term}
            />

            <div className="ic-Form-control" style={{flexGrow: 0.3}}>
              <button className="btn">
                {I18n.t("Go")}
              </button>
            </div>

            <IcCheckbox
              controlClassName="flex-grow-2"
              checked={with_students}
              onChange={(e) => onUpdateFilters({with_students: e.target.checked})}
              label={I18n.t("Hide courses without enrollments")}
            />

            <div className="ic-Form-actions">
              <button className="btn" type="button" onClick={this.addCourse}>
                <i className="icon-plus" />
                {" "}
                {I18n.t("Course")}
              </button>
            </div>
          </form>

          <NewCourseModal
            ref="addCourse"
            terms={terms}
            accounts={accounts}
          />
        </div>
      );
    }
  });

  return CoursesToolbar;
});
