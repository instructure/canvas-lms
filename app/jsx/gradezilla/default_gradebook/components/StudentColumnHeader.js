import React from 'react'
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import { MenuItem, MenuItemGroup } from 'instructure-ui/Menu'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import Typography from 'instructure-ui/Typography'
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants'
import I18n from 'i18n!gradebook'

const { bool, func, oneOf } = React.PropTypes;
/* eslint-disable react/style-prop-object */

export default class StudentColumnHeader extends React.Component {
  static propTypes = {
    selectedSecondaryInfo: oneOf(StudentRowHeaderConstants.secondaryInfoKeys).isRequired,
    sectionsEnabled: bool.isRequired,
    onSelectSecondaryInfo: func.isRequired
  };

  constructor (props) {
    super(props);

    this.onShowSectionNames = this.onSelectSecondaryInfo.bind(this, 'section');
    this.onHideSecondaryInfo = this.onSelectSecondaryInfo.bind(this, 'none');
    this.onShowSisId = this.onSelectSecondaryInfo.bind(this, 'sis_id');
    this.onShowLoginId = this.onSelectSecondaryInfo.bind(this, 'login_id');
  }

  onSelectSecondaryInfo (secondaryInfoKey) {
    this.props.onSelectSecondaryInfo(secondaryInfoKey);
  }

  render () {
    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <Typography weight="normal" fontStyle="normal" size="small">
            { I18n.t('Student Name') }
          </Typography>
        </span>

        <PopoverMenu
          zIndex="9999"
          trigger={
            <span className="Gradebook__ColumnHeaderAction">
              <Typography weight="bold" fontStyle="normal" size="large" color="brand">
                <IconMoreSolid title={I18n.t('Student Name Options')} />
              </Typography>
            </span>
          }
        >
          <MenuItemGroup label={I18n.t('Secondary info')} data-menu-item-group-id="secondary-info">
            {
              this.props.sectionsEnabled &&
              <MenuItem
                key="section"
                data-menu-item-id="section"
                selected={this.props.selectedSecondaryInfo === 'section'}
                onSelect={this.onShowSectionNames}
              >
                {StudentRowHeaderConstants.secondaryInfoLabels.section}
              </MenuItem>
            }
            <MenuItem
              key="sis_id"
              data-menu-item-id="sis_id"
              selected={this.props.selectedSecondaryInfo === 'sis_id'}
              onSelect={this.onShowSisId}
            >
              {StudentRowHeaderConstants.secondaryInfoLabels.sis_id}
            </MenuItem>

            <MenuItem
              key="login_id"
              data-menu-item-id="login_id"
              selected={this.props.selectedSecondaryInfo === 'login_id'}
              onSelect={this.onShowLoginId}
            >
              {StudentRowHeaderConstants.secondaryInfoLabels.login_id}
            </MenuItem>

            <MenuItem
              key="none"
              data-menu-item-id="none"
              selected={this.props.selectedSecondaryInfo === 'none'}
              onSelect={this.onHideSecondaryInfo}
            >
              {StudentRowHeaderConstants.secondaryInfoLabels.none}
            </MenuItem>
          </MenuItemGroup>
        </PopoverMenu>
      </div>
    );
  }
}
