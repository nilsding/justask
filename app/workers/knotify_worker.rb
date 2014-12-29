class KnotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :knotify

  def perform(*_args)
    # TODO: ...
  end
end