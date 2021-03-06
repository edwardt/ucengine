%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(user_tests).

-include("uce.hrl").
-include_lib("eunit/include/eunit.hrl").

user_test_() ->
    { setup
    , fun fixtures:setup/0
    , fun fixtures:teardown/1
    , fun([_, BaseUrl, [Root, _Participant, Ugly|_]]) ->
              [?_test(test_register(BaseUrl)),
               ?_test(test_register_missing_auth(BaseUrl)),
               ?_test(test_register_missing_credential(BaseUrl)),
               ?_test(test_register_missing_name(BaseUrl)),
               ?_test(test_register_conflict(BaseUrl)),
               
               ?_test(test_get(BaseUrl, Root)),
               ?_test(test_get_not_found(BaseUrl, Root)),
               ?_test(test_get_unauthorized(BaseUrl, Ugly)),
               
               ?_test(test_list(BaseUrl, Root)),
               ?_test(test_list_unauthorized(BaseUrl, Ugly)),
               
               ?_test(test_update(BaseUrl, Root)),
               ?_test(test_update_missing_auth(BaseUrl, Root)),
               ?_test(test_update_missing_credential(BaseUrl, Root)),
               ?_test(test_update_not_found(BaseUrl, Root)),
               ?_test(test_update_unauthorized(BaseUrl, Ugly)),
               
               ?_test(test_delete_unauthorized(BaseUrl, Ugly)),
               ?_test(test_delete(BaseUrl, Root)),
               ?_test(test_delete_not_found(BaseUrl, Root))]
      end
    }.

test_register(BaseUrl) ->
    Params = [{"auth", "test"},
              {"credential", "test"},
              {"uid", "test.user@af83.com"},
              {"metadata[nickname]", "test_nickname"}],
    {struct, [{"result", "created"}]} =
        tests_utils:post(BaseUrl, "/user/", Params).

test_register_missing_auth(BaseUrl) ->
    Params = [{"credential", "test"},
              {"uid", "test.user@af83.com"},
              {"metadata[nickname]", "test_nickname"}],
    {struct, [{"error", "missing_parameters"}]} =
        tests_utils:post(BaseUrl, "/user/", Params).

test_register_missing_credential(BaseUrl) ->
    Params = [{"auth", "test"},
              {"uid", "test.user@af83.com"},
              {"metadata[nickname]", "test_nickname"}],
    {struct, [{"error", "missing_parameters"}]} =
        tests_utils:post(BaseUrl, "/user/", Params).

test_register_missing_name(BaseUrl) ->
    Params = [{"auth", "test"},
              {"metadata[nickname]", "test_nickname"}],
    {struct, [{"error", "missing_parameters"}]} =
        tests_utils:post(BaseUrl, "/user/", Params).

test_register_conflict(BaseUrl) ->
    Params = [{"auth", "test"},
              {"uid", "test.user@af83.com"},
              {"credential", "test"}],
    {struct, [{"error", "conflict"}]} =
        tests_utils:post(BaseUrl, "/user/", Params).

test_get(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid}],
    {struct,[{"result",
              {struct,[{"uid","test.user@af83.com"},
                       {"domain", _},
                       {"auth","test"},
                       {"metadata",{struct,[{"nickname", "test_nickname"}]}}
                      ]}
             }]} = tests_utils:get(BaseUrl, "/user/test.user@af83.com", Params).

test_get_not_found(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid}],
    {struct, [{"error", "not_found"}]} =
        tests_utils:get(BaseUrl, "/user/unexistent.user@af83.com", Params).

test_get_unauthorized(BaseUrl, {UglyUid, UglySid}) ->
    Params = [{"uid", UglyUid},
	      {"sid", UglySid}],
    {struct, [{"error", "unauthorized"}]} =
        tests_utils:get(BaseUrl, "/user/unexistent.user@af83.com", Params).

test_list(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid}],
    {struct,[{"result",
              {array,
               [{struct,[{"uid",_},
                         {"domain", _},
                         {"auth",_},
                         {"metadata",{struct,_}}
                        ]}|_]
              }}]} = tests_utils:get(BaseUrl, "/user/", Params).

test_list_unauthorized(BaseUrl, {UglyUid, UglySid}) ->
    Params = [{"uid", UglyUid},
	      {"sid", UglySid}],
    {struct, [{"error", "unauthorized"}]} = tests_utils:get(BaseUrl, "/user/", Params).

test_update(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid},
              {"auth", "test_modified"},
              {"credential", "test_modified"},
              {"metadata[nickname]", "test_modified_nickname"}],
    {struct, [{"result", "ok"}]} =
        tests_utils:put(BaseUrl, "/user/test.user@af83.com", Params).


test_update_missing_auth(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid},
              {"credential", "test_modified"},
              {"metadata[nickname]", "test_modified_nickname"}],
    {struct, [{"error", "missing_parameters"}]} =
        tests_utils:put(BaseUrl, "/user/test.user@af83.com", Params).

test_update_missing_credential(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid},
              {"auth", "test_modified"},
              {"metadata[nickname]", "test_modified_nickname"}],
    {struct, [{"error", "missing_parameters"}]} =
        tests_utils:put(BaseUrl, "/user/test.user@af83.com", Params).

test_update_not_found(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid},
              {"auth", "test_modified"},
              {"credential", "test_modified"},
              {"metadata[nickname]", "test_modified_nickname"}],
    {struct, [{"error", "not_found"}]} =
        tests_utils:put(BaseUrl, "/user/unexistent.user@af83.com", Params).

test_update_unauthorized(BaseUrl, {UglyUid, UglySid}) ->
    Params = [{"uid", UglyUid},
              {"sid", UglySid},
              {"auth", "test_modified"},
              {"credential", "test_modified"},
              {"metadata[nickname]", "test_modified_nickname"}],
    {struct, [{"error", "unauthorized"}]} =
        tests_utils:put(BaseUrl, "/user/test.user@af83.com", Params).

test_delete_unauthorized(BaseUrl, {UglyUid, UglySid}) ->
    Params = [{"uid", UglyUid},
              {"sid", UglySid}],
    {struct, [{"error", "unauthorized"}]} =
        tests_utils:delete(BaseUrl, "/user/test.user@af83.com", Params).

test_delete(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid}],
    {struct, [{"result", "ok"}]} =
        tests_utils:delete(BaseUrl, "/user/test.user@af83.com", Params),
    {struct, [{"error", "not_found"}]} =
        tests_utils:get(BaseUrl, "/user/test.user@af83.com", Params).

test_delete_not_found(BaseUrl, {RootUid, RootSid}) ->
    Params = [{"uid", RootUid},
              {"sid", RootSid}],
    {struct, [{"error", "not_found"}]} =
        tests_utils:delete(BaseUrl, "/user/unexistent.user@af83.com", Params).
