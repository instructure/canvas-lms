import TextHelper from '../TextHelper'

test('truncateText', () => {
  expect(TextHelper.truncateText('this is longer than 30 characters')).toBe('this is longer than 30...')
})
