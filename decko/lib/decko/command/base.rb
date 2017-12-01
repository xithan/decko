module Decko
  module Command
    class Base < ::Rails::Command::Base
      def self.inherited(base) #:nodoc:
         super

         if base.name && base.name !~ /Base$/
           Rails::Command.subclasses << base
         end
       end
    end
  end
end
