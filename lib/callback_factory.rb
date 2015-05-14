require "mail"

# This module provides utility functions to add callbacks to the {JobManager}.
module CallbackFactory
  @batch = []

  # Adds a mail delivery  callback to the job manager.
  # It will accumulate a fixed number of events and writes a mail using the mail
  # library.
  # @param type [Symbol] Type of callback.
  # @param selector [Regexp] The selector of the callback.
  # @param batch_size [Integer] Number of events in the mails.
  # @param to [String] Recipient of the mails.
  def CallbackFactory.generate_mail_for_batch_callback(type, selector,
                                                       batch_size, to)
    callback = lambda do |type, identifier|
      @batch << { :type => type, :identifier => identifier }
      if @batch.length >= batch_size then
        batch = @batch.dup
        @batch = {}
        begin
          Mail.deliver do
            from     'FODOR'
            to       to
            subject  ('FODOR Report %s' % [])
            body     batch.to_s
          end
        rescue Exception => e
          puts "Mail Delivery failed:"
          puts e
        end
      end
    end
    $JOBMANAGER.register_callback(type, callback, selector) 
  end
end
