define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./CoursesStore",
  "./TermsStore",
  "./AccountsTreeStore",
  "./CoursesList",
  "./CoursesToolbar",
  "./renderSearchMessage"
], function(React, I18n, _, CoursesStore, TermsStore, AccountsTreeStore, CoursesList, CoursesToolbar, renderSearchMessage) {

  var MIN_SEARCH_LENGTH = 3;

  var stores = [CoursesStore, TermsStore, AccountsTreeStore];

  var CoursesPane = React.createClass({
    getInitialState() {
      var filters = {
        enrollment_term_id: "",
        search_term: "",
        with_students: false
      };

      return {
        filters,
        draftFilters: filters,
        errors: {}
      };
    },

    componentWillMount() {
      stores.forEach((s) => s.addChangeListener(this.refresh));
    },

    componentDidMount() {
      this.fetchCourses();
      TermsStore.loadAll();
      AccountsTreeStore.loadTree();
    },

    componentWillUnmount() {
      stores.forEach((s) => s.removeChangeListener(this.refresh));
    },

    fetchCourses() {
      CoursesStore.load(this.state.filters);
    },

    fetchMoreCourses() {
      CoursesStore.loadMore(this.state.filters);
    },

    onUpdateFilters(newFilters) {
      this.setState({
        errors: {},
        draftFilters: _.extend({}, this.state.draftFilters, newFilters)
      });
    },

    onApplyFilters() {
      var filters = this.state.draftFilters;
      if (filters.search_term && filters.search_term.length < MIN_SEARCH_LENGTH) {
        this.setState({errors: {search_term: I18n.t("Search term must be at least %{num} characters", {num: MIN_SEARCH_LENGTH})}});
      } else {
        this.setState({filters, errors: {}}, this.fetchCourses);
      }
    },

    refresh() {
      this.forceUpdate();
    },

    render() {
      var { filters, draftFilters, errors } = this.state;
      var courses = CoursesStore.get(filters);
      var terms = TermsStore.get();
      var accounts = AccountsTreeStore.getTree();
      var isLoading = !(courses && !courses.loading && terms && !terms.loading);

      return (
        <div>
          <CoursesToolbar
            onUpdateFilters={this.onUpdateFilters}
            onApplyFilters={this.onApplyFilters}
            terms={terms && terms.data}
            accounts={accounts}
            isLoading={isLoading}
            {...draftFilters}
            errors={errors}
          />

          {courses && courses.data &&
            <CoursesList
              accountId={this.props.accountId}
              courses={courses.data}
              roles={this.props.roles}
              addUserUrls={this.props.addUserUrls}
            />
          }

          {renderSearchMessage(courses, this.fetchMoreCourses, I18n.t("No courses found"))}
        </div>
      );
    }
  });

  return CoursesPane;
});

