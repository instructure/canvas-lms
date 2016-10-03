define([
  'react',
  'i18n!appointment_groups',
  'instructure-ui/Button',
  'instructure-ui/Grid'
], (React, I18n, {default: Button}, {default: Grid, GridCol, GridRow}) => {

  class ContextSelector extends React.Component {
    static propTypes = {
      appointmentGroup: React.PropTypes.object,
      contexts: React.PropTypes.array,
      className: React.PropTypes.string
    };

    constructor () {
      super();
      this.state = {
        buttonText: I18n.t('Select Calendars'),
        showDropdown: false,
        selectedContexts: []
      };
    }

    handleContextSelectorButtonClick = (e) => {
      e.preventDefault();
      this.setState({
        showDropdown: !this.state.showDropdown
      });
    }

    handleDoneClick = (e) => {
      e.preventDefault();
      this.setState({
        showDropdown: false
      });
    }

    renderListItems () {
      return null;
    }

    render () {
      const classes = (this.props.className) ? `ContextSelector ${this.props.className}` :
                                               'ContextSelector';

      return (
        <div className={classes} {...this.props}>
          <Button
            onClick={this.handleContextSelectorButtonClick}
          >
            {this.state.buttonText}
          </Button>
          {
            this.state.showDropdown && (
              <div className="ContextSelector__Dropdown">
                <Grid>
                  <GridRow hAlign="start">
                    <GridCol>
                      {this.renderListItems}
                    </GridCol>
                  </GridRow>
                  <GridRow hAlign="end">
                    <GridCol width="auto">
                      <Button
                        onClick={this.handleDoneClick}
                        size="small"
                      >
                        {I18n.t('Done')}
                      </Button>
                    </GridCol>
                  </GridRow>
                </Grid>
              </div>
            )
          }
        </div>
      );
    }
  }

  return ContextSelector;
});
