class Card
  module Command
    class Base < ::Rails::Command::Base
      class << self
        # def inherited(base)
        #   super
        #
        #   if base.name && base.name !~ /Base$/
        #     Rails::Command.subclasses << base
        #   end
        # end

        # Default file root to place extra files a command might need, placed
        # one folder above the command file.
        #
        # For a `Rails::Command::TestCommand` placed in `rails/command/test_command.rb`
        # would return `rails/test`.
        def default_command_root
          path = File.expand_path(File.join("../commands", command_root_namespace), __dir__)
          path if File.exist?(path)
        end
      end
    end
  end
end
