define([
  'jquery',
  'react',
  'react-dom',
  'react-modal',
  'classnames',
  'i18n!conditional_release',
  'jsx/shared/helpers/numberHelper',
  'jquery.instructure_forms'
], ($, React, ReactDOM, Modal, classNames, I18n, numberHelper) => {
  const SAVE_TIMEOUT = 15000

  const Editor = React.createClass({
    displayName: 'ConditionalReleaseEditor',

    propTypes: {
      env: React.PropTypes.object.isRequired,
      type: React.PropTypes.string.isRequired
    },

    getInitialState() {
      return {
        editor: null,
      };
    },

    validateBeforeSave() {
      const errors = []
      const rawErrors = this.state.editor ? this.state.editor.getErrors() : null
      if (rawErrors) {
        rawErrors.forEach((errorRecord) => {
          $.screenReaderFlashError(I18n.t('%{error} in mastery paths range %{index}', {
            error: errorRecord.error,
            index: errorRecord.index + 1 }))
          errors.push({ message: errorRecord.error })
        })
      }
      return errors.length == 0 ? null : errors;
    },

    focusOnError() {
      if (this.state.editor) {
        this.state.editor.focusOnError()
      }
    },

    updateAssignment(newAttributes = {}) {
      if (!this.state.editor) {
        return
      }
      // a not_graded assignment counts as a non-assignment
      // to cyoe
      if (newAttributes.grading_type === 'not_graded') {
        newAttributes.id = null;
      }
      this.state.editor.updateAssignment({
        grading_standard_id: newAttributes.grading_standard_id,
        grading_type: newAttributes.grading_type,
        id: newAttributes.id,
        points_possible: newAttributes.points_possible,
        submission_types: newAttributes.submission_types
      });
    },

    save(timeoutMs = SAVE_TIMEOUT) {
      if (!this.state.editor) {
        return $.Deferred().reject('mastery paths editor uninitialized')
      }
      const saveObject = $.Deferred()
      setTimeout(() => { saveObject.reject('timeout') }, timeoutMs)

      this.state.editor.saveRule()
      .then(() => {
        saveObject.resolve()
      })
      .catch((err) => {
        saveObject.reject(err)
      })

      return saveObject.promise();
    },

    loadEditor() {
      var url = this.props.env['editor_url']
      $.ajax({
        url,
        dataType: 'script',
        cache: true,
        success: this.createEditor
      })
    },

    createEditor() {
      var env = this.props.env
      const editor = new conditional_release_module.ConditionalReleaseEditor({
        jwt: env['jwt'],
        assignment: env['assignment'],
        courseId: env['context_id'],
        locale: {
          locale: env.locale,
          parseNumber: numberHelper.parse,
          formatNumber: I18n.n
        },
        gradingType: env['grading_type'],
        baseUrl: env['base_url']
      })
      editor.attach(
        document.getElementById('canvas-conditional-release-editor'),
        document.getElementById('application'))
      this.setState({ editor })
    },

    componentDidMount() {
      this.loadEditor();
    },

    render () {
      return (
        <div id='canvas-conditional-release-editor'/>
      )
    }
  });

  const attach = function(element, type, env) {
    const editor = (
      <Editor env={env} type={type} />
    );
    return ReactDOM.render(editor, element);
  };

  const ConditionalRelease = {
    Editor: Editor,
    attach: attach
  };

  return ConditionalRelease;
});
