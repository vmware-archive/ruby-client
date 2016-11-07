# Wavefront CLI

`wavefront <command> [options]`

The `wavefront` command provides CLI access to Wavefront. Different
command keywords enable different functionality.

## Global Options

The following options are valid in almost all contexts.

```
-c, --config=FILE    path to configuration file [default: ~/.wavefront]
-P, --profile=NAME   profile in configuration file [default: default]
-t, --token=TOKEN    Wavefront authentication token
-D, --debug          enable debug mode
-h, --help           show help for command
```

## `ts` Mode: Retrieving Timeseries Data

The `ts` command is used to submit a standard timeseries query to
Wavefront. It can output the timeseries data in a number of formats.
You must specify a query granularity, and you can timebox your
query.

```
Usage:
  wavefront ts [-c file] [-P profile] [-E endpoint] [-t token] [-OD]
            [-S | -m | -H | -d] [-s time] [-e time] [-f format] [-p num]
            [-X bool] <query>

Options:
  -E, --endpoint=URI            cluster endpoint [default:
                                metrics.wavefront.com]
  -S, --seconds                 query granularity of seconds
  -m, --minutes                 query granularity of minutes
  -H, --hours                   query granularity of hours
  -d, --days                    query granularity of days
  -s, --start=TIME              start of query window in epoch seconds or
                                strptime parseable format
  -e, --end=TIME                end of query window in epoch seconds or
                                strptime parseable format
  -f, --format=STRING           output format (raw, ruby, graphite,
                                highcharts, human)
                                [default: raw]
  -p, --prefixlength=NUM        number of path elements to treat as prefix
                                in schema manipulation. [default: 1]
  -X, --strict=BOOL             Do not return points outside the query
                                window. [default: true]
  -O, --includeObsoleteMetrics  include metrics unreported for > 4 weeks
```

The `-X` flag is now more-or-less obsolete. It was required when the
API defaulted to returning data outside the specified query window.

### Examples

View ethernet traffic on the host `shark`, in one-minute buckets,
starting at noon today, in human-readable format.

```
$ wavefront ts -f human -m --start=12:00 \
  'ts("lab.generic.host.interface-phys.if_packets.*", source=shark)'
query               ts("lab.generic.host.interface-phys.if_packets.*", source=shark)
timeseries          0
label               lab.generic.host.interface-phys.if_packets.tx
host                shark
2016-06-27 12:00:00 136.0
2016-06-27 12:01:00 15.666666666666668
2016-06-27 12:02:00 15.8
2016-06-27 12:03:00 15.3
2016-06-27 12:04:00 19.35
2016-06-27 12:05:00 315.451
2016-06-27 12:06:00 110.98316666666668
2016-06-27 12:07:00 34.40016666666667
2016-06-27 12:08:00 308.667
2016-06-27 12:09:00 239.05016666666666
2016-06-27 12:10:00 17.883333333333333
...
```

Show all events between 6pm and 8pm today:

```
$ ./wavefront  ts -f human -m --start=18:00 --end=20:00 'events()'
2016-06-27 16:55:59 -> 2016-06-27 16:56:40 (41s)                             new event                 [shark,box]
2016-06-27 18:41:57 -> 2016-06-27 18:41:57 (inst)    info    alert-updated   Alert Edited: Point Rate
2016-06-27 18:42:03 -> 2016-06-27 18:44:09 (2m 6s)   severe  alert           Point Rate                []
2016-06-27 18:44:09 -> 2016-06-27 18:44:09 (inst)    info    alert-updated   Alert Edited: Point Rate
2016-06-27 18:46:33 -> 2016-06-27 18:46:33 (inst)                            instantaneous_event       [box]
2016-06-27 18:47:53 -> 2016-06-27 18:47:53 (inst)                            instantaneous_event       [box] something important just happened
2016-06-27 19:25:16 -> 2016-06-27 19:26:32 (1m 15s)  info                    puppet_run                [box] Puppet run
```

Output is different for event queries.  The columns are: start time -> end
time, (duration), severity, event type, [source(s)], details.

## `alerts` Mode: Retrieving Alert Data

The `alerts` command lets you view alerts. It does not currently
allow creation and removal of alerts. Alert data can be presented in
a number of formats, but defaults to a human-readable form. If you
wish to parse the output, please use the `ruby` or `json`
formatters.

```
Usage:
  wavefront alerts [-c file] [-P profile] [-E endpoint] [-t token]
            [-f format] [-p tag] [ -s tag] <state>

Options:
  -E, --endpoint=URI   cluster endpoint [default: metrics.wavefront.com]
  -f, --format=STRING  output format (ruby, json, human)
                       [default: human]
  -p, --private=TAG    retrieve only alerts with named private tags,
                       comma delimited.
  -s, --shared=TAG     retrieve only alerts with named shared tags, comma
                       delimited.
```

### Examples

List all alerts in human-readable format. Alerts are separated by a
single blank line.

