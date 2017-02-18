define([
  'react',
  'i18n!student_context_tray',
  'jsx/shared/FriendlyDatetime',
  './StudentCardStore',
  './Avatar',
  './LastActivity',
  './MetricsList',
  './Rating',
  './SectionInfo',
  './SubmissionProgressBars',
  'jsx/shared/MessageStudents',
  'instructure-ui',
], function(React, I18n, FriendlyDatetime,
   StudentCardStore,
   Avatar,
   LastActivity,
   MetricsList,
   Rating,
   SectionInfo,
   SubmissionProgressBars,
   MessageStudents,
   {Heading, Button, Link, Typography, ScreenReaderContent, Spinner, Tray, ApplyTheme}) {

  class StudentContextTray extends React.Component {

    static propTypes = {
      courseId: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.number
      ]),
      studentId: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.number
      ]),
      store: React.PropTypes.instanceOf(StudentCardStore),
      onClose: React.PropTypes.func,
      returnFocusTo: React.PropTypes.func.isRequired
    }

    static renderQuickLink (label, url, showIf) {
      return showIf() ? (
        <div className="StudentContextTray-QuickLinks__Link">
          <Button
            href={url}
            variant="ghost" size="small" isBlock
          >
            {label}
          </Button>
        </div>
      ) : null
    }

    constructor (props) {
      super(props)
      this.state = {
        analytics: {},
        course: {},
        isLoading: this.props.store.isLoading,
        isOpen: true,
        messageFormOpen: false,
        permissions: {},
        submissions: [],
        user: {}
      }
    }

    /**
     * Lifecycle
     */

    componentDidMount () {
      this.props.store.onChange = this.onChange
    }

    componentWillReceiveProps (nextProps) {
      if (nextProps.store !== this.props.store) {
        this.props.store.onChange = null
        nextProps.store.onChange = this.onChange
        const newState = {
          isLoading: true
        };
        if (!this.state.isOpen) {
          newState.isOpen = true
        }
        this.setState(newState)
      }
    }

    /**
     * Handlers
     */

    onChange = () => {
      const {store} = this.props;
      this.setState({
        analytics: store.state.analytics,
        course: store.state.course,
        isLoading: store.state.loading,
        permissions: store.state.permissions,
        submissions: store.state.submissions,
        user: store.state.user
      }, () => {
        if (!store.state.loading && this.state.isOpen) {
          if (this.closeButtonRef) {
            this.closeButtonRef.focus()
          }
        }
      })
    }

    getCloseButtonRef = (ref) => {
      this.closeButtonRef = ref
    }

    handleRequestClose = (e) => {
      e.preventDefault()
      this.setState({
        isOpen: false
      })
      if (this.props.returnFocusTo) {
        const focusableItems = this.props.returnFocusTo();
        // Because of the way native focus calls return undefined, all focus
        // objects should be wrapped in something that will return truthy like
        // jQuery wrappers do... and it should be able to check visibility like a
        // jQuery wrapper... so just use jQuery.
        focusableItems.some($itemToFocus => $itemToFocus.is(':visible') && $itemToFocus.focus())
      }
    }

    handleMessageButtonClick = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: true
      })
    }

    handleMessageFormClose = (e) => {
      e.preventDefault()
      this.setState({
        messageFormOpen: false
      }, () => {
        this.messageStudentsButton.focus()
      })
    }

    /**
     * Renderers
     */

    renderQuickLinks () {
      return (this.state.user.short_name && (
        this.state.permissions.manage_grades ||
        this.state.permissions.view_all_grades ||
        this.state.permissions.view_analytics
      )) ? (
        <section
          className="StudentContextTray__Section StudentContextTray-QuickLinks"
        >
          {StudentContextTray.renderQuickLink(
            I18n.t('Grades'),
            `/courses/${this.props.courseId}/grades/${this.props.studentId}`,
            () =>
              this.state.permissions.manage_grades ||
              this.state.permissions.view_all_grades
          )}
          {StudentContextTray.renderQuickLink(
            I18n.t('Analytics'),
            `/courses/${this.props.courseId}/analytics/users/${this.props.studentId}`,
            () => (
              this.state.permissions.view_analytics && Object.keys(this.state.analytics).length > 0
            )
          )}
        </section>
      ) : null
    }

    render () {
      return (
        <div>
          {this.state.messageFormOpen ? (
            <MessageStudents
              contextCode={`course_${this.state.course.id}`}
              onRequestClose={this.handleMessageFormClose}
              open={this.state.messageFormOpen}
              recipients={[{
                id: this.state.user.id,
                displayName: this.state.user.short_name
              }]}
              title='Send a message'
            />
          ) : null}

          <Tray
            label={I18n.t('Student Details')}
            isDismissable={!this.state.isLoading}
            closeButtonLabel={I18n.t('Close')}
            closeButtonRef={this.getCloseButtonRef}
            isOpen={this.state.isOpen}
            onRequestClose={this.handleRequestClose}
            placement='right'
            zIndex='1000'
            onClose={this.props.onClose}
          >
            <aside
              className={(Object.keys(this.state.user).includes('avatar_url'))
                ? 'StudentContextTray StudentContextTray--withAvatar'
                : 'StudentContextTray'
              }
            >
              {this.state.isLoading ? (
                <div className='StudentContextTray__Spinner'>
                  <Spinner title={I18n.t('Loading')}
                    size='large'
                  />
                </div>
              ) : (
                <div>
                  <header className="StudentContextTray-Header">
                    <Avatar user={this.state.user}
                      canMasquerade={this.state.permissions.become_user}
                      courseId={this.props.courseId}
                    />

                    <div className="StudentContextTray-Header__Layout">
                      <div className="StudentContextTray-Header__Content">
                        {this.state.user.short_name ? (
                          <div className="StudentContextTray-Header__Name">
                            <Heading level="h3" tag="h2">
                              <span className="StudentContextTray-Header__NameLink">
                                <Link
                                  href={`/courses/${this.props.courseId}/users/${this.props.studentId}`}
                                >
                                  {this.state.user.short_name}
                                </Link>
                              </span>
                            </Heading>
                          </div>
                        ) : null}
                        <div className="StudentContextTray-Header__CourseName">
                          <Typography size="medium" tag="div" lineHeight="condensed">
                            {this.state.course.name}
                          </Typography>
                        </div>
                        <Typography size="x-small" color="secondary" tag="div">
                          <SectionInfo course={this.state.course} user={this.state.user} />
                        </Typography>
                        <Typography size="x-small" color="secondary" tag="div">
                          <LastActivity user={this.state.user} />
                        </Typography>
                      </div>
                      {this.state.permissions.send_messages ? (
                        <div className="StudentContextTray-Header__Actions">
                          <Button
                            ref={ (b) => this.messageStudentsButton = b }
                            variant="icon" size="small"
                            onClick={this.handleMessageButtonClick}
                          >
                            <ScreenReaderContent>
                              {I18n.t('Send a message to this student')}
                            </ScreenReaderContent>

                            {/* Note: replace with instructure-icon */}
                            <i className="icon-email" aria-hidden="true" />

                          </Button>
                        </div>
                      ) : null }
                    </div>
                  </header>
                  {this.renderQuickLinks()}
                  <MetricsList user={this.state.user} analytics={this.state.analytics} />
                  <SubmissionProgressBars submissions={this.state.submissions} />

                  {Object.keys(this.state.analytics).length > 0 ? (
                    <section
                      className="StudentContextTray__Section StudentContextTray-Ratings">
                      <Heading level="h4" tag="h3" border="bottom">
                        {I18n.t("Activity Compared to Class")}
                      </Heading>
                      <div className="StudentContextTray-Ratings__Layout">
                        <Rating analytics={this.state.analytics}
                          label={I18n.t('Participation')}
                          metricName='participations_level' />
                        <Rating analytics={this.state.analytics}
                          label={I18n.t('Page Views')}
                          metricName='page_views_level' />
                      </div>
                    </section>
                  ) : null}
                </div>
              )}
            </aside>
          </Tray>
        </div>
      )
    }
  }

  const DeleteMe = (props) => (
    <ApplyTheme theme={ApplyTheme.generateTheme('a11y')}>
      <StudentContextTray {...props}/>
    </ApplyTheme>
  )

  /* TODO: after instui gets updated, just return StudentContextTray */
  return ENV.use_high_contrast ? DeleteMe : StudentContextTray
})
