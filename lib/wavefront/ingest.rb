module Wavefront
  #
  # The Wavefront API has a currently undocumented feature which
  # allows direct ingestion of points, bypassing a proxy. This
  # module lets you use that feature.
  #
  # Note that direct ingestion is UNDOCUMENTED and therefore
  # UNSTABLE. It works at the moment, but it might work differently,
  # or not at all, in the future.
  #
  # The ingestion mechanism is slightly strange and, IMO, not well
  # designed, because though one can submit multiple points in the
  # body of the HTTP POST request, the timestamp and source, which
  # apply apply to all those points, must be in the URI.
  #
  # I have raised (2017-07-11) a feature request with Wavefront to
  # improve and finalise direct data ingestion.
  #
  class Ingest
    attr_reader :headers, :verbose, :noop, :endpoint
    include Wavefront::Constants
    #include Wavefront::Validators
    include Wavefront::Mixins
    DEFAULT_PATH = '/report/metrics'

    def initialize(token, host = DEFAULT_HOST, debug=false, options = {})
      #
      # Following existing convention, 'host' is the Wavefront API endpoint.
      #
      @headers = { :'X-AUTH-TOKEN' => token }
      @endpoint = host
      @token = token
      debug(debug)
      @noop = options[:noop]
      @verbose = options[:verbose]
      @options = options
    end

    # Direct ingestion works by POSTing a JSON objcet of points to a
    # URI which contains the source name and the timestamp for all
    # points in said object. The base URI is
    #
    #  https://endpoint.wavefront.com/report/metrics?h=host&d=ts
    #
    #  where "endpoint" is the Wavefront cluster name (connectedhome
    #  in our case); "host" is the host or source name, and "ts" is
    #  an epoch-seconds timestamp.
    #
    # The body hash looks like this:
    #
    # {
    #   "metric.path.1": {
    #     "value": 100,
    #     "tags": {
    #       "tag1": "value1",
    #       "tag2": "value2"
    #     }
    #   },
    #   "metric.path.2", {
    #     "value": 22.2,
    #   }
    # }
    #
    # This method expects to be fed such a hash, with optional
    # source and timestamp arguments.
    #
    # @param points [Hash] hash of points as described above
    # @param source [String] optional source ID: defaults to the
    #   local hostname
    # @param timestamp [Time, Integer] optional timestamp as a Ruby
    #   Time object or epoch seconds. Defaults to the current time
    #
    def write(points, source = nil, timestamp = Time.now)

      q = { h: source || DEFAULT_OPTIONS[:host],
            d: parse_time(timestamp) }

      if verbose
        puts "sending points: #{points}"
      end
      call_post(create_uri(qs: hash_to_qs(q)), points.to_json,
                'application/json')
    end

    def create_uri(options = {})
      #
      # Build the URI we use to send a 'create' request.
      #
      options[:host] ||= endpoint
      options[:path] ||= ''
      options[:qs]   ||= nil

      options[:qs] = nil if options[:qs] && options[:qs].empty?

      URI::HTTPS.build(
        host:  options[:host],
        path:  uri_concat(DEFAULT_PATH),
        query: options[:qs],
      )
    end

    def debug(enabled)
      RestClient.log = 'stdout' if enabled
    end
  end
end
