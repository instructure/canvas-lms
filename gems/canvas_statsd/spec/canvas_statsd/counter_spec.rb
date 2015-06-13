require 'spec_helper'

describe CanvasStatsd::Counter do

  let(:subject) { CanvasStatsd::Counter.new('test', ['foo']) }

  describe "#accepted_name?" do
    it 'should return true for names not in blocked_names' do
      expect(subject.accepted_name?('bar')).to eq true
    end

    it 'should return false for names in blocked_names' do
      expect(subject.accepted_name?('foo')).to eq false
    end

    it 'should return true for empty string names' do
      expect(subject.accepted_name?('')).to eq true
    end

    it 'should return true for empty nil names' do
      expect(subject.accepted_name?(nil)).to eq true
    end
  end

  describe "#start" do
    it 'should reset count to zero' do
      subject.start
      expect(subject.count).to eq 0
    end
  end

  describe "#track" do
    it 'should increment when given allowed names' do
      subject.start
      subject.track('bar')
      subject.track('baz')
      expect(subject.count).to eq 2
    end

    it 'should not increment when given a blocked name' do
      subject.start
      subject.track('foo') #shouldn't count as foo is a blocked name
      subject.track('name')
      expect(subject.count).to eq 1
    end
  end

  describe "#finalize_count" do
    it 'should return the current count' do
      subject.start
      subject.track('bar')
      expect(subject.finalize_count).to eq 1
    end

    it 'should reset the current count to 0' do
      subject.start
      subject.track('bar')
      subject.finalize_count
      expect(subject.count).to eq 0
    end
  end

end
