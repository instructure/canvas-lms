define([
  'jquery',
  'react',
  'instructure-icons/react/Solid/IconMiniArrowDownSolid',
  'instructure-ui/Button',
  'instructure-ui/Link',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Typography',
  'jsx/gradezilla/shared/GradebookExportManager',
  'timezone',
  'jsx/shared/helpers/dateHelper',
  'i18n!gradebook',
  'compiled/jquery.rails_flash_notifications'
], (
  $, React, { default: IconMiniArrowDownSolid }, { default: Button }, { default: Link },
  { MenuItem, MenuItemSeparator }, { default: PopoverMenu }, { default: Typography },
  GradebookExportManager, tz, DateHelper, I18n
) => {
  const { bool, shape, string } = React.PropTypes;

  class ActionMenu extends React.Component {
    static defaultProps = {
      lastExport: undefined,
      attachment: undefined
    };

    static propTypes = {
      gradebookIsEditable: bool.isRequired,
      contextAllowsGradebookUploads: bool.isRequired,
      gradebookImportUrl: string.isRequired,

      currentUserId: string.isRequired,
      gradebookExportUrl: string.isRequired,

      lastExport: shape({
        progressId: string.isRequired,
        workflowState: string.isRequired,
      }),

      attachment: shape({
        id: string.isRequired,
        downloadUrl: string.isRequired,
        updatedAt: string.isRequired
      })
    };

    static downloadableLink (url) {
      return `${url}&download_frd=1`;
    }

    static gotoUrl (url) {
      window.location.href = url;
    }

    static initialState = {
      exportInProgress: false
    };

    constructor (props) {
      super(props);

      this.state = ActionMenu.initialState;
    }

    componentWillMount () {
      const existingExport = this.getExistingExport();

      this.exportManager = new GradebookExportManager(this.props.gradebookExportUrl, this.props.currentUserId, existingExport);
    }

    componentWillUnmount () {
      if (this.exportManager) this.exportManager.clearMonitor();
    }

    getExistingExport () {
      if (!(this.props.lastExport && this.props.attachment)) return undefined;
      if (!(this.props.lastExport.progressId && this.props.attachment.id)) return undefined;

      return {
        progressId: this.props.lastExport.progressId,
        attachmentId: this.props.attachment.id,
        workflowState: this.props.lastExport.workflowState
      };
    }

    setExportInProgress (status) {
      this.setState({ exportInProgress: !!status });
    }

    handleExport () {
      this.setExportInProgress(true);
      $.flashMessage(I18n.t('Gradebook export started'));

      return this.exportManager.startExport().then((resolution) => {
        this.setExportInProgress(false);

        const attachmentUrl = resolution.attachmentUrl;
        const updatedAt = new Date(resolution.updatedAt);

        const previousExport = {
          label: `${I18n.t('New Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
          attachmentUrl: ActionMenu.downloadableLink(attachmentUrl)
        };

        this.setState({ previousExport });

        // Since we're still on the page, let's automatically download the CSV for them as well
        ActionMenu.gotoUrl(attachmentUrl);
      }).catch((reason) => {
        this.setExportInProgress(false);

        $.flashError(I18n.t('Gradebook Export Failed: %{reason}', { reason }));
      });
    }

    handleImport () {
      ActionMenu.gotoUrl(this.props.gradebookImportUrl);
    }

    disableImports () {
      return !(this.props.gradebookIsEditable && this.props.contextAllowsGradebookUploads);
    }

    lastExportFromProps () {
      if (!(this.props.lastExport && this.props.lastExport.workflowState === 'completed')) return undefined;

      return this.props.lastExport;
    }

    lastExportFromState () {
      if (this.state.exportInProgress || !this.state.previousExport) return undefined;

      return this.state.previousExport;
    }

    previousExport () {
      const completedExportFromState = this.lastExportFromState();

      if (completedExportFromState) return completedExportFromState;

      const completedLastExport = this.lastExportFromProps();
      const attachment = completedLastExport && this.props.attachment;

      if (!completedLastExport || !attachment) return undefined;

      const updatedAt = tz.parse(attachment.updatedAt);

      return {
        label: `${I18n.t('Previous Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
        attachmentUrl: ActionMenu.downloadableLink(attachment.downloadUrl)
      };
    }

    exportInProgress () {
      return this.state.exportInProgress;
    }

    renderPreviousExports () {
      const previousExport = this.previousExport();

      if (!previousExport) return '';

      const lastExportDescription = previousExport.label;
      const downloadFrdUrl = previousExport.attachmentUrl;

      const previousMenu = (
        <MenuItem key="previousExport" onSelect={() => { ActionMenu.gotoUrl(downloadFrdUrl) }}>
          <span data-menu-id="previous-export">{lastExportDescription}</span>
        </MenuItem>
      );

      return [
        (<MenuItemSeparator key="previousExportSeparator" />),
        previousMenu
      ];
    }

    render () {
      const buttonTypographyProps = {
        weight: 'normal',
        style: 'normal',
        size: 'medium',
        color: 'primary'
      };

      return (
        <PopoverMenu
          zIndex="9999"
          trigger={
            <Button variant="link">
              <Typography {...buttonTypographyProps}>
                { I18n.t('Actions') }<IconMiniArrowDownSolid />
              </Typography>
            </Button>
          }
        >
          <MenuItem disabled={this.disableImports()} onSelect={() => { this.handleImport() }}>
            <span data-menu-id="import">{ I18n.t('Import') }</span>
          </MenuItem>
          <MenuItem disabled={this.exportInProgress()} onSelect={() => { this.handleExport() }}>
            <span data-menu-id="export">
              { this.exportInProgress() ? I18n.t('Export in progress') : I18n.t('Export') }
            </span>
          </MenuItem>
          { [...this.renderPreviousExports()] }
        </PopoverMenu>
      );
    }
  }

  return ActionMenu;
});
