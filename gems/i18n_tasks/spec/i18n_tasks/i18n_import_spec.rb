require 'spec_helper'

module I18nTasks
  module I18n
    describe I18nImport do
      describe '#fix_plural_keys' do
        it 'copies over the other key if there is no one key' do
          import = I18nImport.new({'en' => {}}, {'ja' => {}})
          hash = {'some.key.other' => 'value'}
          import.fix_plural_keys(hash)
          hash.should == {'some.key.other' => 'value', 'some.key.one' => 'value'}
        end

        it 'leaves the one key alone if it already exists' do
          import = I18nImport.new({'en' => {}}, {'ja' => {}})
          hash = {
              'some.key.other' => 'value',
              'some.key.one' => 'other value'
          }
          import.fix_plural_keys(hash)
          hash.should == {'some.key.other' => 'value', 'some.key.one' => 'other value'}
        end
      end
    end
  end
end