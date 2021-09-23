# frozen_string_literal: true

require 'spec_helper'
require 'rake/task_graph'

describe Rake::TaskGraph do
  it 'works' do
    batches = described_class.draw { task 'a' }
    expect(batches.length).to eq(1)
    expect(batches[0]).to eq(['a'])
  end

  it 'resolves deps' do
    batches = described_class.draw do
      task 'a'
      task 'b' => ['a']
      task 'c'
      task 'd' => ['c','b']
    end

    expect(batches).to eq([
      ['a','c'],
      ['b'],
      ['d']
    ])
  end

  it 'does not dupe nodes' do
    batches = described_class.draw do
      task 'a' => []
      task 'b' => ['a','a']
      task 'c'
      task 'd' => ['c','b']
      task 'e' => ['a']
    end

    expect(batches).to eq([
      ['a','c'],
      ['b','e'],
      ['d']
    ])
  end

  it 'is pure' do
    subject.task 'a'
    subject.task 'b' => ['a']
    subject.task 'c' => []
    subject.task 'd' => ['a','b','c']

    expect(subject.batches).to eq(subject.batches)
  end

  it 'loses no nodes in a sequence' do
    batches = described_class.draw do
      task 'a'
      task 'b' => ['a']
      task 'c' => ['b']
      task 'd' => ['c']
    end

    expect(batches).to eq([
      ['a'],
      ['b'],
      ['c'],
      ['d'],
    ])
  end

  it 'transforms a node' do
    batches = described_class.draw do
      task 'b' => ['a']
      task 'a' do
        5
      end
    end

    expect(batches).to eq([ [5], ['b'] ])
  end

  it 'whines on self-deps' do
    expect {
      described_class.draw { task 'a' => ['a'] }
    }.to raise_error(/has a self or circular dependency/)
  end

  it 'whines on circular deps' do
    expect {
      described_class.draw do
        task 'a' => ['b']
        task 'b' => ['a']
      end
    }.to raise_error(/has a self or circular dependency/)
  end

  it 'whines if a dependency is undefined' do
    expect {
      described_class.draw { task 'a' => ['b'] }
    }.to raise_error(/but were not defined/)
  end
end
