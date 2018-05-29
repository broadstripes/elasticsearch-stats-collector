#!/usr/bin/env ruby

require 'json'
require 'faraday'

STACK = ENV['OPSWORKS_STACK']
DEST = ENV['DEST_CLUSTER_URL']
SOURCE = ENV['SOURCE_CLUSTER_URL']

raise 'No destination cluster provided' if DEST.nil?
raise 'No source cluster provided' if SOURCE.nil?

def every_ten_seconds
  loop do
    start = Time.now
    yield
    stop = Time.now
    elapsed = stop - start
    sleep(10 - elapsed) if elapsed < 10
  end
end

every_ten_seconds do
  puts 'connecting to cluster'
  resp = Faraday.get(SOURCE + '/_cluster/stats')
  p resp unless resp.success?
  stats = {
    cluster_url: SOURCE,
    opsworks_stack: STACK,
    stats: JSON.parse(resp.body),
    timestamp: Time.now.getutc.strftime("%Y/%m/%d %T")
  }
  puts stats
  Faraday.post(DEST + '/remote-cluster-statistics/_doc/') do |req| 
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.dump(stats)
  end
end
