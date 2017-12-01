module Decko
  module Command
    class CreateUserCommand < ::Rails::Command::Base
      # namespace "card"
      desc 'create_user', 'Creates an admin user'
      def perform
        require_application_and_environment!
        puts Card[:home].name
      end
    end
  end
end

