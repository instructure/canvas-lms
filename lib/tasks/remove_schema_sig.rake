desc 'Removes the schema line in fixtures, models, and specs.'
task :remove_schema_signature do
  models = Dir.glob(File.join(File.dirname(__FILE__), %w(.. .. app models)) + "/*.rb")
  specs = Dir.glob(File.join(File.dirname(__FILE__), %w(.. .. spec models)) + "/*.rb")
  fixtures = Dir.glob(File.join(File.dirname(__FILE__), %w(.. .. spec fixtures)) + "/*.yml")
  files = models | specs | fixtures
  files.each {|file| remove_signature(file)}
end

task :remove_schema_sig => :remove_schema_signature

def remove_signature(filename)
  return false unless File.exist?(filename)
  contents = File.read(filename)
  contents.gsub!(/\A\# Schema version\: \d{14}\z/, '# ')
  fp = File.open(filename, 'w')
  fp.puts contents
  fp.close
end
