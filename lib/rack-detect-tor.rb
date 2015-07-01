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

      start_update_timer unless @options['update_frequency'].to_i == 0
    end

    def call(env)
      env['tor_exit_user'] = @tor_exits.include? Rack::Request.new(env).ip unless env['tor_exit_user'] == true
      @app.call(env)
    end

    private

    def fetch_tor_exits
      begin
        if @options.select{|k,v| k =~ /^external_/}.values.map{|v| v.to_s}.include? ''
          log_message "WARNING: external_ip/external_port not specified. " +
            "Using list of ALL exits. Results will NOT be accurate"

          tor_exits = open('https://check.torproject.org/exit-addresses').read.
            split("\n").select{|i| i =~ /^ExitAddress/}.map{|j| j.split(' ')[1]}
        else
          check_url = "https://check.torproject.org/cgi-bin/TorBulkExitList.py?" +
            "ip=#{@options['external_ip']}&port=#{@options['external_port']}"

          tor_exits = open(check_url).read.split("\n").select{|i| !(i =~ /^\#/)}
        end
      rescue OpenURI::HTTPError => e
        log_error "Error fetching list of tor exits (#{e})."
        return nil
      end

      log_message "Found #{tor_exits.count} exits."
      return tor_exits
    end

    def start_update_timer
      log_message "Starting update timer... (updating every #{@options['update_frequency']} seconds)"

      Thread.new do
        EventMachine.run do
          @update_timer = EventMachine::PeriodicTimer.new(@options['update_frequency']) do
            log_message 'Updating list of tor exits...'
            @tor_exits = fetch_tor_exits || @tor_exits
          end
        end
      end
    end

    def log_message(message)
      $stdout.puts "Rack::DetectTor [#{@identifier}]: #{message}"
    end

    def log_error(message)
      $stderr.puts "Rack::DetectTor [#{@identifier}]: ERROR: #{message}"
    end

  end
end
