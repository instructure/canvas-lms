 define([
  'react',
  'react-dom',
  'i18n!custom_help_link',
  './CustomHelpLinkPropTypes',
  './CustomHelpLinkConstants'
], function(
    React,
    ReactDOM,
    I18n,
    CustomHelpLinkPropTypes,
    CustomHelpLinkConstants
  ) {
  const CustomHelpLinkForm = React.createClass({
    propTypes: {
      link: CustomHelpLinkPropTypes.link.isRequired,
      onSave: React.PropTypes.func,
      onCancel: React.PropTypes.func
    },
    getInitialState () {
      return {
        link: {
          ...this.props.link
        }
      };
    },
    handleKeyDown(e, field) {
      // need to update the state if the user hits the ENTER key from any of the fields
      if (e.which !== 13) {
        return;
      }

      if (field === 'available_to') {
        this.handleAvailableToChange(e.target.value, e.target.checked);
      } else if (field) {
        this.handleChange(field, e.target.value)
      }
    },
    handleChange (field, value) {
      this.setState({
        link: {
          ...this.state.link,
          [field]: value
        }
      });
    },
    handleSave (e) {
      if (typeof this.props.onSave === 'function') {
        this.props.onSave(this.state.link)
      }
      e.preventDefault();
    },
    handleAvailableToChange (type, checked) {
      const available_to = this.state.link.available_to.slice() // make a copy

      if (checked) {
        available_to.push(type)
      } else {
        available_to.splice(available_to.indexOf(type), 1)
      }

      this.handleChange('available_to', available_to)
    },
    handleCancel () {
      if (typeof this.props.onCancel === 'function') {
        this.props.onCancel(this.props.link)
      }
    },
    focus () {
      ReactDOM.findDOMNode(this.textInputRef).focus();
    },
    focusable () {
      ReactDOM.findDOMNode(this.textInputRef);
    },
    render () {
      const {
        text,
        state,
        subtext,
        url,
        available_to,
        index,
        id
      } = this.state.link

      const namePrefix = `${CustomHelpLinkConstants.NAME_PREFIX}[${index}]`

      return (
        <li className="ic-Sortable-item ic-Sortable-item--new-item">
          <input type="hidden" name={`${namePrefix}[state]`} value="active" />
          <div className="ic-Sortable-item__Actions">
            <button
              className="Button Button--icon-action"
              type="button"
              onClick={this.handleCancel}
            >
              <span className="screenreader-only">
                { I18n.t('Cancel custom link creation') }
              </span>
              <i className="icon-x" aria-hidden="true"></i>
            </button>
          </div>
          <fieldset className="ic-Fieldset ic-Sortable-item__Add-link-fieldset">
            <legend className="screenreader-only">
              { I18n.t('Custom link details') }
            </legend>
            <label className="ic-Form-control">
              <span className="ic-Label">
                { I18n.t('Link name') }
              </span>
              <input
                ref={(c) => { this.textInputRef = c; }}
                type="text"
                required
                aria-required="true"
                name={`${namePrefix}[text]`}
                className="ic-Input"
                defaultValue={text}
                onKeyDown={(e) => this.handleKeyDown(e, 'text')}
                onBlur={(e) => this.handleChange('text', e.target.value)}
              />
            </label>
            <label className="ic-Form-control">
              <span className="ic-Label">
                { I18n.t('Link description') }
              </span>
              <textarea
                className="ic-Input"
                name={`${namePrefix}[subtext]`}
                defaultValue={subtext}
                onKeyDown={(e) => this.handleKeyDown(e, 'subtext')}
                onBlur={(e) => this.handleChange('subtext', e.target.value)}
              />
            </label>
            <label className="ic-Form-control">
              <span className="ic-Label">
                { I18n.t('Link URL') }
              </span>
              <input
                type="url"
                required
                aria-required="true"
                name={`${namePrefix}[url]`}
                className="ic-Input"
                onKeyDown={(e) => this.handleKeyDown(e, 'url')}
                onBlur={(e) => this.handleChange('url', e.target.value)}
                placeholder={I18n.t('e.g., http://university.edu/helpdesk')}
                defaultValue={url}
              />
            </label>
            <fieldset className="ic-Fieldset ic-Fieldset--radio-checkbox">
              <legend className="ic-Legend">
                { I18n.t('Available to') }
              </legend>
              <div className="ic-Checkbox-group ic-Checkbox-group--inline">
                {
                  CustomHelpLinkConstants.USER_TYPES.map((type) => {
                    return (
                      <label key={`${id}_${type.value}`} className="ic-Form-control ic-Form-control--checkbox">
                        <input
                          type="checkbox"
                          name={`${namePrefix}[available_to][]`}
                          value={type.value}
                          checked={available_to.indexOf(type.value) > -1}
                          onKeyDown={(e) => this.handleKeyDown(e, 'available_to')}
                          onChange={(e) => this.handleAvailableToChange(e.target.value, e.target.checked)}
                        />
                        <span className="ic-Label">
                          {type.label}
                        </span>
                      </label>
                    );
                  })
                }
              </div>
            </fieldset>
            <div>
              <button type="submit" className="Button Button--primary" onClick={this.handleSave}>
                { state === 'new' ? I18n.t('Add link') : I18n.t('Update link') }
              </button>
              &nbsp;
              <button className="Button" type="button" onClick={this.handleCancel}>
                { I18n.t('Cancel') }
              </button>
            </div>
          </fieldset>
        </li>
      )
    }
  });

  return CustomHelpLinkForm;
});
