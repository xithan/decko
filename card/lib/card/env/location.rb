class Card
  module Env
    module Location
      # card_path    makes a relative path site-absolute (if not already)
      # card_url     makes it a full url (if not already)

      def card_path rel_path
        unless rel_path.is_a? String
          Rails.logger.warn "Pass only strings to card_path. "\
                            "(#{rel_path} = #{rel_path.class})"
        end
        if rel_path =~ %r{^(https?\:)?/}
          rel_path
        else
          "#{Card.config.relative_url_root}/#{rel_path}"
        end
      end

      def card_url rel
        rel =~ /^https?\:/ ? rel : "#{protocol_and_host}#{card_path rel}"
      end

      def protocol_and_host
        Card.config.protocol_and_host || "#{Env[:protocol]}#{Env[:host]}"
      end

      def cardname_from_url url
        m = url.match cardname_from_url_regexp
        m ? Card::Name[m[:mark]] : nil
      end

      private

      def cardname_from_url_regexp
        return unless Env[:host]

        %r{#{Regexp.escape Env[:host]}/(?<mark>[^\?]+)}
      end

      extend Location # allows calls on Location constant, eg Location.card_url
    end
  end
end
