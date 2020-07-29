require "httparty"
require "json"
require "yaml"
require "dbdoc/constants"

module Confluence
  CREDENTIALS_FILE = File.join(DBDOC_HOME, "config", "confluence.env")

  class Api
    include HTTParty
    base_uri "dbdoc.atlassian.net"

    def initialize
      credentials = YAML.load(File.read(CREDENTIALS_FILE))
      @username = credentials["username"]
      @token = credentials["token"]
      @space = credentials["space"]
    end

    def delete_page(page_id:)
      HTTParty.delete(
        "https://dbdoc.atlassian.net/wiki/rest/api/content/#{page_id}", {
          headers: {
            "Authorization" => "Basic #{basic_auth}",
            "Content-Type"  => "application/json"
          }
        }
      )
    end

    def existing_pages:)
      response = HTTParty.get(
        "https://dbdoc.atlassian.net/wiki/rest/api/content/?&spaceKey=#{@space}", {
          headers: {
            "Authorization" => "Basic #{basic_auth}",
            "Content-Type"  => "application/json"
          }
        }
      )

      JSON.parse(response.body)
    end

    def update_page(page_id:, body:, page_title:, version:)
      payload = {
        id: page_id,
        type: "page",
        title: page_title,
        space: {
          key: @space
        },
        body: {
          wiki: {
            value: body,
            representation: "wiki"
          }
        },
        version: {
          number: version
        }
      }

      response = HTTParty.put(
        "https://dbdoc.atlassian.net/wiki/rest/api/content/#{page_id}", {
          headers: {
            "Authorization" => "Basic #{basic_auth}",
            "Content-Type"  => "application/json"
          },
          body: payload.to_json
        }
      )

      if response.code == 200
        {
          response: response,
          page_id: JSON.parse(response.body)["id"]
        }
      else
        puts "--> ERROR UPLOADING #{page_title}: "
        pp response

        {
          response: response
        }
      end
    end

    def create_page(parent_page_id: nil, body:, page_title:)
      payload = {
        type: "page",
        title: page_title,
        space: {
          key: @space
        },
        body: {
          wiki: {
            value: body,
            representation: "wiki"
          }
        }
      }

      if parent_page_id
        payload.merge!({
          ancestors: [
            { id: parent_page_id }
          ]
        })
      end

      response = HTTParty.post(
        "https://dbdoc.atlassian.net/wiki/rest/api/content/", {
          headers: {
            "Authorization" => "Basic #{basic_auth}",
            "Content-Type"  => "application/json"
          },
          body: payload.to_json
        }
      )

      if response.code == 200
        {
          response: response,
          page_id: JSON.parse(response.body)["id"]
        }
      else
        puts "--> ERROR UPLOADING #{page_title}: "
        pp response

        {
          response: response
        }
      end
    end

    private

    def basic_auth
      Base64.encode64("#{@username}:#{@token}").chomp
    end
  end
end
