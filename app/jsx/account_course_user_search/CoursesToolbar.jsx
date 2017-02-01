define([
  'react',
  'i18n!account_course_user_search',
  './TermsStore',
  './AccountsTreeStore',
  './NewCourseModal',
  './IcInput',
  './IcSelect',
  './IcCheckbox',
], (React, I18n, TermsStore, AccountsTreeStore, NewCourseModal, IcInput, IcSelect, IcCheckbox) => {
  const { string, bool, func, arrayOf, shape } = React.PropTypes

  return class CoursesToolbar extends React.Component {
    static propTypes = {
      onUpdateFilters: func.isRequired,
      onApplyFilters: func.isRequired,
      isLoading: bool,
      with_students: bool.isRequired,
      search_term: string,
      enrollment_term_id: string,
      errors: shape({ search_term: string }).isRequired,
      terms: arrayOf(TermsStore.PropType),
      accounts: arrayOf(AccountsTreeStore.PropType),
    }

    static defaultProps = {
      terms: null,
      accounts: [],
      search_term: '',
      enrollment_term_id: null,
      isLoading: false,
    }

    applyFilters = (e) => {
      e.preventDefault()
      this.props.onApplyFilters()
    }

    addCourse = () => {
      this.addCourse.openModal()
    }

    renderTerms () {
      const { terms } = this.props

      if (terms) {
        return [
          <option key="all" value="">
            {I18n.t('All Terms')}
          </option>
        ].concat(terms.map(term => (
          <option key={term.id} value={term.id}>
            {term.name}
          </option>
        )))
      }

      return <option value="">{I18n.t('Loading...')}</option>
    }

    render () {
      const { terms, accounts, onUpdateFilters, isLoading, errors, ...props } = this.props

      const addCourseButton = window.ENV.PERMISSIONS.can_create_courses ?
        (<div>
          <button className="btn" type="button" onClick={this.addCourse}>
            <i className="icon-plus" />
            {' '}
            {I18n.t('Course')}
          </button>
        </div>) : null

      return (
        <div>
          <form
            className="course_search_bar"
            style={{opacity: isLoading ? 0.5 : 1}}
            onSubmit={this.applyFilters}
            disabled={isLoading}
          >
            <div className="ic-Form-action-box courses-list-search-bar-layout">
              <div className="ic-Form-action-box__Form">
                <IcSelect
                  value={props.enrollment_term_id}
                  onChange={e => onUpdateFilters({enrollment_term_id: e.target.value})}
                >
                  {this.renderTerms()}
                </IcSelect>
                <IcInput
                  value={props.search_term}
                  placeholder={I18n.t('Search courses...')}
                  onChange={e => onUpdateFilters({search_term: e.target.value})}
                  error={errors.search_term}
                />
                <div className="ic-Form-control">
                  <button className="btn">
                    {I18n.t('Go')}
                  </button>
                </div>
              </div>
              <div className="ic-Form-action-box__Actions">
                {addCourseButton}
              </div>
            </div>
            <IcCheckbox
              checked={props.with_students}
              onChange={e => onUpdateFilters({with_students: e.target.checked})}
              label={I18n.t('Hide courses without enrollments')}
            />
          </form>
          <NewCourseModal
            ref={(c) => { this.addCourseModal = c }}
            terms={terms}
            accounts={accounts}
          />
        </div>
      )
    }
  }
})
