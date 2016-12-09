describe RuboCop::Cop::Specs::NoNoSuchElementError do
  subject(:cop) { described_class.new }
  let(:msg_regex) { /Avoid using Selenium::WebDriver::Error::NoSuchElementError/ }

  it 'disallows Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(cop, %{
      describe "breaks all the things" do
        it 'is a bad spec' do
          Selenium::WebDriver::Error::NoSuchElementError
        end
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows rescuing Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(cop, %{
      def not_found?
        find("#yar")
        false
      rescue Selenium::WebDriver::Error::NoSuchElementError
        true
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end

  it 'disallows raising Selenium::WebDriver::Error::NoSuchElementError' do
    inspect_source(cop, %{
      def not_found?
        a = find("#yar")
        return true if a
        raise Selenium::WebDriver::Error::NoSuchElementError
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
