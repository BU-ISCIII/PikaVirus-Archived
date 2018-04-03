var margin;
$(document).ready(function() {
    /*changes properties of naviagtion menus*/
    set_size();
    $(".vertical-nav nav ul li ul li a").click(function() {
        // loads the corresponding result page
        //get organism and sample
        var organism = ($(this).text().toLowerCase());
        var sample = $(this).parent().parent().parent().find('span:first').text();
        //load_result('C1', 'bacteria');
        load_result(sample,organism);
    });
    $(window).resize(function() {
        set_size();

    });
});

function set_size() {
    // Horizontal and vertical nav behaviour
    if ($(window).width() > 1350) {
        margin = $('#horizontal-nav').css('marginLeft').replace(/[^-\d\.]/g, '');
        $('.vertical-nav').css("width", margin);
    } else {
        $('.vertical-nav').css("width", 80);
    }
    
    $('.results').css("width", $(window).width() - $('.vertical-nav').css("width").replace(/[^-\d\.]/g, ''));

    // 2nd level responsive behaviour. We change the class so the css
    //can change it
    if ($('.vertical-nav').width() < 155) {
        $('.submenu li a span').css("float", "none");
    } else {
        $('.submenu li a span').css("float", "right");
    }
}

function load_result(sample, organism) {
    $(".results").attr("data", "data/persamples/" + sample + "_" + organism + "_results.html");
}