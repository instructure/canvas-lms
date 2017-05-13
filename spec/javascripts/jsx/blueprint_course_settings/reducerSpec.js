import actions from 'jsx/blueprint_course_settings/actions'
import reducer from 'jsx/blueprint_course_settings/reducer'
import sampleData from './sampleData'

QUnit.module('Course Blueprint Settings reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('sets courses on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess(sampleData.courses))
  deepEqual(newState.courses, sampleData.courses)
})

test('sets existingAssociations on LOAD_LISTINGS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess(sampleData.courses))
  deepEqual(newState.existingAssociations, sampleData.courses)
})

test('adds associations to existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const existing = [sampleData.courses[0]]
  const added = [sampleData.courses[1]]
  const newState = reduce(actions.saveAssociationsSuccess({ added }), { existingAssociations: existing })
  deepEqual(newState.existingAssociations, sampleData.courses)
})

test('removes associations froms existingAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({ removed: ['1'] }), { existingAssociations: sampleData.courses })
  deepEqual(newState.existingAssociations, [sampleData.courses[1]])
})

test('resets addedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  deepEqual(newState.addedAssociations, [])
})

test('resets addedAssociations on CLEAR_ASSOCIATIONS', () => {
  const newState = reduce(actions.clearAssociations())
  deepEqual(newState.addedAssociations, [])
})

test('adds associations to addedAssociations on ADD_COURSE_ASSOCIATIONS', () => {
  const existing = [sampleData.courses[0]]
  const added = [sampleData.courses[1]]
  const newState = reduce(actions.addCourseAssociations(added), { addedAssociations: existing })
  deepEqual(newState.addedAssociations, sampleData.courses)
})

test('removes associations from addedAssociations on UNDO_ADD_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.undoAddCourseAssociations(['1']), { addedAssociations: sampleData.courses })
  deepEqual(newState.addedAssociations, [sampleData.courses[1]])
})

test('resets removedAssociations on CLEAR_ASSOCIATIONS', () => {
  const newState = reduce(actions.clearAssociations())
  deepEqual(newState.removedAssociations, [])
})

test('resets removedAssociations on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  deepEqual(newState.removedAssociations, [])
})

test('adds associations to removedAssociations on REMOVE_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.removeCourseAssociations(['1']), { removedAssociations: ['2'] })
  deepEqual(newState.removedAssociations, ['2', '1'])
})

test('removes associations from removedAssociations on UNDO_REMOVE_COURSE_ASSOCIATIONS', () => {
  const newState = reduce(actions.undoRemoveCourseAssociations(['1']), { removedAssociations: ['1', '2'] })
  deepEqual(newState.removedAssociations, ['2'])
})

test('sets hasLoadedCourses to true on on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess({}))
  equal(newState.hasLoadedCourses, true)
})

test('sets isLoadingCourses to true on on LOAD_COURSES_START', () => {
  const newState = reduce(actions.loadCoursesStart())
  equal(newState.isLoadingCourses, true)
})

test('sets isLoadingCourses to false on on LOAD_COURSES_SUCCESS', () => {
  const newState = reduce(actions.loadCoursesSuccess({}))
  equal(newState.isLoadingCourses, false)
})

test('sets isLoadingCourses to false on on LOAD_COURSES_FAIL', () => {
  const newState = reduce(actions.loadCoursesFail())
  equal(newState.isLoadingCourses, false)
})

test('sets hasLoadedAssociations to true on on LOAD_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess([]))
  equal(newState.hasLoadedAssociations, true)
})

test('sets isLoadingAssociations to true on on LOAD_ASSOCIATIONS_START', () => {
  const newState = reduce(actions.loadAssociationsStart())
  equal(newState.isLoadingAssociations, true)
})

test('sets isLoadingAssociations to false on on LOAD_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.loadAssociationsSuccess([]))
  equal(newState.isLoadingAssociations, false)
})

test('sets isLoadingAssociations to false on on LOAD_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.loadAssociationsFail())
  equal(newState.isLoadingAssociations, false)
})

test('sets isSavingAssociations to true on on SAVE_ASSOCIATIONS_START', () => {
  const newState = reduce(actions.saveAssociationsStart())
  equal(newState.isSavingAssociations, true)
})

test('sets isSavingAssociations to false on on SAVE_ASSOCIATIONS_SUCCESS', () => {
  const newState = reduce(actions.saveAssociationsSuccess({}))
  equal(newState.isSavingAssociations, false)
})

test('sets isSavingAssociations to false on on SAVE_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.saveAssociationsFail())
  equal(newState.isSavingAssociations, false)
})

test('sets error on LOAD_COURSES_FAIL', () => {
  const newState = reduce(actions.loadCoursesFail(new Error('Uh oh! Error Happened!')))
  deepEqual(newState.errors, ['Uh oh! Error Happened!'])
})

test('sets error on LOAD_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.loadAssociationsFail(new Error('Uh oh! Error Happened!')))
  deepEqual(newState.errors, ['Uh oh! Error Happened!'])
})

test('sets error on SAVE_ASSOCIATIONS_FAIL', () => {
  const newState = reduce(actions.saveAssociationsFail(new Error('Uh oh! Error Happened!')))
  deepEqual(newState.errors, ['Uh oh! Error Happened!'])
})

test('sets isLoadingBeginMigration to true on on BEGIN_MIGRATION_START', () => {
  const newState = reduce(actions.beginMigrationStart())
  equal(newState.isLoadingBeginMigration, true)
})

test('sets isLoadingBeginMigration to false on on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.isLoadingBeginMigration, false)
})

test('sets isLoadingBeginMigration to false on on BEGIN_MIGRATION_FAIL', () => {
  const newState = reduce(actions.beginMigrationFail())
  equal(newState.isLoadingBeginMigration, false)
})

test('sets hasCheckedMigration to true on on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.hasCheckedMigration, true)
})

test('sets hasCheckedMigration to true on on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.hasCheckedMigration, true)
})

test('sets isCheckinMigration to true on on CHECK_MIGRATION_START', () => {
  const newState = reduce(actions.checkMigrationStart())
  equal(newState.isCheckinMigration, true)
})

test('sets isCheckinMigration to false on on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.isCheckinMigration, false)
})

test('sets isCheckinMigration to false on on CHECK_MIGRATION_FAIL', () => {
  const newState = reduce(actions.checkMigrationFail())
  equal(newState.isCheckinMigration, false)
})

test('sets migrationStatus to true on on BEGIN_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.beginMigrationSuccess({ workflow_state: 'queued' }))
  equal(newState.migrationStatus, 'queued')
})

test('sets migrationStatus to true on on CHECK_MIGRATION_SUCCESS', () => {
  const newState = reduce(actions.checkMigrationSuccess('queued'))
  equal(newState.migrationStatus, 'queued')
})
