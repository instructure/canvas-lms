/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import IconMiniArrowDownSolid from '@instructure/ui-icons/lib/Solid/IconMiniArrowDown'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Menu, { MenuItem, MenuItemSeparator } from '@instructure/ui-menu/lib/components/Menu'
import Text from '@instructure/ui-elements/lib/components/Text'
import GradebookExportManager from '../../../gradezilla/shared/GradebookExportManager'
import { AppLaunch } from '../../../gradezilla/SISGradePassback/PostGradesApp'
import tz from 'timezone'
import DateHelper from '../../../shared/helpers/dateHelper'
import I18n from 'i18n!gradebook'
import 'compiled/jquery.rails_flash_notifications'

const { arrayOf, bool, func, object, shape, string } = PropTypes;

  class ActionMenu extends React.Component {
    static defaultProps = {
      lastExport: undefined,
      attachment: undefined,
      postGradesLtis: [],
      publishGradesToSis: {
        publishToSisUrl: undefined
      }
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
      }),

      postGradesLtis: arrayOf(shape({
        id: string.isRequired,
        name: string.isRequired,
        onSelect: func.isRequired
      })),

      postGradesFeature: shape({
        enabled: bool.isRequired,
        store: object.isRequired,
        returnFocusTo: object
      }).isRequired,

      publishGradesToSis: shape({
        isEnabled: bool.isRequired,
        publishToSisUrl: string
      }),

      gradingPeriodId: string.isRequired
    };

    static gotoUrl (url) {
      window.location.href = url;
    }

    static initialState = {
      exportInProgress: false
    };

    constructor (props) {
      super(props);

      this.state = ActionMenu.initialState;
      this.launchPostGrades = this.launchPostGrades.bind(this);
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

      return this.exportManager.startExport(this.props.gradingPeriodId).then((resolution) => {
        this.setExportInProgress(false);

        const attachmentUrl = resolution.attachmentUrl;
        const updatedAt = new Date(resolution.updatedAt);

        const previousExport = {
          label: `${I18n.t('New Export')} (${DateHelper.formatDatetimeForDisplay(updatedAt)})`,
          attachmentUrl
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

    handlePublishGradesToSis () {
      ActionMenu.gotoUrl(this.props.publishGradesToSis.publishToSisUrl);
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
        attachmentUrl: attachment.downloadUrl
      };
    }

    exportInProgress () {
      return this.state.exportInProgress;
    }

    launchPostGrades () {
      const { store, returnFocusTo } = this.props.postGradesFeature;
      setTimeout(() => AppLaunch(store, returnFocusTo), 10);
    }

    renderPostGradesTools () {
      const tools = this.renderPostGradesLtis();

      if (this.props.postGradesFeature.enabled) {
        tools.push(this.renderPostGradesFeature());
      }

      if (tools.length) {
        tools.push(<MenuItemSeparator key="postGradesSeparator" />);
      }

      return tools;
    }

    renderPostGradesLtis () {
      return this.props.postGradesLtis.map((tool) => {
        const key = `post_grades_lti_${tool.id}`;
        return (
          <MenuItem onSelect={tool.onSelect} key={key}>
            <span data-menu-id={key}>
              {I18n.t('Sync to %{name}', {name: tool.name})}
            </span>
          </MenuItem>
        );
      });
    }

    renderPostGradesFeature () {
      const sisName = this.props.postGradesFeature.label || I18n.t('SIS');
      return (
        <MenuItem onSelect={this.launchPostGrades} key="post_grades_feature_tool">
          <span data-menu-id="post_grades_feature_tool">
            {I18n.t('Sync to %{sisName}', {sisName})}
          </span>
        </MenuItem>
      );
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

    renderPublishGradesToSis () {
      const { isEnabled, publishToSisUrl } = this.props.publishGradesToSis;

      if (!isEnabled || !publishToSisUrl) {
        return null;
      }

      return (
        <MenuItem onSelect={() => { this.handlePublishGradesToSis() }}>
          <span data-menu-id="publish-grades-to-sis">
            {I18n.t('Sync grades to SIS')}
          </span>
        </MenuItem>
      );
    }

    render () {
      const buttonTypographyProps = {
        weight: 'normal',
        style: 'normal',
        size: 'medium',
        color: 'primary'
      };
      const publishGradesToSis = this.renderPublishGradesToSis();

      return (
        <Menu
          trigger={
            <Button variant="link">
              <Text {...buttonTypographyProps}>
                { I18n.t('Actions') }<IconMiniArrowDownSolid />
              </Text>
            </Button>
          }
        >
          { this.renderPostGradesTools() }
          {publishGradesToSis}

          <MenuItem disabled={this.disableImports()} onSelect={() => { this.handleImport() }}>
            <span data-menu-id="import">{ I18n.t('Import') }</span>
          </MenuItem>

          <MenuItem disabled={this.exportInProgress()} onSelect={() => { this.handleExport() }}>
            <span data-menu-id="export">
              { this.exportInProgress() ? I18n.t('Export in progress') : I18n.t('Export') }
            </span>
          </MenuItem>

          { [...this.renderPreviousExports()] }
        </Menu>
      );
    }
  }

export default ActionMenu
