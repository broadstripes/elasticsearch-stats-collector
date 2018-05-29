#!/usr/bin/env ruby

require 'json'
require 'faraday'

STACK = ENV['OPSWORKS_STACK']
DEST = ENV['DEST_CLUSTER_URL']
DEST_USER = ENV['DEST_CLUSTER_USER']
DEST_PASS = ENV['DEST_CLUSTER_PASS']
SOURCE = ENV['SOURCE_CLUSTER_URL']
SOURCE_USER = ENV['SOURCE_CLUSTER_USER']
SOURCE_PASS = ENV['SOURCE_CLUSTER_PASS']

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

src_conn = Faraday.new(url: SOURCE) do |conn|
  conn.basic_auth SOURCE_USER, SOURCE_PASS if SOURCE_PASS
  conn.adapter Faraday.default_adapter
end

dest_conn = Faraday.new(url: DEST) do |conn|
  conn.basic_auth DEST_USER, DEST_PASS  if DEST_PASS
  conn.adapter Faraday.default_adapter
end

every_ten_seconds do
  puts 'connecting to cluster'
  resp = src_conn.get('/_cluster/stats')
  p resp unless resp.success?
  stats = {
    cluster_url: SOURCE,
    opsworks_stack: STACK,
    stats: JSON.parse(resp.body),
    timestamp: Time.now.getutc.strftime("%Y/%m/%d %T")
  }
  puts stats
  dest_conn.post('/remote-cluster-statistics/_doc/') do |req|
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.dump(stats)
  end
end
