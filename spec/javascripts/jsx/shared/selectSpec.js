import select from 'jsx/shared/select'

QUnit.module('Select function')

const obj = {
  id: '123',
  name: 'foo bar',
  points_possible: 30
}

test('select individual properties', () => {
  deepEqual(select(obj, ['id', 'name']), {id: '123', name: 'foo bar'})
})

test('select and alias properties', () => {
  deepEqual(select(obj, ['id', ['points_possible', 'points']]), {id: '123', points: 30})
})
