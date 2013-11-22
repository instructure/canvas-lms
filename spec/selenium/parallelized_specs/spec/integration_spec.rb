require 'spec_helper'

describe 'CLI' do
  before do
    `rm -rf #{folder}`
  end

  after do
    `rm -rf #{folder}`
  end

  def folder
    "/tmp/parallel_tests_tests"
  end

  def write(file, content)
    path = "#{folder}/#{file}"
    `mkdir -p #{File.dirname(path)}` unless File.exist?(File.dirname(path))
    File.open(path, 'w'){|f| f.write content }
    path
  end

  def bin_folder
    "#{File.expand_path(File.dirname(__FILE__))}/../bin"
  end

  def executable
    "#{bin_folder}/parallel_test"
  end

  def run_tests(options={})
    `cd #{folder} && #{executable} --chunk-timeout 999 -t #{options[:type] || 'spec'} -n #{options[:processes]||2} #{options[:add]} 2>&1`
  end

  it "runs tests in parallel" do
    write 'spec/xxx_spec.rb', 'describe("it"){it("should"){puts "TEST1"}}'
    write 'spec/xxx2_spec.rb', 'describe("it"){it("should"){puts "TEST2"}}'
    result = run_tests

    # test ran and gave their puts
    result.should include('TEST1')
    result.should include('TEST2')

    # all results present
    result.scan('1 example, 0 failure').size.should == 2 # 2 results
    result.scan('2 examples, 0 failures').size.should == 1 # 1 summary
    result.scan(/Finished in \d+\.\d+ seconds/).size.should == 2
    result.scan(/Took \d+\.\d+ seconds/).size.should == 1 # parallel summary
    $?.success?.should == true
  end

  it "does not run any tests if there are none" do
    write 'spec/xxx.rb', 'xxx'
    result = run_tests
    result.should include('No examples found')
    result.should include('Took')
  end

  it "fails when tests fail" do
    write 'spec/xxx_spec.rb', 'describe("it"){it("should"){puts "TEST1"}}'
    write 'spec/xxx2_spec.rb', 'describe("it"){it("should"){1.should == 2}}'
    result = run_tests

    result.scan('1 example, 1 failure').size.should == 1
    result.scan('1 example, 0 failure').size.should == 1
    result.scan('2 examples, 1 failure').size.should == 1
    $?.success?.should == false
  end

  it "can exec given commands with ENV['TEST_ENV_NUM']" do
    result = `#{executable} -e 'ruby -e "print ENV[:TEST_ENV_NUMBER.to_s].to_i"' -n 4`
    result.gsub('"','').split('').sort.should == %w[0 2 3 4]
  end

  it "can exec given command non-parallel" do
    result = `#{executable} -e 'ruby -e "sleep(rand(10)/100.0); puts ENV[:TEST_ENV_NUMBER.to_s].inspect"' -n 4 --non-parallel`
    result.split("\n").should == %w["" "2" "3" "4"]
  end

  it "exists with success if all sub-processes returned success" do
    system("#{executable} -e 'cat /dev/null' -n 4").should == true
  end

  it "exists with failure if any sub-processes returned failure" do
    system("#{executable} -e 'test -e xxxx' -n 4").should == false
  end

  it "can run through parallel_spec / parallel_cucumber" do
    version = `#{executable} -v`
    `#{bin_folder}/parallel_spec -v`.should == version
    `#{bin_folder}/parallel_cucumber -v`.should == version
  end

  it "runs faster with more processes" do
    2.times{|i|
      write "spec/xxx#{i}_spec.rb",  'describe("it"){it("should"){sleep 5}}; $stderr.puts ENV["TEST_ENV_NUMBER"]'
    }
    t = Time.now
    run_tests(:processes => 2)
    expected = 10
    (Time.now - t).should <= expected
  end

  it "can can with given files" do
    write "spec/x1_spec.rb", "puts '111'"
    write "spec/x2_spec.rb", "puts '222'"
    write "spec/x3_spec.rb", "puts '333'"
    result = run_tests(:add => 'spec/x1_spec.rb spec/x3_spec.rb')
    result.should include('111')
    result.should include('333')
    result.should_not include('222')
  end

  it "can run with test-options" do
    write "spec/x1_spec.rb", ""
    write "spec/x2_spec.rb", ""
    result = run_tests(:add => "--test-options ' --version'", :processes => 2)
    result.should =~ /\d+\.\d+\.\d+.*\d+\.\d+\.\d+/m # prints version twice
  end

  it "runs with test::unit" do
    write "test/x1_test.rb", "require 'test/unit'; class XTest < Test::Unit::TestCase; def test_xxx; end; end"
    result = run_tests(:type => :test)
    result.should include('1 test')
    $?.success?.should == true
  end

  it "passes test options to test::unit" do
    write "test/x1_test.rb", "require 'test/unit'; class XTest < Test::Unit::TestCase; def test_xxx; end; end"
    result = run_tests(:type => :test, :add => '--test-options "-v"')
    result.should include('test_xxx') # verbose output of every test
  end
end