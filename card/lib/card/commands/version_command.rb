class Card
  module Command
    class VersionCommand < ::Rails::Command::Base
      def perform
        require_application_and_environment!
        require_dependency "card"
        puts "Decko #{Card::Version.release}"
      end
    end
  end
end
