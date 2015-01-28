require 'spec_helper'

module I18nTasks
  module I18n
    describe I18nImport do
      subject(:import) {  I18nImport.new({'en' => {}}, {'ja' => {}}) }

      describe '#fix_plural_keys' do
        it 'copies over the other key if there is no one key' do
          hash = {'some.key.other' => 'value'}
          import.fix_plural_keys(hash)
          hash.should == {'some.key.other' => 'value', 'some.key.one' => 'value'}
        end

        it 'leaves the one key alone if it already exists' do
          hash = {
              'some.key.other' => 'value',
              'some.key.one' => 'other value'
          }
          import.fix_plural_keys(hash)
          hash.should == {'some.key.other' => 'value', 'some.key.one' => 'other value'}
        end
      end

      describe "#markdown_and_wrappers" do
        it 'finds links' do
          import.markdown_and_wrappers('[hello](http://foo.bar)').should == ['link:http://foo.bar']
        end

        it 'finds escaped chars' do
          import.markdown_and_wrappers('3 \* 3').should == ['\*']
        end

        it 'finds wrappers' do
          import.markdown_and_wrappers('hello *world*').should == ['*-wrap']
        end

        it 'finds wrappers with whitespace' do
          import.markdown_and_wrappers('hello * world *').should == ['*-wrap']
        end

        it 'finds nested wrappers' do
          import.markdown_and_wrappers('hello * **world** *').should == ['**-wrap', '*-wrap']
        end

        context 'a single-line string' do
          it 'doesn\'t find headings' do
            import.markdown_and_wrappers("# users").should == []
          end

          it 'doesn\'t find hr\'s' do
            import.markdown_and_wrappers("---").should == []
          end

          it 'doesn\'t find lists' do
            import.markdown_and_wrappers("1. do something").should == []
            import.markdown_and_wrappers("* do something").should == []
            import.markdown_and_wrappers("+ do something").should == []
            import.markdown_and_wrappers("- do something").should == []
          end
        end

        context 'a multi-line string' do
          it 'finds headings' do
            import.markdown_and_wrappers("# users\n").should == ['h1']
            import.markdown_and_wrappers("users\n====").should == ['h1']
          end

          it 'finds hr\'s' do
            import.markdown_and_wrappers("---\n").should == ['hr']
          end

          it 'finds lists' do
            import.markdown_and_wrappers("1. do something\n").should == ["1."]
            import.markdown_and_wrappers("* do something\n").should == ["*"]
            import.markdown_and_wrappers("+ do something\n").should == ["*"]
            import.markdown_and_wrappers("- do something\n").should == ["*"]
          end
        end
      end
    end
  end
end
