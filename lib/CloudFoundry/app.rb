# Original Author: Dave McCrory in repo cf-meta

module CloudFoundry
  class App
    DEFAULT_CF = ".cloudfoundry.com"
    MAX_NAME_TRIES = 10

    attr_accessor :name_changed, :display_name

    def initialize(vmc_client, meta, cloud=DEFAULT_CF)
      @cloud = cloud
      @name_changed = false
      @vmcclient = vmc_client
      @app_meta = meta
      build_manifest!
      @generator = AppNameGenerator.new @app_meta.display_name, @cloud
    end

    def create()
      begin
        @vmcclient.create_app(@manifest["name"], @manifest)
      rescue RuntimeError => ex
        if (ex.message =~ /Error 701/)
          new_candidate = @generator.next
          unless new_candidate.nil?
            change_name! new_candidate
            create
          else
            # Format is "Error #{parsed_body[:code]}: #{desc}"
            raise "App Url: #{@uri} is already taken"
          end
        else
          raise ex
        end
      end
    end

    def delete()
      @vmcclient.delete_app(@manifest["name"])
    end

    def copy_code()
      @vmcclient.upload_app(@app_meta.display_name, @app_meta.build!)
    end

    def exists?
      begin
        read_info
        return true
      rescue VMC::Client::NotFound => ex
        return false
      end
    end

    def start()
      read_info()

      if @info[:state] != 'STARTED' then
        @info[:state] = 'STARTED'
        @vmcclient.update_app(@app_meta.display_name, @info)
      end
    end

    def read_info
      @info = @vmcclient.app_info(@app_meta.display_name)
      @app_meta.app_urls = @info[:uris]
      @info
    end

    def change_name! new_name
      unless CloudFoundry::AppNameGenerator.is_valid_subdomain(new_name)
        raise "'#{new_name}' is not a valid subdomain name"
      end
      @app_meta.display_name = new_name
      @name_changed = true
      build_manifest!
    end

    private

      def build_manifest!
        @display_name = @app_meta.display_name
        @uri = "#{@display_name}#{@cloud}"

        @manifest = {
           "env" => @app_meta.env_array,
           "name"=> @display_name,
           "staging"=>{"framework"=>@app_meta.framework, "runtime"=>@app_meta.runtime},
           "uris"=>[@uri],
           "instances"=>1,
           "resources"=>{"memory"=>@app_meta.memory}
        }
      end
  end
end