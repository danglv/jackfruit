//document.getElementById('search-form').addEventListener("submit", function(event){
//    var input = document.getElementById("course-search_search").value;
//    if (input.length < 3){
//        alert('bad keyword');
//        event.preventDefault();
//        return false
//    }
//})
$(document).ready(function (){
    $("#search-form").on("submit", function(e){
        var input = $("#course-search").val();
        if(input.length < 3) {
            e.preventDefault();
        }

    });
})