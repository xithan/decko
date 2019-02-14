class Card
  class Proxy < BasicObject
    include ::Kernel
    def initialize card
      @card = card
    end

    def replace card
      @card = card
    end

    def respond_to_missing? method, _include_private=false
      @card.respond_to? method
    end

    def method_missing method_name, *args, &block
      if block_given?
        @card.send(method_name, *args, &block)
      else
        @card.send(method_name, *args)
      end
    end
  end

  module Proxifier
    def new_mutable args
      Proxy.new new(args)
    end
  end
end
