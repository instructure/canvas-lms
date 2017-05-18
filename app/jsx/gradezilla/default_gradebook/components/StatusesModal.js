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

import React from 'react';
import { func } from 'prop-types';
import Button from 'instructure-ui/lib/components/Button';
import Modal, { ModalBody, ModalFooter, ModalHeader } from 'instructure-ui/lib/components/Modal';
import Heading from 'instructure-ui/lib/components/Heading';
import I18n from 'i18n!gradebook';
import { getUserColors } from 'jsx/gradezilla/default_gradebook/stores/UserColorStore';
import { statuses, statusesTitleMap } from 'jsx/gradezilla/default_gradebook/constants/statuses';
import Typography from 'instructure-ui/lib/components/Typography';

const styles = {};
statuses.forEach((status) => {
  styles[status] = {
    backgroundColor: getUserColors().light[status]
  };
});

function renderListItems () {
  return statuses.map(status =>
    <li className="Gradebook__StatusModalListItem" key={status} style={styles[status]}>
      {statusesTitleMap[status]}
    </li>
  );
}

class StatusesModal extends React.Component {
  static propTypes = {
    onClose: func.isRequired
  };

  constructor (props) {
    super(props);

    this.state = { isOpen: false };

    this.open = this.open.bind(this);
    this.close = this.close.bind(this);

    this.bindDoneButton = (button) => { this.doneButton = button };
    this.bindCloseButton = (button) => { this.closeButton = button };
  }

  open () {
    this.setState({ isOpen: true });
  }

  close () {
    this.setState({ isOpen: false });
  }

  render () {
    const {
      state: { isOpen },
      props: { onClose },
      close,
      bindCloseButton,
      bindDoneButton
    } = this;

    return (
      <Modal
        isOpen={isOpen}
        label={I18n.t('Statuses')}
        closeButtonLabel={I18n.t('Close')}
        closeButtonRef={bindCloseButton}
        onRequestClose={close}
        onExited={onClose}
      >
        <ModalHeader>
          <Heading level="h3">{I18n.t('Statuses')}</Heading>
        </ModalHeader>

        <ModalBody>
          <ul className="Gradebook__StatusModalList">
            <Typography>
              {renderListItems()}
            </Typography>
          </ul>
        </ModalBody>

        <ModalFooter>
          <Button
            ref={bindDoneButton}
            variant="primary"
            onClick={close}
          >
            {I18n.t('Done')}
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default StatusesModal;
