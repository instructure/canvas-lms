describe RuboCop::Cop::Specs::NoSeleniumWebDriverWait do
  subject(:cop) { described_class.new }
  let(:msg_regex) { /Avoid using Selenium::WebDriver::Wait/ }

  it 'disallows Selenium::WebDriver::Wait' do
    inspect_source(cop, %{
      describe "breaks all the things" do
        wait = Selenium::WebDriver::Wait.new(timeout: 5)
        wait.until do
          el = f('.self_enrollment_message')
          el.present? &&
          el.text != nil &&
          el.text != ""
        end
        expect(f('.self_enrollment_message')).not_to include_text('self_enrollment_code')
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(msg_regex)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end
