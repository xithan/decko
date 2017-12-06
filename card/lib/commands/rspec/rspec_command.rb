require 'rails/command/environment_argument'
require 'rails/commands/rake/rake_command'

module Card
  module Command
    class SeedCommand < ::Rails::Command::Base
      include ::Rails::Command::EnvironmentArgument
      class_option :spec, aliases: "-d", type: :string, # FILENAME(:LINE)
                   desc: "Run spec for a Decko deck file"
      class_option :core, aliases: "-c", type: :string,
                         desc: "Run spec for a Decko core file"
      class_option :mod, aliases: "-m", type: :string,
                   desc: "Run all specs for a mod or matching a mod"

      class_option :simplecov, aliases: "-s", type: :boolean,
                         desc: "Run with simplecov"
      class_option :rescue, aliases: "-r", type: :boolean,
                               desc: "Run with pry-rescue"

      def perform
        puts command
        exit_with_child_status command
      end

      def exit_with_child_status command
        command += " 2>&1"
        exit $CHILD_STATUS.exitstatus unless system command
      end

      # split special decko args and original command args separated by '--'
      def split_args args
        before_split = true
        decko_args, command_args =
          args.partition do |a|
            before_split = (a == "--" ? false : before_split)
          end
        command_args.shift
        [decko_args, command_args]
      end
    end
  end
end

