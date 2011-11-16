require 'tmpdir'
require 'open-uri'
require 'zip/zipfilesystem'
require 'pry'

# Original Author: Dave McCrory in repo cf-meta
module CloudFoundry
  class Builder
    PACK_EXCLUSION_GLOBS = ['..', '.', '*~', '#*#', '*.log']

    def create_app(vmc_client, name,type, *args)
      @vmcclient = vmc_client
        @currentname = name
        @name = name
        @type = type
        if args[0] != nil then
          arg = args[0]
          arg.each do |key,value|
            if key == "memory" then
              @memory = value
            end
            if key == "path" then
              @path = value
            end
            if key == "location" then
              @location = value
            end
            if key == "upload" then
              @upload = value
            end
            if key == "start" then
              @start = value
            end

          end
        end
        if @path == nil then
          @path = ".cloudfoundry.com"
          @uri = "#{@name}#{@path}"
        else
          @uri = "#{@name}#{@path}"
        end
        if @memory == nil then
          case @type
          when "sinatra"
            @memory = 128
          when "rails"
            @memory = 256
          when "spring"
            @memory = 512
          when "grails"
            @memory = 512
          when "roo"
            @memory = 512
          when "javaweb"
            @memory = 512
          when "node"
            @memory = 64
          else
            @memory = 256
          end
        end
        case @type
        when "rails"
          @framework = "rails3"
        when "spring"
          @framework = "spring"
        when "grails"
          @framework = "grails"
        when "roo"
          @framework = "spring"
        when "javaweb"
          @framework = "spring"
        when "sinatra"
          @framework = "sinatra"
        when "node"
          @framework = "node"
        else
          @framework = "unknown"
        end
        if @location == nil then
          @location = "./#{@name}"
        end

        manifest = {"name"=>@name, "staging"=>{"framework"=>@framework, "runtime"=>nil}, "uris"=>[@uri], "instances"=>1, "resources"=>{"memory"=>@memory}}

        @vmcclient.create_app(@name,manifest)
        if @upload == true then
          upload_app(@name,@location)
        end
        if @start == true then
          start_app(@name)
        end
      end

    def upload_app(name=@currentname,location="./#{@currentname}")
      unless get_files_to_pack(@location).empty?
        zipfile = "#{Dir.tmpdir}/#{name}.zip"
        pack(location, zipfile)
        puts "Packed files to #{zipfile}"
        @vmcclient.upload_app(name, zipfile)
      end
    end

    def get_files_to_pack(dir)
      Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select do |f|
        process = true
        PACK_EXCLUSION_GLOBS.each { |e| process = false if File.fnmatch(e, File.basename(f)) }
        process && File.exists?(f)
      end
    end

    def pack(dir, zipfile)
      File::delete("#{zipfile}") if File::exists?("#{zipfile}")
      Zip::ZipFile::open(zipfile, true) do |zf|
        get_files_to_pack(dir).each do |f|
          zf.add(f.sub("#{dir}/",''), f)
        end
      end
    end

    def unpack(file, dest)
      Zip::ZipFile.foreach(file) do |zentry|
        epath = "#{dest}/#{zentry}"
        dirname = File.dirname(epath)
        FileUtils.mkdir_p(dirname) unless File.exists?(dirname)
        zentry.extract(epath) unless File.exists?(epath)
      end
    end

    def start_app(name=@currentname)
      appstate = @vmcclient.app_info(name)
      if appstate[:state] != 'STARTED' then
        appstate[:state] = 'STARTED'
        @vmcclient.update_app(name, appstate)
      end
    end

    def get_app(name,path='/')
      open(name, 'wb') do |getfile|
        getfile.print open(path).read
      end
    end
  end
end