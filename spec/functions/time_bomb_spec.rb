require 'spec_helper'

describe 'time_bomb' do
  let(:facts) { global_facts }
  context 'with no args' do
    it do
      should run.with_params().and_raise_error(Puppet::ParseError, "time_bomb requires 2 arguments, 0 provided. Usage: time_bomb(<earliest>, <latest | duration>)")
    end
  end

  context 'with one arg' do
    it do
      should run.with_params("fake").and_raise_error(Puppet::ParseError, "time_bomb requires 2 arguments, 1 provided. Usage: time_bomb(<earliest>, <latest | duration>)")
    end
  end

  context 'with three arg' do
    it do
      should run.with_params("fake", "bogus", "dummy").and_raise_error(Puppet::ParseError, "time_bomb requires 2 arguments, 3 provided. Usage: time_bomb(<earliest>, <latest | duration>)")
    end
  end

  context 'with two dates in order in the future' do
    it do
      should run.with_params("September 4, 2092 9am", "September 11, 2092 5pm").and_return(false)
    end
  end

  context 'with two dates in the present' do
    let(:facts) do
      global_facts.merge(
        :fqdn => 'puppet.test.host',
      )
    end
    it do
      # Change won't apply until 2056-02-06 12:35:00 -0800
      should run.with_params("September 4, 2017 9am", "September 11, 2092 5pm").and_return(false)
    end
  end

  context 'with two dates in order in the past' do
    it do
      should run.with_params("September 4, 1992 9am", "September 11, 1992 5pm").and_return(true)
    end
  end

  context 'with two dates out of order' do
    it do
      should run.with_params("September 11, 2092 5pm", "September 4, 2092 9am").and_raise_error(Puppet::ParseError, "Earliest date (2092-09-11 17:00:00 -0700) can't come after latest date (2092-09-04 09:00:00 -0700)!")
    end
  end

  context 'with two dates in order in the future and baking' do
    let(:facts) do
      global_facts.merge(
        :ami_baking => true,
      )
    end
    it do
      should run.with_params("September 4, 2092 9am", "September 11, 2092 5pm").and_return(false)
    end
  end

  context 'with two dates in order in the past and baking' do
    let(:facts) do
      global_facts.merge(
        :ami_baking => true,
      )
    end
    it do
      should run.with_params("September 4, 1992 9am", "September 11, 1992 5pm").and_return(true)
    end
  end

  context 'with two dates in order in the future and noop' do
    let(:facts) do
      global_facts.merge(
        :clientnoop => true,
      )
    end
    it do
      should run.with_params("September 4, 2092 9am", "September 11, 2092 5pm").and_return(true)
    end
  end

  context 'with two dates in order in the past and noop' do
    let(:facts) do
      global_facts.merge(
        :clientnoop => true,
      )
    end
    it do
      should run.with_params("September 4, 1992 9am", "September 11, 1992 5pm").and_return(true)
    end
  end

  context 'with one date and duration in in the past' do
    it do
      should run.with_params("September 4, 1992 9am", "1w").and_return(true)
    end
  end

  context 'with one date and duration in the present' do
    let(:facts) do
      global_facts.merge(
        :fqdn => 'puppet.test.host',
      )
    end
    it do
      # Change won't apply until 2088-02-20 07:32:29 -0800
      should run.with_params("September 4, 2017 9am", "75y").and_return(false)
    end
  end

  context 'with one date and duration in the future' do
    it do
      should run.with_params("September 4, 2092 9am", "1w").and_return(false)
    end
  end

  context 'with one date and bogus arg' do
    it do
      should run.with_params("September 4, 1992 9am", "bogus").and_raise_error(Puppet::ParseError, "Unknown latest time or duration. Usage: time_bomb(<earliest>, <latest | duration>)")
    end
  end

  context 'with one epoch and one date' do
    it do
      should run.with_params("715622400", "September 11, 1992 5pm").and_return(true)
    end
  end

  context 'with one date and one epoch' do
    it do
      should run.with_params("September 4, 1992 9am", "716256000").and_return(true)
    end
  end

  context 'with two epochs' do
    it do
      should run.with_params("715622400", "716256000").and_return(true)
    end
  end

  context 'with one time in the past and a duration in hours, which Time.parse() can parse' do
    it do
      should run.with_params("715622400", "12h").and_return(true)
    end
  end

  context 'with one bogus and and one date' do
    it do
      should run.with_params("bogus", "September 11, 1992 5pm").and_raise_error(Puppet::ParseError, "Unknown earliest time. Usage: time_bomb(<earliest>, <latest | duration>)")
    end
  end


  Puppet::Util::Log.level = :debug
  Puppet::Util::Log.newdestination(:console)
end
