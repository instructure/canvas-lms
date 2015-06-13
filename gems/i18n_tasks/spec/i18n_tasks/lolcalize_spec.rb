require 'spec_helper'

module I18nTasks
  class LolcalizeHarness
    include Lolcalize
  end

  describe 'Lolcalize' do
    describe 'i18n_lolcalize' do
      it 'handles a string' do
        res = LolcalizeHarness.new.i18n_lolcalize('Hello')
        res.should == 'hElLo! LOL!'
      end

      it 'handles a hash' do
        res = LolcalizeHarness.new.i18n_lolcalize({ one: 'Hello', other: 'Hello %{count}' })
        res.should == { one: 'hElLo! LOL!', other: 'hElLo! LOL! %{count}' }
      end
    end
  end
end
