import React, { useState, useRef, useEffect, useMemo } from 'react'
import { Link } from '@instructure/ui-link'
import { Text } from '@instructure/ui-text'
import { View } from '@instructure/ui-view'
import { useScope as useI18nScope } from '@canvas/i18n'
import ItemAssignToTray, { getEveryoneOption } from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'
import { IconEditLine } from '@instructure/ui-icons'
import _ from 'underscore'
import { forEach, map } from 'lodash'
import TokenActions from './TokenActions'
import { sortedRowKeys, getAllOverrides, datesFromOverride } from '../util/overridesUtils'
import { string, func, array, number, oneOfType } from 'prop-types'

const I18n = useI18nScope('DueDateOverrideView')

const DifferentiatedModulesLink = ({ onSave, assignmentName, assignmentId, type, pointsPossible, overrides, defaultSectionId }) => {
    const [open, setOpen] = useState(false)
    const [stagedCards, setStagedCards] = useState();
    const [stagedOverrides, setStagedOverrides] = useState(overrides);
    const [disabledOptionIds, setDisabledOptionIds] = useState([])
    const linkRef = useRef();

    useEffect(() => {
        let index = 0
        const overridesByKey = _.groupBy(stagedOverrides, override => {
            override.set('rowKey', override.attributes.rowKey ?? override.combinedDates())

            return override.get('rowKey')
        })
        const parsedOverrides = _.chain(overridesByKey)
            .map((overrides, key) => {
                const datesForGroup = datesFromOverride(overrides[0])
                index++
                index = stagedCards?.[key]?.index ?? overrides?.[0]?.index ?? index
                return [key, { overrides, dates: datesForGroup, persisted: true, index }]
            })
            .object()
            .value()
        setStagedCards(parsedOverrides)
    }, [stagedOverrides])

    const cards = useMemo(() => {
        let selectedOptionIds = []
        const everyoneOptionKey = getEveryoneOption(stagedCards?.length > 1).id
        const cards = map(sortedRowKeys(stagedCards), cardId => {
            let defaultOptions = []
            const row = stagedCards[cardId]
            const overrides = row.overrides || []
            const dates = row.dates || {}
            overrides.forEach(override => {
                if (override?.attributes?.course_section_id === defaultSectionId) {
                    row.index=0
                    defaultOptions.push(everyoneOptionKey)
                    selectedOptionIds.push(...defaultOptions)
                } else {
                    const studentOverrides =
                        override?.attributes?.student_ids?.map((studentId) => `student-${studentId}`) ?? []
                    defaultOptions.push(...studentOverrides)
                    if (override?.attributes?.course_section_id) {
                        defaultOptions.push(`section-${override.attributes.course_section_id}`)
                    }
                    selectedOptionIds.push(...defaultOptions)
                }
            })

            return {
                key: cardId,
                isValid: defaultOptions.length > 0,
                hasAssignees: defaultOptions.length > 0,
                due_at: dates.due_at,
                unlock_at: dates.unlock_at,
                lock_at: dates.lock_at,
                selectedAssigneeIds: defaultOptions,
                defaultOptions,
                overrideId: row.id,
                index: row.index
            }
        })
        setDisabledOptionIds(selectedOptionIds)
        const sortedCards = cards.sort((cardA, cardB) => cardA.index - cardB.index)

        return sortedCards
    }, [stagedCards])

    const handleClose = () => setOpen(false)

    const generateCard = (cardId, newOverrides, rowDates) => {
        const newRow = TokenActions.handleTokenAdd({}, newOverrides, cardId, rowDates)[0]
        delete newRow.attributes.student_ids;
        newRow.draft = true
        newRow.index = stagedOverrides.length + 1
        const newStageOverrides = [...stagedOverrides, newRow]
        setStagedOverrides(newStageOverrides)
    }

    const handleCardRemove = cardId => {
        const newStageOverrides = stagedOverrides.filter(override => override.attributes.rowKey.toString() !== cardId)
        setStagedOverrides(newStageOverrides)
    }

    const updateRow = (cardId, newOverrides, rowDates) => {
        const tmp = {}
        const dates = rowDates || datesFromOverride(newOverrides[0])
        const currentIndex = stagedCards[cardId]?.index
        tmp[cardId] = { overrides: newOverrides, dates, persisted: false, index: currentIndex }

        const newRows = _.extend({ ...stagedCards }, tmp)
        setStagedCards(newRows);
    }

    const addOverride = () => {
        const cardsCount = stagedOverrides.length + 1;
        generateCard(cardsCount, [], {})
    }

    const handleChange = (cardId, newAssignee, deletedAssignees) => {
        if (newAssignee) {
            handleAssigneeAddition(cardId, newAssignee)
        }
        if (deletedAssignees.length > 0) {
            forEach(deletedAssignees, deleted => {
                handleAssigneeDeletion(cardId, deleted)
            })
        }
    }

    const handleDatesUpdate = (cardId, dateType, newDate) => {
        const row = stagedCards[cardId]
        const oldOverrides = row.overrides
        const oldDates = row.dates

        const newOverrides = map(oldOverrides, override => {
            override.set(dateType, newDate)
            return override
        })

        const tmp = {}
        tmp[dateType] = newDate
        const newDates = _.extend(oldDates, tmp)

        updateRow(cardId, newOverrides, newDates)
    }

    const handleAssigneeAddition = (cardId, newToken) => {
        const row = stagedCards[cardId]
        const newOverridesForRow = TokenActions.handleTokenAdd(newToken, row?.overrides ?? {}, cardId, row.dates)
        const newOverride = newOverridesForRow[newOverridesForRow.length - 1]
        setStagedOverrides([...stagedOverrides, newOverride])
    }

    const handleAssigneeDeletion = (cardId, tokenToRemove) => {
        const row = stagedCards[cardId]
        const tmpOverrides = stagedOverrides.filter(({attributes}) => attributes.rowKey !== cardId)
        let newCardOverrides = TokenActions.handleTokenRemove(tokenToRemove, row?.overrides ?? {})
        if(newCardOverrides.length === 0){
            const emptyRow = TokenActions.handleTokenAdd({}, newCardOverrides, cardId, row.dates)[0]
            delete emptyRow.attributes.student_ids;
            emptyRow.index = row.index
            newCardOverrides = [emptyRow]
        }

        setStagedOverrides([...tmpOverrides, ...newCardOverrides])
    }

    const handleSave = () => {
        const newOverrides = getAllOverrides(stagedCards).filter(row => row.attributes.course_section_id || row.attributes.student_ids);
        setStagedOverrides(newOverrides);
        onSave(newOverrides);
        setOpen(false);
    }

    return (
        <>
            <View display="flex">
                <View as="div" margin="medium none" width="25px">
                    <IconEditLine size="x-small" color="primary" />
                </View>
                <Link
                    margin="medium none"
                    data-testid="manage-assign-to"
                    isWithinText={false}
                    ref={ref => linkRef.current = ref}
                    onClick={() => setOpen(!open)}
                >
                    <View as="div">
                        {I18n.t('Manage Assign To')}
                        <Text as="div" color="secondary" size="small">
                            {I18n.t('%{overridesCount} Assigned', { overridesCount: stagedOverrides.filter(override => !override.draft).length })}
                        </Text>
                    </View>
                </Link>
            </View>
            <ItemAssignToTray
                open={open}
                onClose={handleClose}
                onDismiss={() => {
                    handleClose()
                    linkRef.current.focus()
                }}
                courseId={ENV.COURSE_ID}
                itemName={assignmentName}
                itemType={type}
                iconType={type}
                itemContentId={assignmentId}
                pointsPossible={pointsPossible}
                locale={ENV.LOCALE || 'en'}
                timezone={ENV.TIMEZONE || 'UTC'}
                defaultCards={cards}
                defaultSectionId={defaultSectionId}
                defaultDisabledOptionIds={disabledOptionIds}
                onSave={handleSave}
                onAddCard={addOverride}
                onAssigneesChange={handleChange}
                onDatesChange={handleDatesUpdate}
                onCardRemove={handleCardRemove}
            />
        </>
    )
}

DifferentiatedModulesLink.propTypes = {
    onSave: func.isRequired,
    assignmentName: string.isRequired,
    assignmentId: string.isRequired,
    type: string.isRequired,
    pointsPossible: oneOfType([number, string]),
    overrides: array.isRequired,
    defaultSectionId: oneOfType([number, string])
}

export default DifferentiatedModulesLink;