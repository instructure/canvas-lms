define([
  'helpers/fakeENV',
  'jsx/shared/conditional_release/CyoeHelper',
], (fakeENV, CyoeHelper) => {
  const cyoeEnv = () => ({
    CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
    CONDITIONAL_RELEASE_ENV: {
      active_rules: [{
        trigger_assignment: '1',
        scoring_ranges: [
          {
            assignment_sets: [
              { assignments: [{ assignment_id: '2' }] },
            ],
          },
        ],
      }],
    },
  })

  const setEnv = (env) => {
    fakeENV.setup(env)
    CyoeHelper.reloadEnv()
  }

  const testSetup = {
    setup () {
      setEnv({
        CONDITIONAL_RELEASE_SERVICE_ENABLED: false,
        CONDITIONAL_RELEASE_ENV: null,
      })
    },
    teardown () {
      fakeENV.teardown()
    },
  }

  module('CYOE Helper', () => {

    module('isEnabled', testSetup)

    test('returns false if not enabled', () => {
      notOk(CyoeHelper.isEnabled())
    })

    test('returns true if enabled', () => {
      setEnv(cyoeEnv())
      ok(CyoeHelper.isEnabled())
    })

    module('getItemData', testSetup)

    test('return isTrigger = false if item is not a trigger assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('2')
      notOk(itemData.isTrigger)
    })

    test('return isTrigger = true if item is a trigger assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      ok(itemData.isTrigger)
    })

    test('return isReleased = false if item is not a released assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      notOk(itemData.isReleased)
    })

    test('return isReleased = true if item is a released assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('2')
      ok(itemData.isReleased)
    })

    test('return isCyoeAble = false if item is not graded', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1', false)
      notOk(itemData.isCyoeAble)
    })

    test('return isCyoeAble = true if item is graded', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      ok(itemData.isCyoeAble)
    })

    module('reloadEnv', testSetup)

    test('reloads data from ENV', () => {
      const env = cyoeEnv()
      setEnv(env) // set env calls reloadEnv internally
      let itemData = CyoeHelper.getItemData('1')
      ok(itemData.isTrigger)

      env.CONDITIONAL_RELEASE_ENV.active_rules[0].trigger_assignment = '2'
      setEnv(env)

      itemData = CyoeHelper.getItemData('1')
      notOk(itemData.isTrigger)
    })
  })
})
