/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useCallback} from 'react'
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {createRating} from '@canvas/outcomes/react/hooks/useRatings'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import ProficiencyRating from '../MasteryScale/ProficiencyRating'

const I18n = useI18nScope('OutcomeManagement')

const ratingsShape = PropTypes.shape({
  key: PropTypes.string,
  description: PropTypes.string,
  points: PropTypes.number,
  descriptionError: PropTypes.string,
  pointsError: PropTypes.string,
  focusField: PropTypes.string,
})

const masteryPointsShape = PropTypes.shape({
  value: PropTypes.number,
  error: PropTypes.string,
})

const Ratings = ({
  ratings,
  masteryPoints,
  onChangeRatings,
  onChangeMasteryPoints,
  canManage,
  masteryInputRef,
  clearRatingsFocus,
}) => {
  const {isMobileView} = useCanvasContext()
  const addRow = () => {
    let points = 0.0
    const last = ratings[ratings.length - 1]

    if (last) {
      points = last.points - 1.0
    }

    if (points < 0.0 || Number.isNaN(points)) {
      points = 0.0
    }
    // when a rating is added, set the focusField value to the new rating's description field
    onChangeRatings([...clearFocusFields(), createRating('', points, false, 'description')])
  }

  const clearFocusFields = () => ratings.map(r => ({...r, focusField: null}))

  const onRatingFieldChange = (field, value, index) => {
    onChangeRatings(currentRatings => {
      let ratingsCopy = [...currentRatings]

      const newRating = {
        ...ratingsCopy[index],
        [field]: value,
      }

      const oldRating = ratingsCopy[index]

      // if mastery was set to true here
      // remove mastery from all
      if (newRating.mastery && !oldRating.mastery) {
        ratingsCopy = ratingsCopy.map(r => ({
          ...r,
          mastery: false,
        }))
      }

      ratingsCopy.splice(index, 1, newRating)

      return ratingsCopy
    })
  }

  const handleDelete = useCallback(
    currentIndex => {
      onChangeRatings(currentRatings => {
        const ratingsCopy = [...currentRatings]

        const currentRating = currentRatings[currentIndex]
        ratingsCopy.splice(currentIndex, 1)

        if (currentRating.mastery) {
          const newMasteryIndex = Math.max(currentIndex - 1, 0)
          ratingsCopy[newMasteryIndex] = {
            ...ratingsCopy[newMasteryIndex],
            mastery: true,
          }
        }

        currentIndex === 0 && ratingsCopy.length > 1
          ? (ratingsCopy[currentIndex].focusField = 'trash')
          : ratingsCopy.length === 1
          ? (ratingsCopy[0].focusField = 'points')
          : (ratingsCopy[currentIndex - 1].focusField = 'trash')

        return ratingsCopy
      })
    },
    [onChangeRatings]
  )

  const handleMasteryPointsChange = e => onChangeMasteryPoints(e.target.value)

  const renderMasteryPointsInput = () => (
    <Flex alignItems="start">
      <Flex.Item>
        <div
          className="points individualOutcome"
          style={{paddingTop: '0px'}}
          data-testid="mastery-points-input"
        >
          <TextInput
            type="text"
            messages={masteryPoints.error ? [{text: masteryPoints.error, type: 'error'}] : null}
            renderLabel={
              <ScreenReaderContent>{I18n.t('Change mastery points')}</ScreenReaderContent>
            }
            onChange={handleMasteryPointsChange}
            defaultValue={I18n.n(masteryPoints.value)}
            width={isMobileView ? '3rem' : '4rem'}
            inputRef={masteryInputRef}
          />
        </div>
      </Flex.Item>
      <Flex.Item>
        <div style={{paddingTop: '0.5rem', paddingLeft: isMobileView ? '0.60rem' : '0.75rem'}}>
          <Text weight="bold">{I18n.t('points')}</Text>
        </div>
      </Flex.Item>
    </Flex>
  )

  const renderAddButton = () => (
    <IconButton
      onClick={addRow}
      withBorder={false}
      color="primary"
      size="medium"
      shape="circle"
      screenReaderLabel={I18n.t('Add Mastery Level')}
      data-testid="add-individual-rating-btn"
    >
      <IconPlusLine />
    </IconButton>
  )

  const renderDisplayMasteryPoints = () => (
    <Flex
      wrap="wrap"
      direction={isMobileView ? 'column' : 'row'}
      padding={isMobileView ? 'none small small none' : 'x-small small small none'}
    >
      <Flex.Item as="div" padding="none xx-small none none" data-testid="read-only-mastery-points">
        <Text weight="bold">{I18n.t('Mastery at:')}</Text>
      </Flex.Item>
      <Flex.Item padding={isMobileView ? 'small none none' : 'none'}>
        <Text color="primary">{I18n.t('%{points} points', {points: masteryPoints.value})}</Text>
      </Flex.Item>
    </Flex>
  )

  const renderEditMasteryPoints = () => (
    <Flex
      width="100%"
      padding={isMobileView ? 'none' : 'small small small none'}
      alignItems="start"
      justifyContent={isMobileView ? 'space-between' : 'start'}
    >
      <Flex.Item size="80%">
        {isMobileView ? (
          <Flex padding="0 small 0 0" alignItems="start">
            <Flex.Item>
              <div style={{paddingTop: '0.5rem', paddingRight: '0.60rem'}}>
                <Text weight="bold">{I18n.t('Mastery at')}</Text>
              </div>
            </Flex.Item>
            <Flex.Item>{renderMasteryPointsInput()}</Flex.Item>
          </Flex>
        ) : (
          <Flex padding="0 small 0 0" alignItems="start" textAlign="end">
            <Flex.Item size="60%">{renderAddButton()}</Flex.Item>
            <Flex.Item size="40%">
              <div style={{paddingTop: '0.5rem'}}>
                <Text weight="bold">{I18n.t('Mastery at')}</Text>
              </div>
            </Flex.Item>
          </Flex>
        )}
      </Flex.Item>
      <Flex.Item size="20%" textAlign={isMobileView ? 'end' : 'start'}>
        {isMobileView ? renderAddButton() : renderMasteryPointsInput()}
      </Flex.Item>
    </Flex>
  )

  const renderRatingDescription = description => (
    <Text>
      <PresentationContent>{description}</PresentationContent>
    </Text>
  )

  const renderRatingsPoints = points => (
    <div className={isMobileView ? '' : 'points'}>
      <View margin={isMobileView ? '0' : '0 0 0 small'}>
        <PresentationContent>
          {I18n.n(points)}

          <div className="pointsDescription view-only">{I18n.t('points')}</div>
        </PresentationContent>
      </View>
    </div>
  )

  const renderRatingsTable = () => (
    <Flex width={isMobileView ? '100%' : '65%'} padding="x-small 0">
      <Table caption="Ratings table" layout="fixed" data-testid="outcome-management-ratings-table">
        <Table.Head>
          <Table.Row themeOverride={{borderColor: 'white'}}>
            <Table.ColHeader id="rating" themeOverride={{padding: '0.5rem 0rem'}}>
              <div className="header">{I18n.t('Proficiency Rating')}</div>
            </Table.ColHeader>
            {!isMobileView && (
              <Table.ColHeader id="points" textAlign="end" themeOverride={{padding: '0.5rem 0rem'}}>
                <div className="header">{I18n.t('Points')}</div>
              </Table.ColHeader>
            )}
          </Table.Row>
        </Table.Head>
        {ratings.map(({description, points, key}) => (
          <Table.Body key={key}>
            <Table.Row themeOverride={{borderColor: 'white'}}>
              <Table.Cell themeOverride={{padding: '0.5rem 0rem'}}>
                {renderRatingDescription(description)}
              </Table.Cell>
              {!isMobileView && (
                <Table.Cell textAlign="end" themeOverride={{padding: '0.5rem 1.25rem'}}>
                  {renderRatingsPoints(points)}
                </Table.Cell>
              )}
            </Table.Row>
            {isMobileView && (
              <Table.Row themeOverride={{borderColor: 'white', padding: '0rem 0rem'}}>
                <Table.Cell themeOverride={{padding: '0.5rem 0rem'}}>
                  {renderRatingsPoints(points)}
                </Table.Cell>
              </Table.Row>
            )}
          </Table.Body>
        ))}
      </Table>
    </Flex>
  )

  return (
    <>
      <Flex
        width="100%"
        padding={isMobileView ? '0 0 small 0' : canManage ? '0 small small 0' : '0'}
        margin={canManage ? 'medium none none' : 'small none none'}
        direction={canManage ? 'row' : 'column'}
        data-testid="outcome-management-ratings"
      >
        {canManage ? (
          <>
            <Flex.Item size={isMobileView ? '75%' : canManage ? '80%' : '60%'}>
              <div className="header">{I18n.t('Proficiency Rating')}</div>
            </Flex.Item>
            {!isMobileView && (
              <Flex.Item size="10%">
                <div className="header">{I18n.t('Points')}</div>
              </Flex.Item>
            )}
          </>
        ) : (
          <>
            {renderRatingsTable()}
            {renderDisplayMasteryPoints()}
          </>
        )}
      </Flex>
      {canManage && (
        <>
          {ratings.map(
            ({key, description, descriptionError, pointsError, points, focusField}, index) => (
              <ProficiencyRating
                key={key}
                description={description}
                descriptionError={descriptionError}
                disableDelete={ratings.length === 1}
                onDelete={() => handleDelete(index)}
                onDescriptionChange={value => onRatingFieldChange('description', value, index)}
                onFocusChange={clearRatingsFocus}
                onMasteryChange={() => onRatingFieldChange('mastery', true, index)}
                onPointsChange={value => onRatingFieldChange('points', value, index)}
                focusField={focusField}
                points={points?.toString()}
                pointsError={pointsError}
                isMobileView={isMobileView}
                position={index + 1}
                canManage={canManage}
                individualOutcome={true}
              />
            )
          )}
          {renderEditMasteryPoints()}
        </>
      )}
    </>
  )
}

Ratings.propTypes = {
  ratings: PropTypes.arrayOf(ratingsShape).isRequired,
  masteryPoints: masteryPointsShape.isRequired,
  canManage: PropTypes.bool,
  onChangeRatings: PropTypes.func,
  onChangeMasteryPoints: PropTypes.func,
  masteryInputRef: PropTypes.func,
  clearRatingsFocus: PropTypes.func,
}

Ratings.defaultProps = {
  onChangeRatings: () => {},
  onChangeMasteryPoints: () => {},
  clearRatingsFocus: () => {},
  masteryInputRef: () => {},
  ratings: [],
  masteryPoints: {
    value: null,
    error: null,
  },
}

export default Ratings
