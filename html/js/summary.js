var margin;
$(document).ready(function() {
    /*changes properties of naviagtion menus*/
    set_size();
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
    //Charts size
    $('.charts').css("width", $(window).width() - $('.vertical-nav').css("width").replace(/[^-\d\.]/g, ''));
    // We change the class of vertical-nav
    if ($('.vertical-nav').width() < 155) {
        $('.submenu li a span').css("float", "none");
    } else {
        $('.submenu li a span').css("float", "right");
    }
}

function load_summary(sample) { 
      sample = sample.charAt(0).toUpperCase() + sample.substr(1).toLowerCase();
      google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var organisms=["bacteria", "virus", "fungi","protozoa", "invertebrate"];

        for (i = 0; i < organisms.length; i++) {
            //get data from span
            span = new Array();
            stats=$('.'+sample+' .'+organisms[i]+' span').text();
            lines = stats.split("\n");
            lines=lines.filter(function(e){return e === 0 || e});
            //title
            span[0]=new Array(2);
            span[0][0]="Genome";
            span[0][1]="Hits";
            //data
            j=1;
            for (line = 0; line < lines.length; line++) { 
                //trim spaces and strip tabs so they don't mess the data    
                lines[line]=lines[line].trim().replace('\t','');
                span[j]= new Array(2);
                span[j][0] = lines[line].substr(lines[line].indexOf(' ') + 1); //gnm
                span[j][1] = parseInt(lines[line].substr(0,lines[line].indexOf(' '))); //cuantity 
                j++;

            }   

            data = google.visualization.arrayToDataTable(span);

            options = {
              title: sample+' '+organisms[i],
              pieHole: 0.4,
            };

            chart = new google.visualization.PieChart(document.getElementById(organisms[i]));
            chart.draw(data, options);        
        }
        delete span, lines, data, chart;
      }
  }


  
