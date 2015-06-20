require 'open-uri'
require 'eventmachine'

module Rack
  class DetectTor

    def initialize(app, options={})
      @app = app

      @options = {
        'external_ip'      => nil, 
        'external_port'    => nil,
        'update_frequency' => 60*60
      }.merge(options)

      @identifier = Hash[@options.select{|k,v| k =~ /^external_/}.
                         sort_by{|k,v| k}].values.map{|v| v.to_s == '' ? '*' : v}.join('/')

      log_message 'Fetching initial list of tor exits...'
      @tor_exits = fetch_tor_exits || {}

      unless @options['update_frequency'].to_i == 0
        log_message "Starting update timer... (updating every #{@options['update_frequency']} seconds)"
        run_update_timer
      end
    end

    def call(env)
      env['tor_exit_user'] = @tor_exits.include? request_ip(env)
      @app.call(env)
    end

    private

    def fetch_tor_exits
      if @options.select{|k,v| k =~ /^external_/}.values.map{|v| v.to_s}.include? ''
        log_message "WARNING: external_ip/external_port not specified. Results will NOT be accurate"

        begin
          tor_exit_list = open('https://check.torproject.org/exit-addresses').read
        rescue OpenURI::HTTPError => e
          log_error "Error fetching list of tor exits: #{e}"
        end

        tor_exits = tor_exit_list.split("\n").select{|i| i =~ /^ExitAddress/}.
          map{|j| j.split(' ')[1]}
      else
        check_url = "https://check.torproject.org/cgi-bin/TorBulkExitList.py?" +
          "ip=#{@options['external_ip']}" +
          (@options['external_port'].nil? ? '' : "&port=#{@options['external_port']}")

        begin
          tor_exit_list = open(check_url).read
        rescue OpenURI::HTTPError => e
          log_error "Error fetching list of tor exits: #{e}"
        end

        tor_exits = tor_exit_list.split("\n").select{|i| !(i =~ /^\#/)}
      end

      log_message "Found #{tor_exits.count} exits."
      return tor_exits
    end

    def run_update_timer
      Thread.new do
        EventMachine.run do
          @update_timer = EventMachine::PeriodicTimer.new(@options['update_frequency']) do
            log_message 'Updating list of tor exits...'
            @tor_exits = fetch_tor_exits || @tor_exits
          end
        end
      end
    end

    def request_ip(env)
      # yanked from https://github.com/rack/rack/blob/master/lib/rack/request.rb
      remote_addrs = split_ip_addresses(env['REMOTE_ADDR'])
      remote_addrs = reject_trusted_ip_addresses(remote_addrs)

      return remote_addrs.first if remote_addrs.any?

      forwarded_ips = split_ip_addresses(env['HTTP_X_FORWARDED_FOR'])

      return reject_trusted_ip_addresses(forwarded_ips).last || env["REMOTE_ADDR"]
    end

    def log_message(message)
      $stdout.puts "Rack::DetectTor [#{@identifier}]: #{message}"
    end

    def log_error(message)
      $stderr.puts "Rack::DetectTor [#{@identifier}]: ERROR: #{message}"
    end

  end
end