```
$ wavefront alerts -P sysdef all
name                  over memory cap
created               2016-06-06 13:35:32 +0100
severity              SMOKE
condition             deriv(ts("prod.www.host.tenant.memory_cap.nover")) > 0
displayExpression     ts("prod.www.host.tenant.memory_cap.nover")
minutes               2
resolveAfterMinutes   10
updated               2016-06-06 13:35:32 +0100
alertStates           CHECKING
metricsUsed
hostsUsed
additionalInformation A process has pushed the instance over its memory cap.
                      That is, the `memory_cap:nover` counter has been
                      incremented. Check memory pressure.

name                  JPC Memory Shortage
created               2016-05-16 16:49:20 +0100
severity              WARN
...
```

Show alerts currently firing, in JSON format:

```
$ wavefront alerts -P sysdef --format ruby active
"[{\"customerTagsWithCounts\":{},\"userTagsWithCounts\":{},\"created\":1459508340708,\"name\":\"Point Rate\",\"conditionQBEnabled\":false,\"displayExpressionQBEnabled\":false,\"condition\":\"sum(deriv(ts(~collector.points.valid))) > 50000\",\"displayExpression\":\"sum(deriv(ts(~collector.points.valid)))\",\"minutes\":5,\"target\":\"alerts@company.com,\",\"event\":{\"name\":\"Point Rate\",\"startTime\":1467049323203,\"annotations\":{\"severity\":\"severe\",\"type\":\"alert\",\"created\":\"1459508340708\",\"target\":\"alerts@company.com,\"},\"hosts\":[\"\"],\"table\":\"sysdef\"},\"failingHostLabelPairs\":[{\"label\":\"\",\"observed\":5,\"firing\":5}],\"updated\":1467049317802,\"severity\":\"SEVERE\",\"additionalInformation\":\"We have exceeded our agreed point rate.\",\"activeMaintenanceWindows\":[],\"inMaintenanceHostLabelPairs\":[],\"prefiringHostLabelPairs\":[],\"alertStates\":[\"ACTIVE\"],\"inTrash\":false,\"numMetricsUsed\":1,\"numHostsUsed\":1}]"
```

## `event` Mode: Opening and Closing Events

The `event` command is used to open and close Wavefront events.

```
Usage:
  wavefront event create [-V] [-c file] [-P profile] [-E endpoint] [-t token]
           [-d description] [-s time] [-i | -e time] [-l level] [-t type]
           [-H host] [-n] <event>
  wavefront event close [-V] [-c file] [-P profile] [-E endpoint] [-t token]
           [<event>] [<timestamp>]
  wavefront event delete [-V] <timestamp> <event>
  wavefront event show
  wavefront event --help

Options:
  -E, --endpoint=URI   cluster endpoint [default: metrics.wavefront.com]
  -i, --instant        create an instantaneous event
  -V, --verbose        be verbose
  -s, --start=TIME     time at which event begins
  -e, --end=TIME       time at which event ends
  -l, --level=LEVEL    level of event (info, smoke, warn, severe)
  -T, --type=TYPE      type of event
  -d, --desc=STRING    description of event
  -H, --host=STRING    list of hosts to tag with even (comma separated)
  -n, --nostate        do not create a local file recording the event
```

To close an event in the Wavefront API it must be identified by its
name and the millisecond time at which it was opened. This
information is returned when the event is opened, and the
`wavefront` command provides a handy way of caching it locally.

When a non-instantaneous event is opened and no end time is
specified, the CLI will write a file to
`/var/tmp/wavefront/event/<username>`. The name of the file
is the time the event was opened followed by `::`, followed by the
name of the event. Consider the `event/` directory as a stack:
a newly opened event is "pushed" onto the "stack". Running
`wavefront event close` simply pops the last event off the stack and
closes it. You can be more specific by running `wavefront event
close <name>`, which will close the last event opened and called `name`.

You can also specify the open-time when closing and event, bypassing
the local caching mechanism altogether.

When deleting an event you must supply the timestamp in epoch-milliseconds.
This level of precision is required by Wavefront's API, and it is
troublesome for the user to supply millisecond-accurate timestamps in any
other format.

The `wavefront event show` command lists the cached events. To
properly query events, use the `events()` command in a `ts` query.

### Examples

Create an instantaneous alert, bound only to the host making the API
call. Show the data returned by Wavefront.

```
$ wavefront event create -d "something important just happened" -i \
  -V instantaneous_event
{
  "name": "instantaneous_event",
  "startTime": 1467049673400,
  "endTime": 1467049673401,
  "annotations": {
    "details": "something important just happened"
  },
  "hosts": [
    "box"
  ],
  "isUserEvent": true,
  "table": "sysdef"
}
```

Mark a Puppet run by opening an event of `info` level, to be closed
when the run finishes.

```
$ ./wavefront event create -P sysdef -d 'Puppet run' -l info puppet_run
Event state recorded at /var/tmp/wavefront/events/rob/1467051916712::puppet_run.
```

The run has finished, close the event.

```
$ wavefront event close puppet_run
Closing event 'puppet_run'. [2016-06-27 19:25:16 +0100]
Removing state file /var/tmp/wavefront/events/rob/1467051916712::puppet_run.
```

Delete an event created in error.

