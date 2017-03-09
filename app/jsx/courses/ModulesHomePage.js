import React from 'react'
import IconModuleSolid from 'instructure-icons/react/Solid/IconModuleSolid'
import IconUploadLine from 'instructure-icons/react/Line/IconUploadLine'
import I18n from 'i18n!modules_home_page'

export default class ModulesHomePage extends React.Component {
  static propTypes = {
    onCreateButtonClick: React.PropTypes.func
  }

  static defaultProps = {
    onCreateButtonClick: () => {}
  }

  render () {
    const importURL = window.ENV.CONTEXT_URL_ROOT + '/content_migrations'
    return (
      <ul className="ic-EmptyStateList">
        <li className="ic-EmptyStateList__Item">
          <div className="ic-EmptyStateList__BillboardWrapper">
            <button
              type="button"
              className="ic-EmptyStateButton"
              onClick={this.props.onCreateButtonClick}
            >
              <IconModuleSolid className="ic-EmptyStateButton__SVG" />
              <span className="ic-EmptyStateButton__Text">
                {I18n.t('Create a new Module')}
              </span>
            </button>
          </div>
        </li>
        <li className="ic-EmptyStateList__Item">
          <div className="ic-EmptyStateList__BillboardWrapper">
            <a href={importURL} className="ic-EmptyStateButton">
              <IconUploadLine className="ic-EmptyStateButton__SVG" />
              <span className="ic-EmptyStateButton__Text">
                {I18n.t('Add existing content')}
              </span>
            </a>
          </div>
        </li>
      </ul>
    )
  }
}
