class GuestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "guest_channel"
  end

  def unsubscribed
    stop_all_streams
  end
end
