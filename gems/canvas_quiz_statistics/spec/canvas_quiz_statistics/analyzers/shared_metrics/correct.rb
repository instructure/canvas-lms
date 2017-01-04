shared_examples '[:correct]' do
  it 'should count all fully correct responses' do
    stats = subject.run([
      { correct: "true" },
      { correct: true },
      { correct: false },
      { correct: nil },
      { correct: 'partial' },
      { correct: 'undefined' },
      { correct: 'defined' }
    ])

    expect(stats[:correct]).to eq(2)
  end
end
