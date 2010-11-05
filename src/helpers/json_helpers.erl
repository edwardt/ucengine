-module(json_helpers).

-export([unexpected_error/0,
	 error/1,
	 ok/0,
	 true/0,
	 false/0,
	 created/0,
	 created/1,
	 json/1,
	 xml/1]).

unexpected_error() ->
    Content = mochijson:encode({struct, [{error, unexpected_error}]}),
    [{status, 500},
     {content, "application/json", lists:flatten(Content)}].

error(Reason) ->
    Code = case Reason of
						% 400 Bad Request
	       bad_parameters -> 400;
	       missing_parameters -> 400;
						% 401 Unauthorized
	       unauthorized -> 401;
						% 403 Forbidden
	       bad_credentials -> 403;
						% 404 Not Found
	       not_found -> 404;
						% 409 Conflict
	       conflict -> 409;
						% 500 Internal Server Error
	       unexpected_error -> 500;
						% 501 Not Implemented
	       not_implemented -> 501;
						% Default error
	       _ -> 500
	   end,
    case Code of
	500 ->
	    ?MODULE:unexpected_error();
	_ ->
	    Content = mochijson:encode({struct, [{error, Reason}]}),
	    [{status, Code},
	     {content, "application/json", lists:flatten(Content)}]
    end.

ok() ->
    Content = mochijson:encode({struct, [{result, ok}]}),
    [{status, 200},
     {content, "application/json", lists:flatten(Content)}].

true() ->
    Content = mochijson:encode({struct, [{result, "true"}]}),
    [{status, 200},
     {content, "application/json", lists:flatten(Content)}].

false() ->
    Content = mochijson:encode({struct, [{result, "false"}]}),
    [{status, 200},
     {content, "application/json", lists:flatten(Content)}].

created() ->
    Content = mochijson:encode({struct, [{result, created}]}),
    [{status, 201},
     {content, "application/json", lists:flatten(Content)}].

created(Id) ->
    Content = mochijson:encode({struct, [{result, Id}]}),
    [{status, 201},
     {content, "application/json", lists:flatten(Content)}].

xml(Content) ->
    [{status, 200},
     {content, "application/xml", lists:flatten(Content)}].

json(Content) ->
    JSONContent = mochijson:encode({struct, [{result, Content}]}),
    [{status, 200},
     {content, "application/json", lists:flatten(JSONContent)}].
