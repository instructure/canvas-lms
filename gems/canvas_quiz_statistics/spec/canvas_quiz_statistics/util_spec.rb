require 'spec_helper'

describe CanvasQuizStatistics::Util do
  Util = CanvasQuizStatistics::Util

  describe '#deep_symbolize_keys' do
    it 'does nothing on anything but a Hash' do
      Util.deep_symbolize_keys(5).should == 5
      Util.deep_symbolize_keys([]).should == []
      Util.deep_symbolize_keys(nil).should == nil
    end

    it 'should symbolize top-level keys' do
      Util.deep_symbolize_keys({ 'a' => 'b', c: 'd' }).should == {
        a: 'b',
        c: 'd'
      }
    end

    it 'should symbolize keys of nested hashes' do
      Util.deep_symbolize_keys({
        'e' => {
          'f' => 'g',
          h: 'i'
        }
      }).should == {
        e: {
          f: 'g',
          h: 'i'
        }
      }
    end

    it 'should symbolize keys of hashes inside arrays' do
      Util.deep_symbolize_keys({
        'e' => [{
          'f' => 'g',
          h: 'i'
        }]
      }).should == {
        e: [{
          f: 'g',
          h: 'i'
        }]
      }
    end

    it 'should symbolize all sorts of things' do
      Util.deep_symbolize_keys({
        item1: 'value1',
        "item2" => 'value2',
        hash: {
          item3: 'value3',
          "item4" => 'value4'
        },
        'array' => [{
          "item5" => 'value5',
          item6: 'value6'
        }]
      }).should == {
        item1: 'value1',
        item2: 'value2',
        hash: {
          item3: 'value3',
          item4: 'value4'
        },
        array: [{
          item5: 'value5',
          item6: 'value6'
        }]
      }
    end

    it 'should work with numbers for keys' do
      Util.deep_symbolize_keys({
        "1" => "first",
        "2" => "second"
      }).should == {
        :"1" => "first",
        :"2" => "second"
      }
    end

    it 'should skip nils and items that cant be symbolized' do
      Util.deep_symbolize_keys({ nil => 'foo' }).should == { nil => 'foo' }
    end

    it 'should only munge hashes' do
      Util.deep_symbolize_keys([]).should == []
      Util.deep_symbolize_keys([{ 'foo' => 'bar' }]).should == [{ 'foo' => 'bar' }]
    end
  end
end
