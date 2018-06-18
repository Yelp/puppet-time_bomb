# puppet-time_bomb

By default, Puppet has a [runinterval](https://puppet.com/docs/puppet/5.5/configuration.html#runinterval) of 30 minutes. This frequency can be adjusted and functions like [fqdn_rand()](https://puppet.com/docs/puppet/5.5/function.html#fqdnrand) can be used to space out the runs across hosts. However, for certain types of changes, having it deploy to potentially thousands of servers within one hour is simply too fast/risky. It would be much better if we could spread the deployment out over the course of a few hours, a day, or a week. This is why time_bomb() was created.

## time_bomb(\<earliest\>, \<latest | duration\>)

time_bomb() takes two arguments: the earliest possible time for your change to start getting deployed and the latest possible time (or a duration).

For example, to have a change gradually roll out over the course of a week:

```
if time_bomb("Mon Jan 22 09:00:00 PST 2018", "Fri Jan 26 17:00:00 PST 2018") {
	warning("Making a risky Puppet change")
}
```

or to have a change start at Wed Jan 17 15:39:21 PST 2018 and finish in 2 days:

```
if time_bomb("1516232361", "2d") {
	warning("Making a risky Puppet change")
}
```

As you can see, time_bomb() supports most common (and several less common) datetime formats.

The time_bomb function will always return `true` when run in noop mode, but it will helpfully print a message such as:

```
Notice: Scope(Class[Your::Class]): Pretending like we are in the future. If we weren't in noop mode, time_bomb would execute after 2018-01-17 19:43:47 -0800
```

time_bomb() will also always return `false` while baking AMIs (as determined by the `::ami_baking` fact) until `latest` is reached (Fri Jan 26 17:00:00 PST 2018 in the example above).

