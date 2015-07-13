/** @jsx React.DOM */

define([
  'react',
  './PropTypes',
  'i18n!theme_editor'
], (React, customTypes, I18n) => {

  return React.createClass({

    displayName: 'ThemeEditorImageRow',

    propTypes: {
      varDef: customTypes.image,
      onChange: React.PropTypes.func.isRequired,
      currentValue: React.PropTypes.string,
      placeholder: React.PropTypes.string
    },

    setValue(inputElement) {
      var chosenValue = inputElement

      if (!chosenValue) {
        // if they hit the "remove" button, we want to also clear out the value of the <input type=file>
        // but we don't want to mess with its value otherwise
        this.refs.fileInput.getDOMNode().value = ''
      } else {
        chosenValue = window.URL.createObjectURL(inputElement.files[0])
      }
      this.props.onChange(chosenValue)
    },

    inputName(){
      // dont insert name & send params if default value
      var valueIsDefault = !this.props.chosenValue && !this.props.currentValue
      return valueIsDefault ? '' : 'brand_config[variables]['+ this.props.varDef.variable_name +']'
    },

    render() {
      return (
        <section className="Theme__editor-accordion_element Theme__editor-upload">
          <div className="te-Flex">
            <div className="Theme__editor-form--upload">
              <label
                htmlFor={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
                className="Theme__editor-upload_title"
              >
                {this.props.varDef.human_name}
                <span className="Theme__editor-upload_restrictions">
                  {this.props.varDef.helper_text}
                </span>
              </label>

              <div className={'Theme__editor_preview-img-container Theme__editor_preview-img-container--' + this.props.varDef.variable_name}>
            {{/* ^ this utility class is to control the background color that shows behind the images you can customize in theme editor - see theme_editor.scss */}}
                <div className="Theme__editor_preview-img">
                  <img
                    src={this.props.chosenValue || this.props.placeholder}
                    className="Theme__editor-placeholder"
                  />
                </div>
              </div>
              <input
                type="hidden"
                name={this.inputName()}
                value={this.props.currentValue}
              />
              <div className="Theme__editor-image_upload">
                <label className="Theme__editor-image_upload-label">
                  <span className="Theme__editor-button_upload Button Button--link">Upload Image</span>
                  <input
                    type="file"
                    className="Theme__editor-input_upload"
                    name={this.props.chosenValue ? 'brand_config[variables]['+ this.props.varDef.variable_name +']' : ''}
                    accept={this.props.varDef.accept}
                    onChange={event => this.setValue(event.target)}
                    ref="fileInput"
                  />
                </label>
                {this.props.chosenValue || (this.props.currentValue && this.props.chosenValue !== '') ? (
                  <button
                    type="button"
                    className="Button Button--link"
                    onClick={() => this.setValue(this.props.chosenValue ? null : '')}
                  >
                    {this.props.chosenValue && this.props.currentValue ? I18n.t('Undo') : I18n.t('Reset')}
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
