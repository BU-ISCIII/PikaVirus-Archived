
$(document).ready(function() {
    /*changes properties of naviagtion menus*/
    $(".menu").click(function() {
        // Change style of the selected sample
        $('a.selected').removeClass('selected');
        $(this).addClass('selected');
    });
    $(".tabs-style-bar nav ul li").click(function() {
        $('.tab-current').removeClass('tab-current');
        $(this).addClass('tab-current');
    });
});
