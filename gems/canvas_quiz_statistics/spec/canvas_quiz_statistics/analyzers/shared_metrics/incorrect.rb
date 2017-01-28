shared_examples '[:incorrect]' do
  it 'should count all incorrect responses' do
    stats = subject.run([
      { correct: "true" },
      { correct: true },
      { correct: 'false' },
      { correct: false },
      { correct: nil },
      { correct: 'partial' },
      { correct: 'undefined' },
      { correct: 'defined' }
    ])

    expect(stats[:incorrect]).to eq(3)
  end
end