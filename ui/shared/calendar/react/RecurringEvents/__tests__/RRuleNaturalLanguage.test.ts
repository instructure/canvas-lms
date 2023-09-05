/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import {RruleValidationError} from '../RRuleHelper'
import RRuleToNaturalLanguage from '../RRuleNaturalLanguage'

const defaultTZ = 'Asia/Tokyo'
const today = moment().tz(defaultTZ)

describe('RRuleToNaturalLanguage', () => {
  let locale: string, timezone: string, format_date: (date: Date) => string
  beforeAll(() => {
    locale = 'en'
    timezone = defaultTZ
    format_date = new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      timeZone: timezone,
    }).format
  })

  describe('parses daily', () => {
    describe('every day', () => {
      it('with count', () => {
        const str = RRuleToNaturalLanguage('FREQ=DAILY;INTERVAL=1;COUNT=3', locale, timezone)
        expect(str).toEqual('Daily, 3 times')
      })

      it('with until', () => {
        const until = today.clone().add(1, 'year')
        const str = RRuleToNaturalLanguage(
          `FREQ=DAILY;INTERVAL=1;UNTIL=${until.utc().format('YYYYMMDDTHHmmss') + 'Z'}`,
          locale,
          timezone
        )
        expect(str).toEqual(`Daily until ${format_date(until.toDate())}`)
      })
    })
    describe('every other day', () => {
      it('with interval and count', () => {
        const str = RRuleToNaturalLanguage('FREQ=DAILY;INTERVAL=2;COUNT=3', locale, timezone)
        expect(str).toEqual('Every 2 days, 3 times')
      })

      it('with interval and until', () => {
        const until = today.clone().add(1, 'year')
        const str = RRuleToNaturalLanguage(
          `FREQ=DAILY;INTERVAL=2;UNTIL=${until.utc().format('YYYYMMDDTHHmmss') + 'Z'}`,
          locale,
          timezone
        )
        expect(str).toEqual(`Every 2 days until ${format_date(until.toDate())}`)
      })
    })
  })

  describe('parses weekly', () => {
    describe('every week', () => {
      it('with count', () => {
        const str = RRuleToNaturalLanguage(
          'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;COUNT=3',
          locale,
          timezone
        )
        expect(str).toEqual('Weekly on Mon, Wed, Fri, 3 times')
      })

      it('with until', () => {
        const until = today.clone().add(1, 'year')
        const str = RRuleToNaturalLanguage(
          `FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR;UNTIL=${
            until.utc().format('YYYYMMDDTHHmmss') + 'Z'
          }`,
          locale,
          timezone
        )
        expect(str).toEqual(`Weekly on Mon, Wed, Fri until ${format_date(until.toDate())}`)
      })
    })

    describe('every other week', () => {
      it('with count', () => {
        const str = RRuleToNaturalLanguage(
          'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;COUNT=3',
          locale,
          timezone
        )
        expect(str).toEqual('Every 2 weeks on Mon, Wed, Fri, 3 times')
      })

      it('with until', () => {
        const until = today.clone().add(1, 'year')
        const str = RRuleToNaturalLanguage(
          `FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;UNTIL=${
            until.utc().format('YYYYMMDDTHHmmss') + 'Z'
          }`,
          locale,
          timezone
        )
        expect(str).toEqual(`Every 2 weeks on Mon, Wed, Fri until ${format_date(until.toDate())}`)
      })
    })

    describe('monthly', () => {
      describe('on a day of the month', () => {
        describe('every month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYMONTHDAY=15;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Monthly on day 15, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYMONTHDAY=15;INTERVAL=1;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Monthly on day 15 until ${format_date(until.toDate())}`)
          })
        })

        describe('every other month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYMONTHDAY=15;INTERVAL=2;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Every 2 months on day 15, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYMONTHDAY=15;INTERVAL=2;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Every 2 months on day 15 until ${format_date(until.toDate())}`)
          })
        })
      })
      describe('on a day of the week', () => {
        describe('every month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=1;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Monthly on the first Tue, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYDAY=TU;BYSETPOS=1;INTERVAL=1;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Monthly on the first Tue until ${format_date(until.toDate())}`)
          })
        })

        describe('every other month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=1;INTERVAL=2;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Every 2 months on the first Tue, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYDAY=TU;BYSETPOS=1;INTERVAL=2;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(
              `Every 2 months on the first Tue until ${format_date(until.toDate())}`
            )
          })
        })
      })
      describe('on the last week day of the month', () => {
        describe('every month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=-1;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Monthly on the last Tue, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYDAY=TU;BYSETPOS=-1;INTERVAL=1;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Monthly on the last Tue until ${format_date(until.toDate())}`)
          })
        })

        describe('every other month', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=MONTHLY;BYDAY=TU;BYSETPOS=-1;INTERVAL=2;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Every 2 months on the last Tue, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=MONTHLY;BYDAY=TU;BYSETPOS=-1;INTERVAL=2;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(
              `Every 2 months on the last Tue until ${format_date(until.toDate())}`
            )
          })
        })
      })
    })

    describe('yearly', () => {
      describe('every year', () => {
        describe('on a date', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=28;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Annually on Jul 28, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=28;INTERVAL=1;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Annually on Jul 28 until ${format_date(until.toDate())}`)
          })

          it('on a leap day', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Annually on Feb 29, 3 times')
          })
        })
        describe('on a day of the week', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=YEARLY;BYMONTH=7;BYDAY=TU;BYSETPOS=2;INTERVAL=1;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Annually on the second Tue of Jul, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=YEARLY;BYMONTH=7;BYDAY=TU;BYSETPOS=2;INTERVAL=1;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(
              `Annually on the second Tue of Jul until ${format_date(until.toDate())}`
            )
          })
        })
      })

      describe('every other year', () => {
        describe('on a date', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=28;INTERVAL=2;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Every 2 years on Jul 28, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=YEARLY;BYMONTH=7;BYMONTHDAY=28;INTERVAL=2;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(`Every 2 years on Jul 28 until ${format_date(until.toDate())}`)
          })
        })
        describe('on a day of the week', () => {
          it('with count', () => {
            const str = RRuleToNaturalLanguage(
              'FREQ=YEARLY;BYMONTH=7;BYDAY=TU;BYSETPOS=2;INTERVAL=2;COUNT=3',
              locale,
              timezone
            )
            expect(str).toEqual('Every 2 years on the second Tue of Jul, 3 times')
          })

          it('with until', () => {
            const until = today.clone().add(1, 'year')
            const str = RRuleToNaturalLanguage(
              `FREQ=YEARLY;BYMONTH=7;BYDAY=TU;BYSETPOS=2;INTERVAL=2;UNTIL=${
                until.utc().format('YYYYMMDDTHHmmss') + 'Z'
              }`,
              locale,
              timezone
            )
            expect(str).toEqual(
              `Every 2 years on the second Tue of Jul until ${format_date(until.toDate())}`
            )
          })
        })
      })
    })
  })

  describe('RRULEs with errors', () => {
    it('throws if the RRULE is invalid', () => {
      expect(() => {
        RRuleToNaturalLanguage('FREQ=INVALID', locale, timezone)
      }).toThrow(RruleValidationError)
    })
  })
})
