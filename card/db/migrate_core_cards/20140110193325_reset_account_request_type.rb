# -*- encoding : utf-8 -*-

class ResetAccountRequestType < Card::Migration::Core
  def up
    arcard = Card[:signup]
    arcard.update type_id: Card::CardtypeID if arcard.type_code != :cardtype
  end
end
