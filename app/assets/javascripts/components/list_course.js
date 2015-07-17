$(document).ready(function(){

    // make submit form
    $('input[type=checkbox]').change(function(){
        var inputChecked = $(this);
        //unchecked other
        $("input[type=checkbox]" ).each(function( ) {
            var name = $(this).attr('name');
            var value = $(this).attr('value');
            if(name == inputChecked.attr('name') && inputChecked.attr('value') != value){
                $(this).removeAttr('checked');
            }
        });
       $('#test-form').submit();
    });

    // listen sort event
    $('#sorting-options').on('change', function(){
        $('#test-form').submit();
    });

    // get param url
    function getParameterByName(name) {
        name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
            results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
    }
    // checked for input of page
    var price = getParameterByName('budget');
    var language = getParameterByName('lang')
    var level = getParameterByName('level');
    var sort = getParameterByName('ordering');
    var page = getParameterByName('page')
    $("input[type=checkbox]" ).each(function( ) {
        var value = $(this).attr('value');
        if(value == price || value == language || value == level){
            $(this).attr("checked", "checked");
        }
    });
    // set selected
    $('option').each(function( ) {
        if($(this).val() == sort){
            $(this).attr("selected", "selected");
            $('select').material_select();
        }
    });

    // set pageginate
    if(page == ''){
        page = 1;
    }
    $("#page-index").val(page);
    $('.pagination li').each(function(){
        if($(this).text() == page) {
            $(this).addClass('active');
        }else{
            $(this).removeClass('active')
        }
    });
    //listen click into page
    $('.pagination li').click(function(){
        $("#page-index").val($(this).text());
        $('#test-form').submit();

    });

})