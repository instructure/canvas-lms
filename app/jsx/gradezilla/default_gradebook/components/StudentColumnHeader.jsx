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

  class StudentColumnHeader extends React.Component {
    render () {
      return (
        <div className="Gradebook__ColumnHeaderContent">
          <span className="Gradebook__ColumnHeaderDetail">
            <Typography weight="normal" style="normal" size="small">
              { I18n.t('Student Name') }
            </Typography>
          </span>

          <PopoverMenu
            zIndex="9999"
            trigger={
              <span className="Gradebook__ColumnHeaderAction">
                <Typography weight="bold" style="normal" size="large" color="brand">
                  <IconMoreSolid title={I18n.t('Student Name Options')} />
                </Typography>
              </span>
            }
          >
            <MenuItem>Item 1</MenuItem>
            <MenuItem>Item 2</MenuItem>
            <MenuItem>Item 3</MenuItem>
          </PopoverMenu>
        </div>
      );
    }
  }

  return StudentColumnHeader;
});
