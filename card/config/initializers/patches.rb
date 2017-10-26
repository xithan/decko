#:nodoc: all
module Kaminari
  module Helpers
    class Tag
      include Patches::Kaminari::Helpers::Tag
    end
  end
end

if defined? BetterErrors
  #:nodoc: all
  module BetterErrors
    class StackFrame
      suppress_warnings { include Patches::BetterErrors::StackFrame::TmpPath }
    end
  end
end

#:nodoc: all
module ActiveRecord
  class Relation
    include Patches::ActiveRecord::Relation
  end

  module ConnectionAdapters
    class AbstractAdapter
      prepend Patches::ActiveRecord::ConnectionAdapters::AbstractAdapter
    end

    class PostgreSQLAdapter
      prepend Patches::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end

    class MysqlAdapter
      include Patches::ActiveRecord::ConnectionAdapters::MysqlCommon
    end

    class Mysql2Adapter
      include Patches::ActiveRecord::ConnectionAdapters::MysqlCommon
    end

    class SQLiteAdapter
      include Patches::ActiveRecord::ConnectionAdapters::SQLiteAdapter
    end
  end
end

#:nodoc: all
module ActiveJob::Arguments
  class << self
    prepend Patches::ActiveJob::Arguments
  end
end

#:nodoc: all
module ActionDispatch
  class Reloader
    extend Patches::ActionDispatch::Reloader
  end
end

#:nodoc: all
module ActiveSupport
  module Callbacks
    class Callback
      prepend Patches::ActiveSupport::Callbacks::Callback
    end
  end
end
