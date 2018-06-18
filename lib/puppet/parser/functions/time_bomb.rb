require 'time'

class String
  def numeric?
    Float(self) != nil rescue false
  end
end

module Puppet::Parser::Functions

  newfunction(:time_bomb, :type => :rvalue, :doc =>
    'time_bomb allows you to slowly deploy a dangerous
Puppet change to a large number of servers.

You specify the earliest datetime that the changes should begin to get deployed along with when you wish the changes to be done getting deployed. time_bomb will randomly decide on a time in the range to apply the change for each server.

') do |args|

    earliest_string = args[0]
    latest_string = args[1]
    if args.length != 2
      raise Puppet::ParseError, "time_bomb requires 2 arguments, #{args.length} provided. Usage: time_bomb(<earliest>, <latest | duration>)"
    end
    begin
      earliest = Time.parse(earliest_string)
    rescue ArgumentError
      if earliest_string.numeric?
        begin
          earliest = Time.at(earliest_string.to_i)
        rescue ArgumentError
          raise Puppet::ParseError, "Unknown earliest time. Usage: time_bomb(<earliest>, <latest | duration>)"
        end
      else
        raise Puppet::ParseError, "Unknown earliest time. Usage: time_bomb(<earliest>, <latest | duration>)"
      end
    end

    if /^(?<amount>\d+)(?<unit>[hdwmy])$/ =~ latest_string
      unit_map = {
        'h' => 3_600,
        'd' => 86_400,
        'w' => 604_800,
        'm' => 2_419_200,
        'y' => 29_030_400
      }
      latest = earliest + amount.to_i * unit_map.fetch(unit)
    else
      begin
        latest = Time.parse(latest_string)
      rescue ArgumentError
        if latest_string.numeric?
          begin
            latest = Time.at(latest_string.to_i)
          rescue ArgumentError
            raise Puppet::ParseError, "Unknown latest time or duration. Usage: time_bomb(<earliest>, <latest | duration>)"
          end
        else
            raise Puppet::ParseError, "Unknown latest time or duration. Usage: time_bomb(<earliest>, <latest | duration>)"
        end
      end
    end

    if earliest > latest
      raise Puppet::ParseError, "Earliest date (#{earliest}) can't come after latest date (#{latest})!"
    end
    now = Time.now

    start = Time.at(function_fqdn_rand([latest.to_i - earliest.to_i]) + earliest.to_i)
    noop = lookupvar('::clientnoop')
    ami_baking = lookupvar('::ami_baking')

    # We always return true in noop mode
    # This allows users to make sure the gated/risky changes look correct.
    # We output a warning
    if noop
      function_notice(["Pretending like we are in the future. If we weren't in noop mode, time_bomb would execute after #{start}"])
      return true
    end

    # We always return false when baking amis until we are past `latest`
    # If we were to apply a change while baking, it is possible time_bomb would
    # later return a different value when a host is launched with the ami (and
    # a new fqdn). This would cause risky Puppet changes to potentially get
    # reverted and/or applied a second time.
    if ami_baking && now < latest
      function_notice(["Not applying time_bomb while baking ami"])
      return false
    end

    now > start
  end
end
