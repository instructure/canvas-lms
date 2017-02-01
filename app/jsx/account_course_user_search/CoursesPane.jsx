define([
  'react',
  'i18n!account_course_user_search',
  './CoursesStore',
  './TermsStore',
  './AccountsTreeStore',
  './CoursesList',
  './CoursesToolbar',
  './renderSearchMessage',
], (React, I18n, CoursesStore, TermsStore, AccountsTreeStore, CoursesList, CoursesToolbar, renderSearchMessage) => {
  const MIN_SEARCH_LENGTH = 3
  const stores = [CoursesStore, TermsStore, AccountsTreeStore]
  const { shape, arrayOf, string } = React.PropTypes

  return class CoursesPane extends React.Component {
    static propTypes = {
      roles: arrayOf(shape({ id: string.isRequired })).isRequired,
      addUserUrls: shape({
        USER_LISTS_URL: string.isRequired,
        ENROLL_USERS_URL: string.isRequired,
      }).isRequired,
      accountId: string.isRequired,
    }

    constructor () {
      super()

      const filters = {
        enrollment_term_id: '',
        search_term: '',
        with_students: false,
      }

      this.state = {
        filters,
        draftFilters: filters,
        errors: {}
      }
    }

    componentWillMount () {
      stores.forEach(s => s.addChangeListener(this.refresh))
    }

    componentDidMount () {
      this.fetchCourses()
      TermsStore.loadAll()
      AccountsTreeStore.loadTree()
    }

    componentWillUnmount () {
      stores.forEach(s => s.removeChangeListener(this.refresh))
    }

    fetchCourses = () => {
      CoursesStore.load(this.state.filters)
    }

    fetchMoreCourses = () => {
      CoursesStore.loadMore(this.state.filters)
    }

    onUpdateFilters = (newFilters) => {
      this.setState({
        errors: {},
        draftFilters: Object.assign({}, this.state.draftFilters, newFilters)
      })
    }

    onApplyFilters = () => {
      const filters = this.state.draftFilters
      if (filters.search_term && filters.search_term.length < MIN_SEARCH_LENGTH) {
        this.setState({errors: {search_term: I18n.t('Search term must be at least %{num} characters', {num: MIN_SEARCH_LENGTH})}})
      } else {
        this.setState({filters, errors: {}}, this.fetchCourses)
      }
    }

    refresh = () => {
      this.forceUpdate()
    }

    render () {
      const { filters, draftFilters, errors } = this.state
      const courses = CoursesStore.get(filters)
      const terms = TermsStore.get()
      const accounts = AccountsTreeStore.getTree()
      const isLoading = !(courses && !courses.loading && terms && !terms.loading)

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

          {renderSearchMessage(courses, this.fetchMoreCourses, I18n.t('No courses found'))}
        </div>
      )
    }
  }
})
