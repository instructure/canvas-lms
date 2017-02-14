define([
  'react',
  'instructure-icons/react/Solid/IconMoreSolid',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/Typography',
  'i18n!gradebook'
], (
  React, { default: IconMoreSolid }, { MenuItem }, { default: PopoverMenu }, { default: ScreenReaderContent },
  { default: Typography }, I18n
) => {
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

  return TotalGradeColumnHeader;
});
