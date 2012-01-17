module CloudFoundry
  class AppNameGenerator
    MAX_NAME_TRIES = 10

    def initialize name, cloud=".cloudfoundry.com"
      @name = name
      @cloud = cloud
      @tries = 0
      @base_name = name.gsub /-?(\d+)$/, ''
      @base_index = $1  || 0
    end


    def next
      if @tries < MAX_NAME_TRIES
        @tries += 1
        "#{@base_name}-#{@base_index + @tries}"
      else
        nil
      end
    end


    def self.is_valid_subdomain name
      ((name =~  /^[a-zA-Z][\-a-zA-Z0-9]+$/) == 0)
    end

    def find_available_app_name external_email, external_app_name, stem
      clean_name = get_valid_subdomain external_app_name, stem
      generated_name = clean_name

      unless is_available_app_name?(generated_name)
        email_parts = external_email.split '@'
        # Nice name is not available so give them a generated semi safe name
        generated_name = "#{clean_name}-#{email_parts.first}"
        counter = 0
        while (!is_available_app_name?(generated_name))
          counter += 1
          if (counter > @tries)
            generated_name = nil
            break
          end
          generated_name = "#{clean_name}-#{email_parts.first}-#{counter}"
        end
      end
      generated_name
    end

    private
      # Returns a valid subdomain
      # http://www.ietf.org/rfc/rfc2396.txt
      # alpha    = lowalpha | upalpha
      # alphanum = alpha | digit
      # domainlabel   = alphanum | alphanum *( alphanum | "-" ) alphanum
      def get_valid_subdomain external_app_name, stem
        clean_name =  external_app_name.downcase.gsub(/[^-\w]+/m, '-').gsub(/_/, '-')  #underscores are not allowed

        # Cannot start with -
        if clean_name =~ /^-/
          clean_name = stem + clean_name
        end

        # Also weird to end with '-'
        clean_name = clean_name[0..clean_name.length-2] if clean_name =~ /-$/

        clean_name
      end

      # Cheks by issuing HTTP requests
      # Needs to be optimized. Do map instead
      def is_available_app_name? name
        begin
          url = "http://#{name}#{@cloud}"
          puts "Checking #{url} if available"
          response = RestClient.get url
        rescue Exception => ex
          puts "#{url} is available"
          return true
        end
        return false
      end
  end
end