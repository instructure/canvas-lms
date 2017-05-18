#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Base do
  Base = CanvasQuizStatistics::Analyzers::Base
  subject { described_class.new({}) }

  describe 'DSL' do
    def unset(*klasses)
      klasses.each do |klass|
        Object.send(:remove_const, klass.name.demodulize)
        Base.metrics[klass.question_type] = []
      end
    end

    describe '#metric' do
      it 'should define a metric calculator' do
        class Apple < Base
          metric :something do |responses|
            responses.size
          end
        end

        expect(Apple.new({}).run([ {}, {} ])).to eq({ something: 2 })

        unset Apple
      end

      it 'should not conflict with other analyzer metrics' do
        class Apple < Base
          metric :something do |responses|
            responses.size
          end
        end

        class Orange < Base
          metric :something_else do |responses|
            responses.size
          end
        end

        expect(Apple.new({}).run([{}])).to eq({ something: 1 })
        expect(Orange.new({}).run([{}])).to eq({ something_else: 1 })

        unset Apple, Orange
      end

      describe 'with context dependencies' do
        it 'should invoke the context builder and parse dependency' do
          class Apple < Base
            def build_context(responses)
              { colors: responses.map { |r| r[:color] } }
            end

            metric something: [ :colors ] do |responses, colors|
              colors.join(', ')
            end
          end

          responses = [{ color: 'Red' }, { color: 'Green' }]

          expect(Apple.new({}).run(responses)).to eq({ something: 'Red, Green' })

          unset Apple
        end
      end
    end

    describe '#inherit_metrics' do
      it 'should inherit a parent class metrics' do
        class Apple < Base
          metric :something do |responses|
            responses.size
          end
        end

        class Orange < Apple
          inherit_metrics :apple_question

          metric :something_else do |responses|
            responses.size
          end
        end

        expect(Apple.new({}).run([{}])).to eq({ something: 1 })
        expect(Orange.new({}).run([{}])).to eq({ something: 1, something_else: 1 })

        unset Apple, Orange
      end
    end

    describe '#inherit' do
      it 'should inherit a metric from another question type' do
        class Apple < Base
          metric :something do |responses|
            responses.size
          end
        end

        class Orange < Apple
          inherit :something, from: :apple

          metric :something_else do |responses|
            responses.size
          end
        end

        expect(Apple.new({}).run([{}])).to eq({ something: 1 })
        expect(Orange.new({}).run([{}])).to eq({ something: 1, something_else: 1 })

        unset Apple, Orange
      end
    end

  end
end
