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
  'instructure-ui/Heading',
  'instructure-ui/Button',
  'instructure-ui/Link',
  'instructure-ui/Overlay',
  'instructure-ui/Typography',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/Spinner',
  'instructure-ui/Tray'
], function(React, I18n, FriendlyDatetime,
   StudentCardStore,
   Avatar,
   LastActivity,
   MetricsList,
   Rating,
   SectionInfo,
   SubmissionProgressBars,
   MessageStudents,
   { default: Heading },
   { default: Button },
   { default: Link },
   { default: Overlay },
   { default: Typography },
   { default: ScreenReaderContent },
   { default: Spinner },
   { default: Tray }) {

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
      isOpen: React.PropTypes.bool,
      store: React.PropTypes.instanceOf(StudentCardStore),
      onClose: React.PropTypes.func,
      isLoading: React.PropTypes.bool
    }

    static defaultProps = {
      isOpen: false
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
        isLoading: this.props.isLoading,
        isOpen: this.props.isOpen,
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

    componentWillReceiveProps(nextProps) {
      if (nextProps.store !== this.props.store) {
        this.props.store.onChange = null
        nextProps.store.onChange = this.onChange
        this.setState({isLoading: true})
      }
    }

    /**
     * Handlers
     */

    onChange = (e) => {
      const {store} = this.props;
      this.setState({
        analytics: store.state.analytics,
        course: store.state.course,
        isLoading: store.state.loading,
        permissions: store.state.permissions,
        submissions: store.state.submissions,
        user: store.state.user
      })
    }

    handleRequestClose = (e) => {
      e.preventDefault()
      this.setState({
        isOpen: false
      })
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
            () => this.state.permissions.view_analytics
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
            isDismissable={!this.state.isLoading}
            closeButtonLabel={I18n.t('Close')}
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
                              <Link
                                href={`/courses/${this.props.courseId}/users/${this.props.studentId}`}
                              >
                                <span className="StudentContextTray-Header__NameLink">
                                  {this.state.user.short_name}
                                </span>
                              </Link>
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
                            variant="link" size="small"
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

  return StudentContextTray
})
