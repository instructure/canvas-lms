require File.expand_path(File.dirname(__FILE__) + '/testrail')

config_path=File.expand_path('../../../../config/testrail.yml', __FILE__)
if File.exist?(config_path)
  $configuration = YAML.load_file(config_path)
else
  $configuration = nil
end

unless $configuration.nil?
  $client = TestRail::APIClient.new($configuration['test']['url'])
  $client.user = $configuration['test']['username']
  $client.password = $configuration['test']['password']
  $run_ID = $configuration['test']['run_id']
end

def upload_results(result, case_num)
  if result
    status = 1
    comment = 'Test Passed'
  else
    status = 5
    comment = 'Test Failed'
  end
  begin
    $client.send_post( "add_result_for_case/#{$run_ID}/#{case_num}",
        { :status_id => status, :comment => comment, :custom_supportusername => 33 }) 
  rescue
    # do nothing
  end
end

def report_test(case_num)
  if $configuration.nil?
    yield
  else
    begin
      yield
    rescue Exception
      upload_results(false, case_num)
      raise
    end
    upload_results(true, case_num)
  end
end
