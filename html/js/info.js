
$(document).ready(function() {
	nav_scroll();
	nav_click();
});

function nav_click(){
 	$('.scroller > nav:first > a').on( 'click', function() {
 		$('.current').removeClass('current');
        $(this).addClass('current');
 	})
}


function nav_scroll(){
	//Mouse event
	var page = document.getElementById('pagina');
	if (page.addEventListener) {
		// IE9, Chrome, Safari, Opera
		page.addEventListener("mousewheel", MouseWheelHandler, false);
		// Firefox
		page.addEventListener("DOMMouseScroll", MouseWheelHandler, false);
	}
	// IE 6/7/8
	else page.attachEvent("onmousewheel", MouseWheelHandler);

	function MouseWheelHandler(e) {
		$('#pagina').bind("scroll", function() {
			currentSection=$(".section:in-viewport").attr('id');
			currentLink=$('.current').attr('href').replace('#','');
			if (currentLink!=currentSection){				
				$('.current').removeClass('current');
				$('a[href$="#'+currentSection+'"]').addClass('current');
			 }
    	});
	}	
}

