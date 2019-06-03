require_relative '../../rails_helper'

RSpec.describe AssignmentsService::Scheduler do
  let(:start_at) { DateTime.parse("Mon Nov 26 2018") }
  let(:end_at) { start_at + 30.days }
  let(:course) { double(:course, start_at: start_at, end_at: end_at, time_zone: 'UTC') }

  let(:days) do
    subject.course_dates.keys.map { |d| d.strftime("%a") }.uniq
  end

  subject do
    described_class.new(course: course, assignment_count: 44)
  end

  describe '#course_days_count' do
    it 'should return a count of all weekdays' do
      expect(subject.course_days_count).to eq 28
    end
  end

  describe '#assignments_per_day' do
    it 'does assignment count / course_days_count' do
      expect(subject.assignments_per_day).to eq 2
    end

    context 'assignments dont divide evenly into course days' do
      subject do
        described_class.new(course: course, assignment_count: 22)
      end

      it 'distributes remainder' do
        expect(subject.course_dates[subject.course_dates.keys[0]]).to eq 2
        expect(subject.course_dates[subject.course_dates.keys[1]]).to eq 2
      end
    end
  end

  describe '#course_dates' do
    it 'does not include weekends' do
      expect(days).to_not include("Sat")
    end

    it 'will not assign a due date on the first day of the course' do
      expect(subject.course_dates.keys[0]).to_not eq start_at
    end

    it 'will start a day after' do
      expect(subject.course_dates.keys[0]).to eq start_at.in_time_zone(course.time_zone).at_end_of_day + 1.day
    end

    it 'will have a due time of 23:59' do
      expect(subject.course_dates.keys[0].strftime("%H:%M")). to eq "23:59"
    end

    context 'when given a start date' do
      subject do
        described_class.new(course: course, assignment_count: 44, start_date: DateTime.new(2018,12,6))
      end

      it 'will start a day after' do
        expect(subject.course_dates.keys[0].strftime("%Y-%m-%d")). to eq (DateTime.new(2018,12,7)).strftime('%Y-%m-%d')
      end
    end

    context 'when given less assignments than days' do
      subject do
        described_class.new(course: course, assignment_count: 10)
      end

      it 'distibutes correctly' do
        result = {
          "Tue, 27 Nov 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Wed, 28 Nov 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Thu, 29 Nov 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Fri, 30 Nov 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Mon, 03 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Tue, 04 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Wed, 05 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Thu, 06 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Fri, 07 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Mon, 10 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Tue, 11 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Wed, 12 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Thu, 13 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Fri, 14 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Mon, 17 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Tue, 18 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Wed, 19 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Thu, 20 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1,
          "Fri, 21 Dec 2018 23:59:59 UTC +00:00".to_datetime=>0,
          "Mon, 24 Dec 2018 23:59:59 UTC +00:00".to_datetime=>1
        }

        actual = subject.course_dates

        expect(actual.keys[0].day).to eq(27)
        expect(actual[actual.keys[0]]).to eq(1)
        expect(actual.keys[1].day).to eq(28)
        expect(actual[actual.keys[1]]).to eq(0)
        expect(actual.keys[2].day).to eq(29)
        expect(actual[actual.keys[2]]).to eq(1)
        expect(actual.keys[3].day).to eq(30)
        expect(actual[actual.keys[3]]).to eq(0)
        expect(actual.keys[4].day).to eq(3)
        expect(actual[actual.keys[4]]).to eq(1)
        expect(actual.keys[5].day).to eq(4)
        expect(actual[actual.keys[5]]).to eq(0)
        expect(actual.keys[6].day).to eq(5)
        expect(actual[actual.keys[6]]).to eq(1)
        expect(actual.keys[7].day).to eq(6)
        expect(actual[actual.keys[7]]).to eq(0)
        expect(actual.keys[8].day).to eq(7)
        expect(actual[actual.keys[8]]).to eq(1)
        expect(actual.keys[9].day).to eq(10)
        expect(actual[actual.keys[9]]).to eq(0)
        expect(actual.keys[10].day).to eq(11)
        expect(actual[actual.keys[10]]).to eq(0)
        expect(actual.keys[11].day).to eq(12)
        expect(actual[actual.keys[11]]).to eq(1)
        expect(actual.keys[12].day).to eq(13)
        expect(actual[actual.keys[12]]).to eq(0)
        expect(actual.keys[13].day).to eq(14)
        expect(actual[actual.keys[13]]).to eq(1)
        expect(actual.keys[14].day).to eq(17)
        expect(actual[actual.keys[14]]).to eq(0)
        expect(actual.keys[15].day).to eq(18)
        expect(actual[actual.keys[15]]).to eq(1)
        expect(actual.keys[16].day).to eq(19)
        expect(actual[actual.keys[16]]).to eq(0)
        expect(actual.keys[17].day).to eq(20)
        expect(actual[actual.keys[17]]).to eq(1)
        expect(actual.keys[18].day).to eq(21)
        expect(actual[actual.keys[18]]).to eq(0)
        expect(actual.keys[19].day).to eq(24)
        expect(actual[actual.keys[19]]).to eq(1)
      end
    end

    context 'when given more assignments than days' do
      subject do
        described_class.new(course: course, assignment_count: 35)
      end

      it 'runs the default' do
        actual = subject.course_dates
        expect(actual.values.select { |v| v > 1 }.any?).to be
      end
    end

    context 'when given holidays' do
      before do
        @env = {
          HOLIDAYS: "2018-11-28,2018-11-29"
        }
        allow(subject).to receive(:settings_service_holidays).and_return(nil)
      end

      it 'will not include the first holiday in course dates' do
        with_modified_env @env do
          expect(subject.course_dates.keys[1].strftime("%F")). to_not eq "2018-11-28"
        end
      end

      it 'will not include more holidays in course dates' do
        with_modified_env @env do
          expect(subject.course_dates.keys[1].strftime("%F")). to_not eq "2018-11-29"
        end
      end
    end
  end
end
