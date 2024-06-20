#!/bin/sh

# Will convert Postman api spec json to OpenAPI yaml
# requires installing as cli using npm:
#   $ npm i postman-to-openapi -g
#
# p2o ./path/to/PostmantoCollection.json -f ./path/to/result.yml {-o options file name}
#

p2o ./Bricks_server.postman_collection.json -f ./Bricks_server.open_api.yml -o
