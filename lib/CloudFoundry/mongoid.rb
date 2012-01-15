require 'mongoid'
require 'mongo/connection'

include Mongo
include Mongoid

module CloudFoundry
  class Mongo
      def self.config
        Mongoid.configure do |config|
          conn_info = nil

          dbname = 'db'
          if ENV['VCAP_SERVICES']
            services = JSON.parse ENV['VCAP_SERVICES']
            services.each do |service_version, bindings|
              mongo_binding = bindings.find {|binding| binding['label'] =~ /mongo/i}
              conn_info = mongo_binding['credentials'] if mongo_binding
            end
            raise "ERROR - Could not find connection info for mongo" unless conn_info
          else
            conn_info = {'hostname' => 'localhost', 'port' => 27017}
            dbname = "gallery_db"
          end

          @@cnx = Mongo::Connection.new conn_info['hostname'], conn_info['port'], :pool_size => 5, :timeout => 5
          db = @@cnx[dbname]
          if conn_info['username'] and conn_info['password']
            db.authenticate conn_info['username'], conn_info['password']
          end

          config.master = db
        end
     end
  end
end