module Sequares
  module RepositoryCommon
    private def _hash_event(event)
      Digest::SHA256.hexdigest(Marshal.dump(event))
    end
  end
end
