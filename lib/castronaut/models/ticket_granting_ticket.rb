module Castronaut
  module Models

    class TicketGrantingTicket < ActiveRecord::Base
      include Castronaut::Models::Consumeable
      include Castronaut::Models::Dispenser

      has_many :service_tickets, :dependent => :destroy

      before_validation :dispense_ticket, :if => :new_record?
      validates_presence_of :ticket, :identifier

      def self.validate_cookie(ticket_cookie)
        Castronaut.logger.debug("#{self} - Validating ticket for #{ticket_cookie}")

        return Castronaut::TicketResult.new(nil, "No ticket granting ticket given", 'warn') if ticket_cookie.nil?

        ticket_granting_ticket = find_by_ticket(ticket_cookie)

        if ticket_granting_ticket
          Castronaut.logger.debug("#{self} -[#{ticket_cookie}] for [#{ticket_granting_ticket.identifier}] successfully validated.")
          return Castronaut::TicketResult.new(ticket_granting_ticket, "Your session has expired. Please log in again.", 'warn') if ticket_granting_ticket.expired?
        else
          Castronaut.logger.debug("#{self} - [#{ticket_cookie}] was not found in the database.")
        end

        Castronaut::TicketResult.new(ticket_granting_ticket)
      end

      def self.generate_for(result, client_host)
        create! :identifier => result.identifier, :client_hostname => client_host, :extra_info => result.extra_info
      end
      
      def ticket_prefix
        "TGC"
      end
      
      def proxies
      end

      def to_cookie
        ticket
      end

      def expired? 
        false
      end
      
      
      # Serialized
      def extra_info
        value = self[:extra_info]
        value.nil? ? nil : YAML.load(value)
      end
      def extra_info= value
        self[:extra_info] = value.nil? ? nil : value.to_yaml
      end
      
      def extra_xml
        if self.extra_info.blank?
          nil
        else
          self.extra_info.to_xml :skip_instruct => true, :root => 'extra_info'
        end
      end

    end

  end
end
