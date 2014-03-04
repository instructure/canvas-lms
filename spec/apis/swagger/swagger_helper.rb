swagger_dir = File.join(
  File.dirname(__FILE__),
  '..', '..', '..',
  'doc', 'api', 'fulldoc', 'html', 'swagger')
$:.unshift(swagger_dir)

require File.expand_path(File.dirname(__FILE__) + '/../../mocha_rspec_adapter')
