// load testswarm agent
(function() {
    var url = window.location.search;
    url = decodeURIComponent( url.slice( url.indexOf("swarmURL=") + 9 ) );
    if ( !url || url.indexOf("http") !== 0 ) {
        return;
    }

    document.write("<scr" + "ipt src='http://swarm.af83.com/js/inject.js?" + (new Date).getTime() + "'></scr" + "ipt>");
})();
