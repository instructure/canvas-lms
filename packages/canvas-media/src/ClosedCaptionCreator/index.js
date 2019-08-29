/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, {Component} from 'react'

import {Flex} from '@instructure/ui-layout'

import AddClosedCaptionButton from './AddClosedCaptionButton'
import ClosedCaptionCreatorRow from './ClosedCaptionCreatorRow'
import ClosedCaptionHeader from './ClosedCaptionHeader'
import ClosedCaptionRow from './ClosedCaptionRow'
import shortId from '../shared/shortid'

// TODO:
//   - Limit file creation
//   - Ellipsis long file names
//   - Get current subtitles from API
//   - Upload new subtitles via API
//   - Download existing subtitles via download button
//   - Delete existing subtitles locally and via API
//   - Figure out fix for dynamic translations (ex: 'delete %{filename}')

export default class ClosedCaptionPanel extends Component {
  state = {
    addingNewClosedCaption: true,
    newSelectedFile: null,
    newSelectedLanguage: null,
    subtitles: []
  }

  newButtonClick = () => {
    this.setState({
      addingNewClosedCaption: true,
      newSelectedFile: null,
      newSelectedLanguage: null
    })
  }

  onFileSelected = e => {
    if (this.state.newSelectedLanguage) {
      e.persist()
      this.setState(prevState => {
        return {
          subtitles: prevState.subtitles.concat([
            {id: shortId(), language: prevState.newSelectedLanguage, file: e.target.files[0]}
          ]),
          addingNewClosedCaption: false,
          newSelectedFile: null,
          newSelectedLanguage: null
        }
      })
    } else {
      this.setState({newSelectedFile: e.target.files[0]})
    }
  }

  onOptionSelected = option => {
    if (this.state.newSelectedFile) {
      this.setState(prevState => {
        return {
          subtitles: prevState.subtitles.concat([
            {id: shortId(), language: option, file: prevState.newSelectedFile}
          ]),
          addingNewClosedCaption: false,
          newSelectedFile: null,
          newSelectedLanguage: null
        }
      })
    } else {
      this.setState({newSelectedLanguage: option})
    }
  }

  render() {
    const {
      CLOSED_CAPTIONS_LANGUAGE_HEADER,
      CLOSED_CAPTIONS_FILE_NAME_HEADER,
      CLOSED_CAPTIONS_ACTIONS_HEADER,
      CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER
    } = this.props.uploadMediaTranslations.UploadMediaStrings

    return (
      <div>
        <Flex direction="column">
          <ClosedCaptionHeader
            CLOSED_CAPTIONS_LANGUAGE_HEADER={CLOSED_CAPTIONS_LANGUAGE_HEADER}
            CLOSED_CAPTIONS_FILE_NAME_HEADER={CLOSED_CAPTIONS_FILE_NAME_HEADER}
            CLOSED_CAPTIONS_ACTIONS_HEADER={CLOSED_CAPTIONS_ACTIONS_HEADER}
          />
          {this.state.subtitles.map(cc => (
            <ClosedCaptionRow key={cc.id} closedCaption={cc} />
          ))}
          {this.state.addingNewClosedCaption ? (
            <ClosedCaptionCreatorRow
              uploadMediaTranslations={this.props.uploadMediaTranslations}
              onOptionSelected={this.onOptionSelected}
              liveRegion={this.props.liveRegion}
              onFileSelected={this.onFileSelected}
              languages={this.props.languages}
              selectedFileName={this.state.newSelectedFile ? this.state.newSelectedFile.name : ''}
              fileSelected={this.state.newSelectedFile}
              renderTrashButton={this.state.subtitles.length > 0}
              trashButtonOnClick={() =>
                this.setState({
                  addingNewClosedCaption: false,
                  newSelectedFile: null,
                  newSelectedLanguage: null
                })
              }
            />
          ) : null}
        </Flex>
        <AddClosedCaptionButton
          CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER={CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER}
          disabled={this.state.addingNewClosedCaption}
          newButtonClick={this.newButtonClick}
        />
      </div>
    )
  }
}
