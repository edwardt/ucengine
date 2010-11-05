module('app', {
    setup: function() {
        this.app = $.sammy('#sammy_anchor', sammyapp);
        $.mockjax({
            url : '/api/0.1/org/af83',
            responseText: {"result": {"name"     :"af83",
                                      "metadata" : {"description":"af83m\u00e9dia specializes in digital communication. Our mission is to design and manage online content and communities.",
                                                    "logo":"af83.png",
                                                    "htags":"af83"}}}
        });
        $.mockjax({
            url: '/api/0.1/meeting/af83/opened',
            responseText: {"result":[{"org":"af83","name":"demo","start_date":1287493374119,"end_date":"never","roster":["root"],"metadata":{"description":"UCengine demo meetup"}},{"org":"af83","name":"demo2","start_date":1287493374120,"end_date":"never","roster":[],"metadata":{"description":"Meeting R&D"}}]}
        });
        $.mockjax({
            url : '/api/0.1/meeting/af83/closed',
            responseText: {"result":[{"org":"af83","name":"agoroom","start_date":1287493374120,"end_date":"1287493374120","roster":["root"],"metadata":{"description":"Meeting agoroom"}}]}
        });
        $.mockjax({
            url: '/api/0.1/meeting/af83/upcoming',
            responseText: {"result":[]}
        });
    },

    teardown: function() {
        $.mockjaxClear();
        $('#sammy_anchor').unbind('DOMSubtreeModified');
        this.app.unload();
        window.location.hash = '#/';
        $('#sammy_anchor').find('*').remove();
    }
});

function whenNotEmpty(el, callback) {
    setTimeout(function() {
        if (el.children().size() != 0)
            callback()
        else
            whenNotEmpty(el, callback);
    }, 50);
}

test("should load home page", function() {
    stop();
    whenNotEmpty($('#sammy_anchor'), function(e) {
        start();
        equals(document.title, 'Home - UCengine', "document.title");
        ok($('nav .page li:eq(0)').hasClass('on'), "hav class 'on' on first li");
        ok(!$('nav .page li:eq(1)').hasClass('on'), "no class 'on' on second li");
        $(this).unbind();
    });
    this.app.run('#/');
});

test("should load about page", function() {
    stop();
    expect(3);
    window.location.hash = '#/about';
    whenNotEmpty($('#sammy_anchor'), function(e) {
        start();
        equals(document.title, 'About - UCengine', "document.title");
        ok(!$('nav .page li:eq(0)').hasClass('on'), "not class 'on' on first li");
        ok($('nav .page li:eq(1)').hasClass('on'), "has class 'on' on second li");
        $(this).unbind();
    });
    this.app.run('#/about');
});
