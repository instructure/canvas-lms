 define([
  'react',
  'i18n!custom_help_link',
  './CustomHelpLinkPropTypes',
  './CustomHelpLinkConstants'
], function(React, I18n, CustomHelpLinkPropTypes, CustomHelpLinkConstants) {
  const CustomHelpLinkMenu = React.createClass({
    propTypes: {
      links: React.PropTypes.arrayOf(CustomHelpLinkPropTypes.link).isRequired,
      onChange: React.PropTypes.func
    },
    handleChange (e, link) {
      if (link.is_disabled) {
        e.preventDefault();
        return;
      }
      if (typeof this.props.onChange === 'function') {
        e.preventDefault()
        this.props.onChange(link)
      }
    },
    focus () {
      this.refs.addButton.focus();
    },
    focusable () {
      return this.refs.addButton;
    },
    render () {
      return (
        <div className="al-dropdown__container">
          <button
            ref="addButton"
            type="button"
            className="Button al-trigger"
            title={ I18n.t('Add link') }
            aria-label={ I18n.t('Add link') }
            aria-haspopup="true"
          >
            <i className="icon-plus" aria-hidden="true"></i>
            &nbsp;
            { I18n.t('Link') }
          </button>
          <ul
            className="al-options"
            role="menu"
            tabIndex="0"
            aria-hidden="true"
            aria-expanded="false"
            aria-labelledby="CustomHelpLinkMenu__helpText"
          >
            <li role="presentation"
              className="ui-menu-item ui-menu-item--helper-text"
            >
              { I18n.t('Add help menu links') }
            </li>
            <li role="presentation">
              <a href="#"
                tabIndex="-1"
                role="menuitem"
                onClick={(e) => this.handleChange(e, { ...CustomHelpLinkConstants.DEFAULT_LINK })}
              >
                { I18n.t('Add Custom Link') }
              </a>
            </li>
              {
                this.props.links.map((link, index) => {
                  return (
                    <li role="presentation" key={index}>
                      <a href="#"
                        tabIndex="-1"
                        role="menuitem"
                        onClick={(e) => this.handleChange(e, link)}
                        aria-disabled={link.is_disabled ? true : null}
                        className={link.is_disabled ? 'disabled' : null}
                      >
                        { link.text }
                      </a>
                    </li>
                  )
                })
              }

          </ul>
        </div>
      )
    }
  });

  return CustomHelpLinkMenu;
});
