# llm-open-connector-xai
This repo contains ruby code that implements Salesforce LLM Open connector spec and has the implementation for Xai models (Grok)

## Instructions

1. Install prequiresite gems

bundle install
or
bundle install --path vendor/bundle

2. set environmental variables
* CLIENT_API_KEY="some_secret"
This is the key that is used to exchange between Salesforce and Ruby middleware code
* XAI_API_KEY
This is in code with value <key>. Either edit app.rb and change this to your own xai key or set this in env var and require it

3. Push to your remote server such as Heroku as in the blog post / cookbook https://opensource.salesforce.com/einstein-platform/groq
