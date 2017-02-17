define([
  'jquery',
  'react',
  'str/htmlEscape',
  'i18n!help_dialog',
  'jquery.instructure_forms', /* formSubmit, getFormData, formErrors */
  'compiled/jquery.rails_flash_notifications'
], ($, React, htmlEscape, I18n) => {
  const TeacherFeedbackForm = React.createClass({
    propTypes: {
      onCancel: React.PropTypes.func,
      onSubmit: React.PropTypes.func
    },
    getDefaultProps () {
      return {
        onCancel: function () {},
        onSubmit: function () {}
      };
    },
    getInitialState () {
      return {
        coursesLoaded: false,
        courses: []
      };
    },
    componentWillMount () {
      $.getJSON('/api/v1/courses.json', (courses) => {
        this.setState({
          coursesLoaded: true,
          courses
        });
      })
    },
    componentDidMount () {
      this.focus();

      $(this.form).formSubmit({
        formErrors: false,
        disableWhileLoading: true,
        required: ['recipients[]', 'body'],
        success: () => {
          $.flashMessage(I18n.t('Message sent.'));
          this.props.onSubmit();
        },
        error: (response) => {
          this.form.formErrors(JSON.parse(response.responseText));
          this.focus();
        }
      });
    },
    focus () {
      this.recipients.focus();
    },
    handleCancelClick () {
      this.form.reset();
      this.props.onCancel();
    },
    renderCourseOptions () {
      let options = this.state.courses.map((c) => {
        const value = `course_${c.id}_admins`;

        return (
          <option key={value} value={value} selected={window.ENV.context_id == c.id}>
            {c.name}
          </option>
        );
      });

      if (!this.state.coursesLoaded) {
        options.push(<option key="loading">{I18n.t('Loading courses...')}</option>)
      }

      return options;
    },
    render () {
      return (
          <form
            ref={(c) => this.form = c}
            action="/api/v1/conversations"
            method="POST"
          >
            <fieldset className="ic-Form-group ic-HelpDialog__form-fieldset">
              <legend className="screenreader-only">
                {I18n.t('Ask your instructor a question')}
              </legend>
              <label className="ic-Form-control">
                <span className="ic-Label">
                  {I18n.t('Which course is this question about?')}
                </span>
                <select
                  ref={(c) => this.recipients = c}
                  className="ic-Input"
                  required
                  aria-required="true"
                  name="recipients[]"
                >
                  {this.renderCourseOptions()}
                </select>
                <span className="ic-Form-help-text">
                  {I18n.t('Message will be sent to all the teachers and teaching assistants in the course.')}
                </span>
              </label>
              <label className="ic-Form-control">
                <span className="ic-Label">
                  {I18n.t('Message')}
                </span>
                <textarea
                  className="ic-Input"
                  required
                  aria-required="true"
                  name="body">
                </textarea>
              </label>
              <div className="ic-HelpDialog__form-actions">
                <button
                  type="button"
                  className="Button"
                  onClick={this.handleCancelClick}
                >
                  {I18n.t('Cancel')}
                </button>&nbsp;
                <button
                  type="submit"
                  disabled={!this.state.coursesLoaded}
                  className="Button Button--primary">
                  <i className="icon-message" aria-hidden="true"></i>
                  &nbsp;&nbsp;
                  {I18n.t('Send Message')}
                </button>
              </div>
              <input type="hidden" name="group_conversation" value="true" />
            </fieldset>

          </form>
      );
    }
  });
  return TeacherFeedbackForm;
});
