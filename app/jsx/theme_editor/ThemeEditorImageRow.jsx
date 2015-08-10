/** @jsx React.DOM */

define([
  'react',
  './PropTypes',
  'i18n!theme_editor'
], (React, customTypes, I18n) => {

  // consider anything other than null or undefined (including '') as "set"
  function isSet(val) {
    return val === null || val === undefined
  }

  return React.createClass({

    displayName: 'ThemeEditorImageRow',

    propTypes: {
      varDef: customTypes.image,
      userInput: customTypes.userVariableInput,
      onChange: React.PropTypes.func.isRequired,
      currentValue: React.PropTypes.string,
      placeholder: React.PropTypes.string
    },

    getDefaultProps(){
      return {
        userInput: {}
      }
    },

    // valid input: null, '', or an HTMLInputElement
    setValue(inputElementOrNewValue) {
      var chosenValue = inputElementOrNewValue

      if (!inputElementOrNewValue) { //if it's null or ''
        // if they hit the "Undo" or "Use Default" button,
        // we want to also clear out the value of the <input type=file>
        // but we don't want to mess with its value otherwise
        this.refs.fileInput.getDOMNode().value = ''
      } else {
        chosenValue = window.URL.createObjectURL(inputElementOrNewValue.files[0])
      }
      this.props.onChange(chosenValue)
    },

    render() {
      var inputName = 'brand_config[variables][' + this.props.varDef.variable_name + ']'
      var imgSrc = this.props.userInput.val || this.props.placeholder

      return (
        <section className="Theme__editor-accordion_element Theme__editor-upload">
          <div className="te-Flex">
            <div className="Theme__editor-form--upload">
              <div className="Theme__editor-upload_header">
                <h4 className="Theme__editor-upload_title" >
                  { this.props.varDef.human_name }
                </h4>
                <span className="Theme__editor-upload_restrictions">
                  { this.props.varDef.helper_text }
                </span>
              </div>

              <div className={'Theme__editor_preview-img-container Theme__editor_preview-img-container--' + this.props.varDef.variable_name}>
            {/* ^ this utility class is to control the background color that shows behind the images you can customize in theme editor - see theme_editor.scss */}
                <div className="Theme__editor_preview-img">
                  { imgSrc && <img src={imgSrc} className="Theme__editor-placeholder" alt="" /> }
                </div>
              </div>

              <div className="Theme__editor-image_upload">
                <input
                    type="hidden"
                    name={!this.props.userInput.val && inputName}
                    value={(this.props.userInput.val === '') ? '' : this.props.currentValue}
                  />

                <label className="Theme__editor-image_upload-label">
                  <span className="screenreader-only">
                    { this.props.varDef.human_name }
                  </span>
                  <input
                    type="file"
                    className="Theme__editor-input_upload"
                    name={this.props.userInput.val && inputName}
                    accept={this.props.varDef.accept}
                    onChange={event => this.setValue(event.target)}
                    ref="fileInput"
                  />
                  <span className="Theme__editor-button_upload Button Button--link" aria-hidden="true">
                    { I18n.t('Select Image') }
                  </span>
                </label>

                {this.props.userInput.val || this.props.currentValue ? (
                  <button
                    type="button"
                    className="Button Button--link"
                    onClick={() => this.setValue(isSet(this.props.userInput.val) ? '' : null)}
                  >
                    { isSet(this.props.userInput.val) ? I18n.t('Use Default') : I18n.t('Undo') }
                  </button>
                ) : (
                  null
                )}
              </div>
            </div>
          </div>
        </section>
      )
    }
  })
});
