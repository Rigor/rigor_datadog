# load dependencies
require_relative 'bundle/bundler/setup'
require 'json'
require 'iron_mq'
require 'iron_worker'
require 'httparty' # HTTP client for Rigor API calls
require 'dogapi'   # Ruby Datadog API client

# pull API keys out of the configuration variables
rigor_api_key   = IronWorker.config['rigor_api_key']
datadog_api_key = IronWorker.config['datadog_api_key']

# if no keys provided, fail the job
raise 'Invalid config: Rigor and Datadog API keys required' unless rigor_api_key && datadog_api_key

# set up the request headers for the Rigor API
rigor_request_headers = {
  'API-KEY'      => rigor_api_key,
  'Content-Type' => 'application/json'
}

if check_id = IronWorker.payload['check_id']
  puts "Getting data for Rigor Check #{check_id}"
  # get the specified check via Rigor API
  check_url = "#{IronWorker.config['rigor_api_path']}/checks/#{check_id}"
  check     = HTTParty.get(check_url, headers: rigor_request_headers)

  # pull out some check info and build up a tags array to include with Datadog API call
  check_type  = check['type']
  check_tags  = Array(check['tags']).map {|tag| "check_tag:#{tag['name']}"}
  series_tags = ["check_id:#{check_id}", "check_type:#{check_type}", "env:development"] + check_tags

  # get the metric data for the check via Rigor API
  check_metrics_url = "#{check['links']['metrics']}/data?include_summary=true"
  metric_data = HTTParty.get(check_metrics_url, headers: rigor_request_headers)

  # create the Datadog API client using the api key from config var
  dog = Dogapi::Client.new(datadog_api_key)

  # for each summary metric, add a datapoint in Datadog
  metric_data['summary'].each do |metric_name, value|
    # namespace the metrics with "rigor."
    # e.g. "rigor.run_count"
    # tag the metrics with check_type, check_id, check_tag (if it has any tags in Rigor)
    dog.emit_point("rigor.#{metric_name}", value, :tags => series_tags)
    puts "Sent #{metric_name} to Datadog"
  end
else
  puts 'No Rigor Check ID provided, quitting'
end
