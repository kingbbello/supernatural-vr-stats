class SupernaturalApiService
    BASE_URL = "https://api.getsupernatural.com/v1/feed/me".freeze
    HEADERS = {
      "cookie" => "session_id=64579098-96de-41ee-8c33-51bd2081efd4", # TODO: need a way to dynamically get this from user auth
      "accept" => "application/json",
      "content-type" => "application/json",
      "user-agent" => "Supernatural/345 CFNetwork/1568.300.101 Darwin/24.2.0",
      "accept-language" => "en-CA,en-US;q=0.9,en;q=0.8",
      "accept-encoding" => "gzip, deflate, br"
    }.freeze
  
    def fetch_all_data
      Rails.cache.fetch("supernatural_api_feed", expires_in: 1.week) do
        all_data = []
        page = 1
        per_page = 50
  
        loop do
          response = HTTP.headers(HEADERS).get(BASE_URL, params: { page: page, per_page: per_page })
  
          if response.status.success?
            data = JSON.parse(response.body.to_s)
            feed = data['data']['feed'] || []
            
            break if feed.empty? # Stop if no more data
            
            all_data.concat(feed) # Add feed to the results
            page += 1
          else
            Rails.logger.error "Error fetching data: #{response.status} #{response.body}"
            break
          end
        end
  
        all_data
      end
    end
  end
  