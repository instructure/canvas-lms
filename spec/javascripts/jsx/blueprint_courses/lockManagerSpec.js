import LockManager from 'jsx/blueprint_courses/lockManager'

QUnit.module('LockManager class')

test('shouldInit returns false if master courses env is not setup', () => {
  ENV.MASTER_COURSE_DATA = null
  const manager = new LockManager()
  notOk(manager.shouldInit())
})

test('shouldInit returns true if is_master_course_master_content is true', () => {
  ENV.MASTER_COURSE_DATA = { is_master_course_master_content: true }
  const manager = new LockManager()
  ok(manager.shouldInit())
})

test('shouldInit returns true if is_master_course_child_content is true', () => {
  ENV.MASTER_COURSE_DATA = { is_master_course_child_content: true }
  const manager = new LockManager()
  ok(manager.shouldInit())
})
