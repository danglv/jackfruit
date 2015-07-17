$(document).ready(function(){
    $('input[type=checkbox]').change(function(){
        var input = $(this);
        //unchecked other
 
       $('#test-form').submit()
    });
    function getParameterByName(name) {
        name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
            results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
    }
    // checked for input of page
    var price = getParameterByName('price');
    var language = getParameterByName('language')
    var level = getParameterByName('level');
    $("input[type=checkbox]" ).each(function( index ) {
        var value = $(this).attr('value');
        if(value == price || value == language || value == level){
            $(this).attr("checked", "checked");
        }
    });

})