```
$ wavefront delete 1476187357169 some_event
```

## `write` Mode: Sending Points to Wavefront

The `write` command is used to put data points into Wavefront. It is
different from other commands in that it communicates with a
**proxy** rather than with the Wavefront API. This means it does
not require any credentials.

```
Usage:
  wavefront write point [-DV] [-c file] [-P profile] [-E proxy] [-t time]
           [-p port] [-H host] [-n] [-T tag...] <metric> <value>
  wavefront write file [-DV] [-c file] [-P profile] [-E proxy] [-H host]
           [-p port] [-n] [-F format] [-m metric] [-T tag...] <file>

Options:
  -E, --proxy=URI      proxy endpoint [default: wavefront]
  -t, --time=TIME      time of data point (omit to use current time)
  -H, --host=STRING    source host [default: box]
  -p, --port=INT       Wavefront proxy port [default: 2878]
  -T, --tag=TAG        point tag in key=value form
  -F, --format=STRING  format of input file or stdin [default: tmv]
  -n, --noop           show the metric without sending it
  -m, --metric=STRING  the metric path to which contents of a file will be
                       assigned. If the file contains a metric name, the two
                       will be concatenated
  -V, --verbose        be verbose
```

`write` has two sub-commands: `write point` and `write file`. Both
allow you to specify the proxy address and port either with
command-line switches, or by the `proxy` and `port` values in your
`.wavefront` file.

### `write point`

This provides a very quick method of putting a point into Wavefront.
It takes two mandatory arguments: the metric path, and the metric
value.

You can optionally add point tags with multiple uses of `-T
key=val`, and specify a timestamp with the `-t` option.

### `write file`

`write file` takes a whitespace-separated file, and turns it into a
series of points, which it sends to a Wavefront proxy. Each line
will be mapped to a single point.

Each line in the file must be of the same format, and must contain a
value. It can optionally contain metric path, a timestamp, and point
tags. The format of the file is passed in with the `-F` option, and
it must contain only the letters `t` (timestamp), `m` (metric path),
`v` (value) and `T` (point tags). If `T` is used, it must come
last: this allows you to have as many point tags as you like, and
you do not have to have the same number for each point.

The metric can also be, to some extent, described by options. If you
do not have a metric path in the file, you can use `-m` to supply a
path to which every point will be assigned. If you use `-m` *and* a
field in the file, the two will be concatenated, with `-m` used as a
global prefix.

Similarly, a global timestamp can be supplied with `-t` (timestamps
in files must be in epoch seconds, but `-t` can be any `strptime()`
parseable string), and global point tags with one or more `-T
key=val`s. If you supply tags with `-T` and in the file, the points
will get both.

The input file does not have to be on disk: following the Unix
convention, you can use `-` as the filename, and `wavefront` will
read from standard in, converting lines to points as it receives
them. All the same rules apply as with standard files.

`wavefront write file` takes some efforts to protect the user from
sending bad data. It will not allow metrics with less than two
components, and it will not permit timestamps prior to 2000-01-01,
or more than a year in the future. It also checks that every
potential data point conforms to the limits described in the
Wavefront wire format documentation.

### Examples

Tell Wavefront that the value of `dev.myvalue` at this moment is
123.

```
$ wavefront write point dev.myvalue 123
```

Write a file of retrospective data, whwere the fields are, in order,
a timestamp, the metric path, and the value. Tag all points with
`mytag` set to `my value`.

```
$ wavefront write file -F tmvT -T mytag="my value" datafile
```

The command `parabola.rb` prints a timestamp and a 'y' value every
second. Plot the parabola in Wavefront.

```
$ parabola.rb | wavefront write file -F tv -m cli.demo.parabola -
```

## Notes on Options

### Times

Timeseries query windows and events be defined by using Unix epoch
times (as shown by `date "%+s"`) or by entering any Ruby
`strptime`-parseable string.  For instance:

```
$ wavefront --start 12:15 --end 12:20 ...
```

will request data points between 12:15 and 12:20pm today. If you ran
that in the morning, the time would be invalid, and you would get a
400 error from Wavefront, so something of the form
`2016-04-17T12:25:00` would remove all ambiguity.

There is no need to include a timezone in your time: the `wavefront`
CLI will automatically use your local timezone when it parses the
string.

### Default Configuration

Passing tokens and endpoints into the `wavefront` command can become
tiresome, so you can put such data into an `ini`-style configuration
file. By default this file should be located at `${HOME}/.wavefront`,
though you can override the location with the `-c` flag.

You can switch between Wavefront accounts using profile stanzas,
selected with the `-P` option.  If `-P` is not supplied, the
`default` profile will be used. Not having a useable configuration
file will not cause an error.

A configuration file looks like this:

```
[default]
token = abcdefab-1234-abcd-1234-abcdefabcdef
endpoint = companya.wavefront.com
format = human

[companyb]
token = 12345678-abcd-0123-abcd-123456789abc
endpoint = metrics.wavefront.com
```

The key for each key-value pair can match any long option show in the
command `help`, so you can set, for instance, a default output
format, as shown above.
