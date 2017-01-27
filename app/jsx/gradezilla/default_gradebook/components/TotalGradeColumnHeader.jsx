import React from 'react'
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import { MenuItem } from 'instructure-ui/Menu'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import Typography from 'instructure-ui/Typography'
import I18n from 'i18n!gradebook'
  /* eslint-disable react/style-prop-object */

  // TODO: remove this rule when this component begins using internal state
  /* eslint-disable react/prefer-stateless-function */

  class TotalGradeColumnHeader extends React.Component {
    render () {
      return (
        <div className="Gradebook__ColumnHeaderContent">
          <span className="Gradebook__ColumnHeaderDetail">
            <Typography weight="normal" fontStyle="normal" size="small">
              { I18n.t('Total') }
            </Typography>
          </span>

          <PopoverMenu
            zIndex="9999"
            trigger={
              <span className="Gradebook__ColumnHeaderAction">
                <Typography weight="bold" fontStyle="normal" size="large" color="brand">
                  <IconMoreSolid title={I18n.t('Total Options')} />
                </Typography>
              </span>
            }
          >
            <MenuItem>{ I18n.t('Message Students Who...') }</MenuItem>
            <MenuItem>{ I18n.t('Display as Points') }</MenuItem>
            <MenuItem>{ I18n.t('Move to End') }</MenuItem>
            <MenuItem>{ I18n.t('Adjust Final Grade') }</MenuItem>
          </PopoverMenu>
        </div>
      );
    }
  }

export default TotalGradeColumnHeader
