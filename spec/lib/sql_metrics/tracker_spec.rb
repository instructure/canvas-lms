require_relative '../../spec_helper'

module SqlMetrics
  describe Tracker do

    describe '#start' do
      it 'resets values to zero' do
        subject = Tracker.new
        subject.start
        subject.track 'CACHE', 'SELECT * FROM some_table'
        subject.start
        expect(subject.num_caches).to eq(0)
        expect(subject.num_reads).to eq(0)
        expect(subject.num_writes).to eq(0)
      end
    end

    describe '#track' do
      before :each do
        @subject = Tracker.new
        @subject.start
      end

      it 'considers CACHE above all' do
        @subject.track 'CACHE', 'SELECT * FROM some_table'
        expect(@subject.num_caches).to eq(1)
        expect(@subject.num_reads).to eq(0)
      end

      it 'marks as read when select is in the first 15 chars of the sql' do
        @subject.track 'LOAD', '  SELECT "context_external_tools".* FROM'
        expect(@subject.num_reads).to eq(1)
        expect(@subject.num_writes).to eq(0)
      end

      it 'marks as read with no select, but a LOAD name' do
        @subject.track 'LOAD', 'WITH RECURSIVE t AS'
        expect(@subject.num_reads).to eq(1)
        expect(@subject.num_writes).to eq(0)
      end

      it 'doesnt track names set as blocked' do
        tracker = Tracker.new(blocked_names: ['SCHEMA'])
        tracker.start
        tracker.track 'SCHEMA', 'SELECT * FROM some_table'
        expect(tracker.num_reads).to eq(0)
      end

      it 'doesnt track nil names or sql values' do
        @subject.track nil, 'SELECT *'
        @subject.track 'CACHE', nil
        expect(@subject.num_reads).to eq(0)
      end

      it 'passes full sql to counter.track calls for reads' do
        sql = '  SELECT \'context_external_tools\'.* FROM'
        read_counter = mock(:start)
        read_counter.expects(:track).with(sql)
        tracker = Tracker.new(read_counter: read_counter)
        tracker.start
        tracker.track 'LOAD', sql
      end

      it 'passes full sql to counter.track calls for writes' do
        sql = '  UPDATE \'context_external_tools\'.* FROM'
        write_counter = mock(:start)
        write_counter.expects(:track).with(sql)
        tracker = Tracker.new(write_counter: write_counter)
        tracker.start
        tracker.track 'UPDATE', sql
      end
    end

  end
end
