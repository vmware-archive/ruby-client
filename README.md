Wavefront [![Build Status](https://travis-ci.org/wavefrontHQ/ruby-client.svg?branch=master)](https://travis-ci.org/wavefrontHQ/ruby-client) [![Gem Version](https://badge.fury.io/rb/wavefront-client.svg)](https://badge.fury.io/rb/wavefront-client) ![](http://ruby-gem-downloads-badge.herokuapp.com/wavefront-client?type=total)
==========

This is a ruby gem for speaking to the [Wavefront][1] monitoring and graphing system.

## Usage
Within your own ruby code:

### Writer

The `Wavefront::Writer` class can be used to post metrics to Wavefront.

Example usage:

```ruby
require 'wavefront/writer'
tags = {'k1' => 'v1', 'k2' => 'value 2'}
writer = Wavefront::Writer.new({:agent_host => 'agent.local.com', :host_name => 'server1', :metric_name => 'namespace.my.metric', :point_tags => tags})
# value of the metric at current timestamp is: 5
writer.write(5)
# Let's write a different metric overwriting the default options from the constructor
writer.write(6, 'namespace.my.other.metric', {host_name: 'server2'})
```

* The initializer takes a hash of options, wherein one can set
  * `:agent_host`  - A `String` representing the hostname of the Wavefront Agent. Default: `localhost`
  * `:agent_port`  - A number representing the port of the Wavefront Agent. Default: `2878`
  * `:host_name`   - A `String` representing the host that reported metrics will appear to be from in Wavefront. Default: The fqdn of the machine where your Ruby code is running. Can be over-written by the write method
  * `:metric_name` - A `String` representing the default metric name for any metrics reported from this class. Default: None. Can be over-written by the write method
  * `point_tags`   - A `Map` of key, value pairs of strings which will be sent to Wavefront. Can be over-written by the write method
  * The write method parameters are:
    * `metric_value` - A number, the value of the metric reporting at the current timestamp
    * `metric_name` - A `String`, this must be present, either within the write method call or set on the Writer class
    * A hash of options:
      * `host_name` - A `String`, which will appear as the host for the sent
         metric in Wavefront. Defaults to the `host_name` used to initialize
         the class.
      * `point_tags` - A `Map` of key, value pairs of strings which will be
        sent to Wavefront. Not required. Note that if you specify these as
        part of the write method call they replace any set at the class level.
        The two maps are _not_ merged. Defaults to the `point_tags` used to
        initialize the class
      * `timestamp` - The Epoch Seconds (`Fixnum`), or a Ruby `Time` object, of
        the reported point Default: `Time.now`

### Host Tags

The `Wavefront::Metadata` class facilitates the retrieval and posting of host tag related data to and from Wavefront.

Example usage:

```ruby
require 'wavefront/metadata'
meta = Wavefront::Metadata.new('<TOKEN>')

meta.get_tags # Get tags for all hosts
meta.get_tags("webserver.hostname.com") # Get tags for a specific host
meta.add_tags(["host.server1.server.com","host.server2.server.com"],["tag1","tag2"]) # Add an arbitrary number of tags to an arbitrary number of hosts
meta.remove_tags(["server1.server.com","server2.server.com"],["tag1","tag2"]) # Remove an arbitrary number of tags from an arbitrary number of hosts
```

* The initializer takes up to 3 parameters:
  * `token`              - A valid Wavefront API Token. This is required.
  * `host`               - A `String` representing the Wavefront endpoint to connect to. Default: `metrics.wavefront.com`.
  * `debug` `true|false` - When set to `true` output `RestClient` debugging to `stdout`. Default: `false`.

### Query Client

The `Wavefront::Client` class can be used to send queries to Wavefront and get a response

Example usage:

```ruby
require 'wavefront/client'

TOKEN ='123TOKEN'
wave = Wavefront::Client.new(TOKEN)
response = wave.query('<TS_EXPRESSION>')  # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
response = wave.query('<TS_EXPRESSION>', 'm', {:start_time => Time.now - 86400, :end_time => Time.now})  # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
```

* Like the Metadata class, the initializer takes up to 3 parameters:
  * `token`              - A valid Wavefront API Token. This is required.
  * `host`               - A `String` representing the Wavefront endpoint to connect to. Default: `metrics.wavefront.com`.
  * `debug` `true|false` - When set to `true` output `RestClient` debugging to `stdout`. Default: `false`.

* The query method takes up to 3 parameters:
  * The first parameter is required and is any valid Wavefront TS expression
  * The second parameter is a valid granularity, these are: 'd', 'm', 'h' and 's'. Default: `m`
  * The third parameter is a Hash of options. These are:
    * `:start_time` - An object of class `Time` that specifies the query start time. Default: `Time.now - 600`.
    * `:end_time` - And object of class `Time` that specifies the query end time. Default: `Time.now`.
    * `:response_format` `[ :raw, :ruby, :graphite, :highcharts ]` - See the section "Response Classes" below. Default: `:raw`.
    * `:prefix_length` - Used when performing schema manipulations. See the Graphite response format below. Default `1`.
    * `:strict` - originally Wavefront would return data points
      either side of the requested range. These extra points are
      required by the UI, but when you use the API you almost
      certainly don't want them. In Wavefront 2.4, an API parameter
      `strict` was introduced, which removes this padding. By
      default we set this to `true`, so you will get back exactly
      the range you request with `:start_time` and `:end_time`. If
      you wish to have the old behaviour, set this to `false`.
    * `:includeObsoleteMetrics` - With Wavefront 3.0 onwards, the non-reporting metrics
       are treated as obsolete after 4 weeks of no data being reported for them.
       Setting  `includeObsoleteMetrics` to true allows you to pull these obsolete metrics.
       It defaults to `false`
    * `:passthru` - as Wavefront develops it is hard to keep pace with
      the API changes and cover everything in the SDK. The `passthru`
      hash lets you pass parameters directly to the Wavefront API.
      Thus you can set things like `summarization`, or `listMode`
      directly, without having to implement them explicity in the SDK.
      Obviously no type-checking is done to the `passthru` hash, so
      refer to the Wavefront API docs, and use it with caution.

### Response Classes
The `query` method returns a sub-class of `Wavefront::Response`. By default this is `Wavefront::Response::Raw`, which is the raw String returned from the API. By including the `:response_format` key in the options hash when calling the query method you can receive responses as a number of other classes.

Example usage:

* `:response_format => :raw`

Default. Raw String returned from the API.

* `:response_format => :ruby`

A ruby object with accessor methods to the various parts of the query:

```
response = wave.query('<TS_EXPRESSION>', 'm')  # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
response.class  # Wavefront::Response::Raw
response = wave.query('<TS_EXPRESSION>', 'm', {:response_format => :ruby}) # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
response.class # Wavefront::Response::Ruby
response.instance_variables  # [:@response, :@query, :@name, :@timeseries, :@stats]
response.query
```

* `:response_format => :graphite`

A ruby object that returns graphite-format data via the `graphite` method:

```
response = wave.query('<TS_EXPRESSION>', 'm', {:response_format => :graphite}) # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
response.graphite[0]['datapoints'].first  # [99.8, 1403702640]
```

**Note:** The `target` schema String is constructed from the `label` and the `host` portions of the raw Wavefront response in order to be idiomatically Graphite. In order to determine how to do this properly one must split the `label` into a prefix and a postfix, inserting the `host` between then.

For example, `label: "web.prod.base.host.cpu-0.percent-idle"` and `host: i-12345678`, by default, would yield: `web.i-12345678.prod.base.host.cpu-0.percent-idle` as the Graphite target.

Depending on the vagaries of your particular configuration you may wish to specify more than the default 1 field as a prefix. This can be achieved passing the `:prefix_length` key as an option with an appropriate `Fixnum`. For example:

```
response = wave.query('<TS_EXPRESSION>', 'm', {:response_format => :graphite, :prefix_length => 2})
response.graphite[0]['target'] # web.prod.i-12345678.base.host.cpu-0.percent-idle
```

* `:response_format => :highcharts`

A ruby object that returns highcharts-format data via the `response` method:

```
response = wave.query('<TS_EXPRESSION>', 'm', {:response_format => :highcharts}) # <TS_EXPRESSION> : Placeholder for a valid Wavefront ts() query
response.highcharts[0]['data'].first  # [1436849460000, 517160277.3333333]
```

### Command-line client
A command line client is included too. Please see
[README-cli.md](README-cli.md) for details.

## Building and installing

```bash
rake build
```

or

```
rake install
```

## Contributing
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## Credits

Many thanks to SpaceApe games for initially contributing this Ruby client. Contributors include:

Sam Pointer
Louis McCormack
Joshua McGhee
Robert Fisher
Salil Deshmukh
Conor Beverland

[1]: http://wavefront.com
