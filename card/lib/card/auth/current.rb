class Card
  module Auth
    # methods for setting current account
    module Current
      # set current user in process and session
      def signin signin_id
        self.current_id = signin_id
        set_session_user signin_id
      end

      # current user is not anonymous
      # @return [true/false]
      def signed_in?
        current_id != Card::AnonymousID
      end

      # id of current user card.
      # @return [Integer]
      def current_id
        @current_id ||= Card::AnonymousID
      end

      # current accounted card (must have +\*account)
      # @return [Card]
      def current
        if @current && @current.id == current_id
          @current
        else
          @current = Card[current_id]
        end
      end

      # set the id of the current user.
      def current_id= card_id
        @current = @as_id = @as_card = @current_roles = nil
        card_id = card_id.to_i if card_id.present?
        @current_id = card_id
      end

      # set current user from email or id
      # @return [Integer]
      def current= mark
        self.current_id =
          if mark.to_s =~ /@/
            account = Auth.find_account_by_email mark
            account && account.active? ? account.left_id : Card::AnonymousID
          else
            mark
          end
      end

      def current_roles
        @current_roles ||= [Card.fetch_name(:anyone_signed_in),
                            current.fetch(trait: :roles)&.item_names].flatten.compact
      end

      def no_special_roles?
        Auth.current_roles.size == 1 # &&
        # Auth.current_roles.first == Card.fetch_name(:anyone_signed_in)
      end

      def clear_current_roles
        @current_roles = nil
      end

      def serialize
        { as_id: as_id, current_id: current_id }
      end

      # @param auth_data [Integer|Hash] user id, user name, or a hash
      # @option auth_data [Integer] current_id
      # @option auth_data [Integer] as_id
      def with auth_data
        case auth_data
        when Integer
          auth_data = { current_id: auth_data }
        when String
          auth_data = { current_id: Card.fetch_id(auth_data) }
        end

        tmp_current_id = current_id
        tmp_as_id = as_id
        tmp_current = @current
        tmp_as_card = @as_card
        tmp_current_roles = @current_roles

        # resets @as and @as_card
        self.current_id = auth_data[:current_id]
        @as_id = auth_data[:as_id] if auth_data[:as_id]
        yield
      ensure
        @current_id = tmp_current_id
        @as_id = tmp_as_id
        @current = tmp_current
        @as_card = tmp_as_card
        @current_roles = tmp_current_roles
      end

      # get session object from Env
      # return [Session]
      def session
        Card::Env.session
      end

      # set current from token or session
      def set_current opts={}
        if opts[:token]
          set_current_from_token opts[:token]
        elsif opts[:api_key]
          set_current_from_api_key opts[:api_key]
        else
          set_current_from_session
        end
      end

      # set the current user based on token
      def set_current_from_token token
        payload = Token.validate! token
        self.current_id = payload[:anonymous] ? Card::AnonymousID : payload[:user_id]
      end

      # set the current user based on api_key
      def set_current_from_api_key api_key
        account = find_account_by_api_key api_key
        unless account&.validate_api_key! api_key
          raise Card::Error::PermissionDenied, "API key authentication failed"
        end

        self.current = account.left_id
      end

      # get :user id from session and set Auth.current_id
      def set_current_from_session
        self.current_id =
          if (card_id = session_user) && Card.exists?(card_id)
            card_id
          else
            set_session_user Card::AnonymousID
          end
      end

      # find +\*account card by +\*api card
      # @param token [String]
      # @return [+*account card, nil]
      def find_account_by_api_key api_key
        find_account_by "api_key", Card::ApiKeyID, api_key.strip
      end

      # find +\*account card by +\*email card
      # @param email [String]
      # @return [+*account card, nil]
      def find_account_by_email email
        find_account_by "email", Card::EmailID, email.strip.downcase
      end

      # general pattern for finding +\*account card based on field cards
      # @param fieldname [String] right name of field card (for WQL comment)
      # @param field_id [Integer] card id of field's simple card
      # @param value [String] content of field
      # @return [+*account card, nil]
      def find_account_by fieldname, field_id, value
        Auth.as_bot do
          Card.search({ right_id: Card::AccountID,
                        right_plus: [{ id: field_id },
                                     { content: value }] },
                      "find +:account for #{fieldname} (#{value})").first
        end
      end

      def session_user
        session[session_user_key]
      end

      def set_session_user card_id
        session[session_user_key] = card_id
      end

      def session_user_key
        "user_#{database.underscore}".to_sym
      end

      def database
        Rails.configuration.database_configuration.dig Rails.env, "database"
      end
    end
  end
end
