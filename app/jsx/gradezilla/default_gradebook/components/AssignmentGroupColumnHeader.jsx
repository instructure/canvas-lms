import React from 'react'
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import { MenuItem } from 'instructure-ui/Menu'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import Typography from 'instructure-ui/Typography'
import I18n from 'i18n!gradebook'
  // TODO: remove this rule when this component begins using internal state
  /* eslint-disable react/prefer-stateless-function */

  class AssignmentGroupColumnHeader extends React.Component {
    static propTypes = {
      assignmentGroup: React.PropTypes.shape({
        name: React.PropTypes.string.isRequired,
        groupWeight: React.PropTypes.number
      }).isRequired,
      weightedGroups: React.PropTypes.bool.isRequired
    };

    renderWeight () {
      if (!this.props.weightedGroups) return '';

      const weightValue = this.props.assignmentGroup.groupWeight || 0;
      const weightStr = I18n.n(weightValue, { precision: 2, percentage: true });
      const weightDesc = I18n.t('%{weight} of grade', { weight: weightStr });

      return (
        <Typography weight="normal" fontStyle="normal" size="x-small">
          {weightDesc}
        </Typography>
      );
    }

    render () {
      const optionsTitle = I18n.t('%{name} Options', { name: this.props.assignmentGroup.name });

      return (
        <div className="Gradebook__ColumnHeaderContent">
          <span className="Gradebook__ColumnHeaderDetail">
            {this.props.assignmentGroup.name}
            {this.renderWeight()}
          </span>

          <PopoverMenu
            zIndex="9999"
            trigger={
              <span className="Gradebook__ColumnHeaderAction">
                <Typography weight="bold" fontStyle="normal" size="large" color="brand">
                  <IconMoreSolid title={optionsTitle} />
                </Typography>
              </span>
            }
          >
            <MenuItem>Placeholder Item 1</MenuItem>
            <MenuItem>Placeholder Item 2</MenuItem>
            <MenuItem>Placeholder Item 3</MenuItem>
          </PopoverMenu>
        </div>
      );
    }
  }

export default AssignmentGroupColumnHeader
