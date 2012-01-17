# Original Author: Dave McCrory in repo cf-meta

module CloudFoundry
  class App
    DEFAULT_CF = ".cloudfoundry.com"
    MAX_NAME_TRIES = 10

    attr_accessor :name_changed, :display_name

    def self.is_available_app_name? name, cloud=DEFAULT_CF
      begin
        url = "http://#{name}#{cloud}"
        puts "Checking #{url} if available"
        response = RestClient.get url
      rescue Exception => ex
        puts "#{url} is available "
        return true
      end
      return false
    end

    def self.is_valid_subdomain name
      ((name =~  /^[a-zA-Z][\-a-zA-Z0-9]+$/) == 0)
    end

    # Returns a valid subdomain
    # http://www.ietf.org/rfc/rfc2396.txt
    # alpha    = lowalpha | upalpha
    # alphanum = alpha | digit
    # domainlabel   = alphanum | alphanum *( alphanum | "-" ) alphanum
    def self.get_valid_subdomain external_app_name, stem
      clean_name =  external_app_name.downcase.gsub(/[^-\w]+/m, '-').gsub(/_/, '-')  #underscores are not allowed

      # Cannot start with -
      if clean_name =~ /^-/
        clean_name = stem + clean_name
      end

      # Also weird to end with '-'
      clean_name = clean_name[0..clean_name.length-2] if clean_name =~ /-$/

      clean_name
    end

    def self.find_available_app_name external_email, external_app_name, stem, cloud=DEFAULT_CF

      clean_name = get_valid_subdomain external_app_name, stem
      generated_name = clean_name

      unless CloudFoundry::App.is_available_app_name?(generated_name, cloud)
        email_parts = external_email.split '@'
        # Nice name is not available so give them a generated semi safe name
        generated_name = "#{clean_name}-#{email_parts.first}"
        counter = 0
        while (!CloudFoundry::App.is_available_app_name?(generated_name, cloud))
          counter += 1
          if (counter > MAX_NAME_TRIES)
            generated_name = nil
            break
          end
          generated_name = "#{clean_name}-#{email_parts.first}-#{counter}"
        end
      end
      generated_name
    end

    def initialize(vmc_client, meta, cloud=DEFAULT_CF)
      @cloud = cloud
      @name_changed = false
      @vmcclient = vmc_client
      @app_meta = meta
      @base_name = @app_meta.display_name.gsub /-?(\d+)$/, ''
      puts "********** Base Name is #{@base_name} for #{@app_meta.display_name}"
      @base_index = $1  || 0
      build_manifest!
    end

    def create(options={})
      begin
        @vmcclient.create_app(@manifest["name"], @manifest)
      rescue RuntimeError => ex
        if (ex.message =~ /Error 701/)
          pick_another_name_if_taken = options[:pick_another_name_if_taken] == true ? true : false
          tries_left = options[:tries_left] || MAX_NAME_TRIES
          if pick_another_name_if_taken && tries_left > 0
            index = MAX_NAME_TRIES - tries_left + 1 + @base_index
            change_name! "#{@base_name}-#{index}"
            create(:pick_another_name_if_taken => true, :tries_left => tries_left - 1)
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