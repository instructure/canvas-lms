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
import {arrayOf, func, objectOf, shape, string} from 'prop-types'
import formatMessage from 'format-message'

import {Alert} from '@instructure/ui-alerts'
import {IconButton} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

import ClosedCaptionCreatorRow from './ClosedCaptionCreatorRow'

// TODO:
//   - Limit file creation

export default class ClosedCaptionPanel extends Component {
  static propTypes = {
    liveRegion: func.isRequired,
    subtitles: arrayOf(
      shape({
        locale: string.isRequired,
        file: shape({name: string.isRequired}).isRequired
      })
    ),
    updateSubtitles: func.isRequired,
    uploadMediaTranslations: shape({
      UploadMediaStrings: objectOf(string),
      SelectStrings: objectOf(string)
    }).isRequired,
    languages: arrayOf(
      shape({
        id: string,
        language: string
      })
    ).isRequired
  }

  constructor(props) {
    super(props)

    this.state = {
      addingNewClosedCaption: !props?.subtitles?.length, // if there are none, show the + button
      newSelectedFile: null,
      newSelectedLanguage: null,
      lastDeletedCCIndex: -1,
      subtitles: props.subtitles || [],
      announcement: null
    }
    this._addButtonRef = React.createRef()
    this._newCreatorRef = React.createRef()
    this._nextCCRef = React.createRef()
  }

  componentDidUpdate() {
    if (document.activeElement === document.body) {
      // where focus goes when it's lost
      if (this._newCreatorRef.current) {
        this._newCreatorRef.current.focus()
      } else if (this._nextCCRef.current) {
        this._nextCCRef.current.focus()
      } else {
        this._addButtonRef.current?.focus()
      }
      // setState in componentDidUpdate is generally bad form,
      // but in this case it makes sense to clear lastDeletedCCIndex
      // here in the place where it's just been used to help direct focus.
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState(state => {
        if (state.lastDeletedCCIndex !== -1) {
          return {lastDeletedCCIndex: -1}
        }
        return null
      })
    }
  }

  newButtonClick = () => {
    this.setState({
      addingNewClosedCaption: true,
      newSelectedFile: null,
      newSelectedLanguage: null,
      announcement: null
    })
  }

  onFileSelected = newFile => {
    if (this.state.newSelectedLanguage && newFile) {
      this.setState(prevState => {
        const subtitles = prevState.subtitles.concat([
          {
            locale: prevState.newSelectedLanguage.id,
            file: newFile,
            isNew: true
          }
        ])
        this.props.updateSubtitles(subtitles)
        return {
          subtitles,
          addingNewClosedCaption: false,
          newSelectedFile: null,
          newSelectedLanguage: null,
          announcement: formatMessage(
            this.props.uploadMediaTranslations.UploadMediaStrings.ADDED_CAPTION,
            {lang: prevState.newSelectedLanguage.label}
          )
        }
      })
    } else {
      this.setState({newSelectedFile: newFile, announcement: null})
    }
  }

  onLanguageSelected = lang => {
    if (this.state.newSelectedFile) {
      this.setState(prevState => {
        const subtitles = prevState.subtitles.concat([
          {locale: lang.id, file: prevState.newSelectedFile, isNew: true}
        ])
        this.props.updateSubtitles(subtitles)
        return {
          subtitles,
          addingNewClosedCaption: false,
          newSelectedFile: null,
          newSelectedLanguage: null,
          announcement: formatMessage(
            this.props.uploadMediaTranslations.UploadMediaStrings.ADDED_CAPTION,
            {lang: lang.label}
          )
        }
      })
    } else {
      this.setState({newSelectedLanguage: lang, announcement: null})
    }
  }

  onRowDelete = locale => {
    this.setState(prevState => {
      const deletedLang = this.props.languages.findIndex(l => l.id === locale)
      const deletedCCIndex = prevState.subtitles.findIndex(s => s.locale === locale)
      const subtitles = prevState.subtitles.filter(s => s.locale !== locale)
      this.props.updateSubtitles(subtitles)
      return {
        subtitles,
        addingNewClosedCaption: subtitles.length > 0 ? prevState.addingNewClosedCaption : true,
        announcement: formatMessage(
          this.props.uploadMediaTranslations.UploadMediaStrings.DELETED_CAPTION,
          {lang: deletedLang?.label}
        ),
        lastDeletedCCIndex: deletedCCIndex
      }
    })
  }

  render() {
    const {ADD_NEW_CAPTION_OR_SUBTITLE} = this.props.uploadMediaTranslations.UploadMediaStrings
    return (
      <View display="inline-block" data-testid="ClosedCaptionPanel">
        {this.state.announcement && (
          <Alert
            liveRegion={this.props.liveRegion}
            screenReaderOnly
            isLiveRegionAtomic
            liveRegionPoliteness="assertive"
          >
            {this.state.announcement}
          </Alert>
        )}
        <View display="inline-block">
          {this.state.subtitles.map((cc, index) => (
            <ClosedCaptionCreatorRow
              ref={index === this.state.lastDeletedCCIndex ? this._nextCCRef : undefined}
              key={cc.locale}
              liveRegion={this.props.liveRegion}
              uploadMediaTranslations={this.props.uploadMediaTranslations}
              onDeleteRow={this.onRowDelete}
              onLanguageSelected={this.onLanguageSelected}
              onFileSelected={this.onFileSelected}
              languages={this.props.languages}
              selectedLanguage={this.props.languages.find(l => l.id === cc.locale)}
              selectedFile={cc.file}
            />
          ))}
        </View>
        {this.state.addingNewClosedCaption ? (
          <View as="div">
            <ClosedCaptionCreatorRow
              ref={this._newCreatorRef}
              liveRegion={this.props.liveRegion}
              uploadMediaTranslations={this.props.uploadMediaTranslations}
              onDeleteRow={this.onRowDelete}
              onLanguageSelected={this.onLanguageSelected}
              onFileSelected={this.onFileSelected}
              languages={this.props.languages.filter(candidate_lang => {
                // remove already selected languages form the list
                return !this.state.subtitles.find(st => st.locale === candidate_lang.id)
              })}
              selectedLanguage={this.state.newSelectedLanguage}
              selectedFile={this.state.newSelectedFile}
            />
          </View>
        ) : (
          <div style={{position: 'relative', textAlign: 'center'}}>
            <IconButton
              ref={this._addButtonRef}
              shape="circle"
              color="primary"
              screenReaderLabel={ADD_NEW_CAPTION_OR_SUBTITLE}
              onClick={this.newButtonClick}
              margin="x-small auto"
            >
              <IconAddLine />
            </IconButton>
          </div>
        )}
      </View>
    )
  }
}
