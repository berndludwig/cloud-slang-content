#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
####################################################
# Authenticates and retrieves a list of all Helion Development Platform / Stackato users
#
# Inputs:
#   - host - Helion Development Platform / Stackato host
#   - username - Helion Development Platform / Stackato username
#   - password - Helion Development Platform / Stackato password
#   - proxy_host - optional - the proxy server used to access the Helion Development Platform / Stackato services
#   - proxy_port - optional - proxy server port - the proxy server port used to access the Helion Development Platform
#                                                 / Stackato services - Default: "'8080'"
#   - proxy_username - optional - user name used when connecting to the proxy
#   - proxy_password - optional - proxy server password associated with the <proxyUsername> input value
# Outputs:
#   - return_result - the response of the operation in case of success, the error message otherwise
#   - error_message - return_result if status_code is not '200'
#   - return_code - '0' if success, '-1' otherwise
#   - status_code - the code returned by the operation
#   - users_list - list of all spaces on Helion Development Platform / Stackato instance
#   - usernames_list - list containing only the usernames of the users_list
# Results:
#   - SUCCESS - the list with existing users on Helion Development Platform / Stackato host was successfully retrieved
#   - GET_AUTHENTICATION_FAILURE - the authentication call fail
#   - GET_AUTHENTICATION_TOKEN_FAILURE - the authentication token cannot be obtained from authentication call response
#   - GET_USERS_FAILURE - the get users call fail
#   - GET_USERS_LIST_FAILURE - the list with existing users on Helion Development Platform / Stackato could not be
#                              retrieved
####################################################
namespace: io.cloudslang.paas.stackato.users

imports:
  stackato: io.cloudslang.paas.stackato
  stackato_utils: io.cloudslang.paas.stackato.utils
  rest: io.cloudslang.base.network.rest
  json: io.cloudslang.base.json

flow:
  name: get_users
  inputs:
    - host
    - username
    - password
    - proxy_host:
        required: false
    - proxy_port:
        default: '8080'
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false

  workflow:
    - authentication:
        do:
          stackato.get_authentication:
            - host
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
        publish:
          - return_result
          - error_message
          - token
        navigate:
          SUCCESS: get_users_call
          GET_AUTHENTICATION_FAILURE: GET_AUTHENTICATION_FAILURE
          GET_AUTHENTICATION_TOKEN_FAILURE: GET_AUTHENTICATION_TOKEN_FAILURE

    - get_users_call:
        do:
          rest.http_client_get:
            - url: "${'https://' + host + '/v2/users'}"
            - username
            - password
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - headers: "${'Authorization: bearer ' + token}"
            - content_type: 'application/json'
        publish:
          - return_result
          - error_message
          - return_code
          - status_code
        navigate:
          SUCCESS: get_users_list
          FAILURE: GET_USERS_FAILURE

    - get_users_list:
        do:
          json.get_value:
            - json_input: ${return_result}
            - json_path: ["'resources'"]
        publish:
          - users_list: ${value}
        navigate:
          SUCCESS: get_usernames_list
          FAILURE: GET_USERS_LIST_FAILURE

    - get_usernames_list:
        do:
          stackato_utils.get_usernames_list:
            - json_input: ${return_result}
        publish:
          - usernames_list
        navigate:
          SUCCESS: SUCCESS
          FAILURE: GET_USERNAMES_LIST_FAILURE

  outputs:
    - return_result
    - return_code
    - status_code
    - error_message: ${return_result if return_code == '-1' or status_code != '200' else ''}
    - users_list
    - usernames_list

  results:
    - SUCCESS
    - GET_AUTHENTICATION_FAILURE
    - GET_AUTHENTICATION_TOKEN_FAILURE
    - GET_USERS_FAILURE
    - GET_USERS_LIST_FAILURE
    - GET_USERNAMES_LIST_FAILURE