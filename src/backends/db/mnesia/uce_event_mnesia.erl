-module(uce_event_mnesia).

-author('victor.goya@af83.com').

-export([init/0,
	 add/1,
	 get/1,
	 list/6]).

-include("uce.hrl").

init() ->
    mnesia:create_table(uce_event,
			[{disc_copies, [node()]},
			 {type, set},
			 {attributes, record_info(fields, uce_event)}]).

add(#uce_event{} = Event) ->
    case mnesia:transaction(fun() ->
				    mnesia:write(Event)
			    end) of
	{atomic, _} ->
	    ok;
	{aborted, Reason} ->
	    {error, Reason}
    end.

get(Id) ->
    case mnesia:transaction(fun() ->
				    mnesia:read(uce_event, Id)
			    end) of
	{aborted, Reason} ->
	    {error, Reason};
	{atomic, Event} ->
	    Event
    end.

list(Location, Search, From, Type, Start, End) ->
    MatchObject = if
		      Start == 0, End == infinity ->
			  #uce_event{id='_',
				       datetime='_',
				       location=Location,
				       from=From,
				       type=Type,
				       metadata='_'};
		      
		      true ->
			  SelectLocation = case Location of
					     ['_', '_'] ->
						 ['$3', '$4'];
					     [Org, '_'] ->
						 [Org, '$4'];
					     [Org, Meeting] ->
						 [Org, Meeting]
					 end,
			  SelectFrom = if
					   From == '_' ->
					       '$5';
					   true ->
					       From
				       end,
			  SelectType = if
					   Type == '_' ->
					       '$6';
					   true ->
					       Type
				       end,			  
			  Guard = if 
				      Start /= 0, End /= infinity ->
					  [{'>=', '$2', Start}, {'=<', '$2', End}];
				      
				      Start /= 0 ->
					  [{'>=', '$2', Start}];
				      
				      End /= infinity ->
					  [{'=<', '$2', End}];
				      
				      true ->
					  []
				  end,
			  Match = #uce_event{id='$1',
					       datetime='$2',
					       location=SelectLocation,
					       from=SelectFrom,
					       type=SelectType,
					       metadata='$7'},
			  Result = {{'uce_event', '$1','$2', SelectLocation,
				     SelectFrom, SelectType, '$7'}},
			  {Match, Guard, [Result]}
		  end,
    Events = case MatchObject of
		 #uce_event{} ->
		     mnesia:dirty_match_object(MatchObject);
		 {_, _, _} = MatchSpec ->
		     mnesia:dirty_select(uce_event, [MatchSpec]);
		 none ->
		     []
	     end,
    case Search of
	'_' ->
	    Events;
	_ ->
	    event_helpers:search(Events, Search)
    end.
