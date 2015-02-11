/** @jsx React.DOM */

define(['react'], (React) => {
  return React.createClass({

    displayName: 'ThemeEditorColorRow',

    propTypes: {
      varDef: React.PropTypes.object.isRequired,
      onChange: React.PropTypes.func.isRequired,
      currentValue: React.PropTypes.string,
      placeholder: React.PropTypes.string.isRequired
    },

    render() {
      return (
        <section className="Theme__editor-accordion_element Theme__editor-color">
          <div className="Theme__editor-form--color">
            <label
              htmlFor={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
              className="Theme__editor-color_title"
            >
              {this.props.varDef.human_name}
            </label>
            <div className="Theme__editor-color-block">
              <input
                  type="text"
                  className="Theme__editor-color-block_input-text Theme__editor-color-block_input"
                  placeholder={this.props.placeholder}
                  name={'brand_config[variables]['+ this.props.varDef.variable_name +']'}
                  value={this.props.chosenValue != null ? this.props.chosenValue : this.props.currentValue}
                  onChange={event => this.props.onChange(event.target.value) }
                />
              <label className="Theme__editor-color-label Theme__editor-color-block_label-sample" style={{backgroundColor: this.props.placeholder}}
                /* this <label> and <input type=color> are here so if you click the 'sample',
                it will pop up a color picker on browsers that support it */
              >
                <input
                  className="Theme__editor-color-block_input-sample Theme__editor-color-block_input"
                  type="color"
                  ref="colorpicker"
                  value={this.props.placeholder}
                  role="presentation-only"
                  onChange={event => this.props.onChange(event.target.value) }
                />
                
              </label>
            </div>
          </div>
        </section>
      )
    }
  })
});