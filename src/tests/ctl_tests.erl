-module(ctl_tests).

-include("uce.hrl").
-include_lib("eunit/include/eunit.hrl").

ctl_org_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_org_add())
        , ?_test(test_org_add_missing_parameter())
        , ?_test(test_org_get())
        , ?_test(test_org_get_missing_parameter())
        , ?_test(test_org_get_not_found())
        , ?_test(test_org_update())
        , ?_test(test_org_update_missing_parameter())
        , ?_test(test_org_update_not_found())
        , ?_test(test_org_delete())
        , ?_test(test_org_delete_missing_parameter())
        , ?_test(test_org_delete_not_found())
        , ?_test(test_org_list())
        ]
      end
    }.

ctl_meeting_test_() ->
    { setup
      , fun fixtures:setup/0
      , fun fixtures:teardown/1
      , fun(_Testers) ->
        [ ?_test(test_meeting_add())
        , ?_test(test_meeting_add_missing_parameter())
        , ?_test(test_meeting_get())
        , ?_test(test_meeting_get_missing_parameter())
        , ?_test(test_meeting_get_not_found())
        , ?_test(test_meeting_update())
        , ?_test(test_meeting_update_missing_parameter())
        , ?_test(test_meeting_update_not_found())
        , ?_test(test_meeting_delete())
        , ?_test(test_meeting_delete_missing_parameter())
        , ?_test(test_meeting_delete_not_found())
        , ?_test(test_meeting_list())
        , ?_test(test_meeting_list_missing_parameter())
        , ?_test(test_meeting_list_not_found())
        ]
      end
    }.


%%
%% Org
%%
test_org_add() ->
    {error, not_found} = uce_org:get("neworg"),
    Params = [{"name", ["neworg"]}, {"description", [""]}],
    ok = uce_ctl:action(org, add, Params),
    Expected = {ok, #uce_org{name="neworg", metadata=[{"description", ""}]}},
    Expected = uce_org:get("neworg").
test_org_add_missing_parameter() ->
    Params = [{"description", [""]}],
    error = uce_ctl:action(org, add, Params).

test_org_get() ->
    Params = [{"name", ["testorg"]}],
    ok = uce_ctl:action(org, get, Params).
test_org_get_missing_parameter() ->
    error = uce_ctl:action(org, get, []).
test_org_get_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, get, Params).

test_org_update() ->
    Before = {ok, #uce_org{name="testorg", metadata=[{"description", "testorg"}]}},
    Before = uce_org:get("testorg"),
    Params = [{"name", ["testorg"]}, {"description", ["A new description"]}],
    ok = uce_ctl:action(org, update, Params),
    Expected = {ok, #uce_org{name="testorg", metadata=[{"description", "A new description"}]}},
    Expected = uce_org:get("testorg").
test_org_update_missing_parameter() ->
    error = uce_ctl:action(org, update, []).
test_org_update_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, update, Params).

test_org_delete() ->
    Before = {ok, #uce_org{name="testorg", metadata=[{"description", "A new description"}]}},
    Before = uce_org:get("testorg"),
    Params = [{"name", ["testorg"]}],
    ok = uce_ctl:action(org, delete, Params),
    {error, not_found} = uce_org:get("testorg").
test_org_delete_missing_parameter() ->
    error = uce_ctl:action(org, delete, []).
test_org_delete_not_found() ->
    Params = [{"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, delete, Params).

test_org_list() ->
    ok = uce_ctl:action(org, list, []).

%%
%% Meeting
%%

test_meeting_add() ->
    {error, not_found} = uce_meeting:get("newmeeting"),
    Params = [{"org", ["testorg"]}, {"name", ["newmeeting"]}, {"description", [""]}],
    ok = uce_ctl:action(meeting, add, Params),
    Expected = {ok, #uce_meeting{id=["testorg", "newmeeting"], metadata=[{"description", ""}]}},
    Expected = uce_meeting:get(["testorg", "newmeeting"]).
test_meeting_add_missing_parameter() ->
    error = uce_ctl:action(meeting, add, []).

test_meeting_get() ->
    Params = [{"org", ["testorg"]}, {"name", ["testmeeting"]}],
    ok = uce_ctl:action(meeting, get, Params).
test_meeting_get_missing_parameter() ->
    error = uce_ctl:action(meeting, get, []).
test_meeting_get_not_found() ->
    Params = [{"org", ["testorg"]}, {"name", ["meeting that doesn't exists"]}],
    error = uce_ctl:action(meeting, get, Params).

test_meeting_update() ->
    {ok, #uce_meeting{ id=["testorg", "testmeeting"]
                     , start_date=Start
                     , end_date=End
                     , metadata=[{"description", Description}]
                     }} = uce_meeting:get(["testorg", "testmeeting"]),
    StartDate = uce_ctl:timestamp_to_iso(Start),
    EndDate = uce_ctl:timestamp_to_iso(End),
    Params = [ {"org", ["testorg"]}
             , {"name", ["testmeeting"]}
             , {"start", StartDate}
             , {"end", EndDate}
             , {"description", ["A new description"]}
             ],
    ok = uce_ctl:action(meeting, update, Params),
    Expected = {ok, #uce_meeting{ id=["testorg", "testmeeting"]
                                , start_date=uce_ctl:parse_date(StartDate)
                                , end_date=uce_ctl:parse_date(EndDate)
                                , metadata=[{"description", "A new description"}]
                                }},
    Expected = uce_meeting:get(["testorg", "testmeeting"]).
test_meeting_update_missing_parameter() ->
    error = uce_ctl:action(org, update, []).
test_meeting_update_not_found() ->
    Params = [{"org", ["testorg"]}, {"name", ["org that doesnt exists"]}],
    error = uce_ctl:action(org, update, Params).

test_meeting_delete() ->
    {ok, #uce_meeting{ id=["testorg", "testmeeting"]
                     , start_date=_Start
                     , end_date=_End
                     , metadata=[{"description", _Description}]
                     }} = uce_meeting:get(["testorg", "testmeeting"]),
    Params = [{"org", ["testorg"]}, {"name", ["testmeeting"]}],
    ok = uce_ctl:action(meeting, delete, Params),
    {error, not_found} = uce_meeting:get(["testorg", "testmeeting"]).
test_meeting_delete_missing_parameter() ->
    error = uce_ctl:action(meeting, delete, []).
test_meeting_delete_not_found() ->
    Params = [{"org", ["testorg"]}, {"name", ["meeting that doesn't exists"]}],
    error = uce_ctl:action(meeting, delete, []).

test_meeting_list() ->
    Params = [{"org", ["testorg"]}, {"status", ["all"]}],
    ok = uce_ctl:action(meeting, list, Params).
test_meeting_list_missing_parameter() ->
    error = uce_ctl:action(meeting, list, []).
test_meeting_list_not_found() ->
    Params = [{"org", ["org that doesn't exitst"]}, {"status", ["all"]}],
    error = uce_ctl:action(meeting, list, []).

