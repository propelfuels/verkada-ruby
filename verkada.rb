require_relative './neko-http.rb'

module VerkadaAPI
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= NullLogger.new()
  end

  class Org
    attr_reader :cameras
    attr_accessor :logger

    def initialize(org_id, api_key)
      @logger = VerkadaAPI.logger
      @org_id = org_id
      @api_key = api_key
      @cameras = []
    end

    def notifications(params = nil)
      resp = http_get('notifications')
      return nil unless resp[:code] == 200
      nots = resp.dig(:parsed, :notifications)
      if nots.nil?
        logger.warn('Verkada call error: no notifications found')
        return nil
      end
      nots
    end

    def audit_logs
      resp = http_get('auditlog')
      return nil unless resp[:code] == 200
      logs = resp.dig(:parsed, :audit_logs)
      if logs.nil?
        logger.warn('Verkada call error: no audit logs found')
        return nil
      end
      logs
    end

    def refresh_cameras
      resp = http_get('cameras')
      return false unless resp[:code] == 200
      cams = resp.dig(:parsed, :cameras)
      if cams.nil?
        logger.warn('Verkada call error: no cameras found')
        return false
      end
      cameras.clear
      cams.each do |c|
        cameras << Camera.new(c, self)
      end
      true
    end

    def http_get(path, q = nil)
      url = "https://api.verkada.com/orgs/#{@org_id}/#{path}"
      hdrs = {'x-api-key' => @api_key, 'Accept' => 'application/json'}
      resp = Neko::HTTP.get(url, q, hdrs)
      if resp[:code] == 200
        resp[:parsed] = JSON.parse(resp[:body], {symbolize_names: true})
      else
        logger.warn("Verkada call failed: HTTP#{resp[:code]} #{resp[:message]}")
      end
      resp
    end
  end

  class Camera
    attr_reader :id, :date_added, :device_retention, :firmware, :last_online
    attr_reader :local_ip, :location, :lat, :lon, :mac, :model, :name
    attr_reader :serial, :site, :status, :org

    def initialize(data, org)
      if Hash === data
        d = data
      else
        raise ArgumentError.new("Expected a Hash, got #{data.class}")
      end
      @org = org
      @id = d[:camera_id]
      @date_added = Time.at(d[:date_added]) if Integer === d[:date_added]
      @device_retention = d[:device_retention]
      @firmware = d[:firmware]
      @last_online = Time.at(d[:last_online]) if Integer === d[:last_online]
      @local_ip = d[:local_ip]
      @location = d[:location]
      @lat = d[:lat]
      @lon = d[:lon]
      @mac = d[:mac]
      @model = d[:model]
      @name = d[:name]
      @serial = d[:serial]
      @site = d[:site]
      @status = d[:status].downcase.to_sym if String === d[:status]
    end

    def object_counts(params = nil)
      resp = org.http_get("cameras/#{id}/objects/counts", params)
      return nil unless resp[:code] == 200
      objs = resp.dig(:parsed, :object_counts)
      if objs.nil?
        org.logger.warn('Verkada call error: no objects found')
        return nil
      end
      objs
    end

    def thumbnail(time = Time.now - 60)
      resp = org.http_get("cameras/#{id}/thumbnail/#{time.to_i}")
      return nil unless resp[:code] == 200
      obj = resp[:parsed]
      if obj.nil?
        org.logger.warn('Verkada call error: empty')
        return nil
      end
      obj
    end

    def history(time = Time.now - 60)
      resp = org.http_get("cameras/#{id}/history/#{time.to_i}")
      return nil unless resp[:code] == 200
      url = resp.dig(:parsed, :url)
      if url.nil?
        org.logger.warn('Verkada call error: empty')
        return nil
      end
      url
    end
  end

  class NullLogger < Logger
    def initialize(*args)
    end

    def add(*args, &block)
    end
  end
end
