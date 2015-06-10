describe RuboCop::Canvas::MigrationTags do
  subject { Class.new.tap { |c| c.include(described_class) }.new }

  it 'collects the list of tags for the migration' do
    node = Parser::CurrentRuby.parse('tag :predeploy, :cassandra')
    subject.on_send(node)
    expect(subject.tags).to eq([:predeploy, :cassandra])
  end
end
