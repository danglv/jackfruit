(function ($) {
 
 $.fn.fullScreen = function () {

  this.click(function () {
    if( $(this).hasClass("rotate") ) {
  
      $(this).removeClass("rotate");
      var container = $(".lecture").width();
      var widthPlayer = 0;
      var widthContainer = 0;
      if (container >1200){
        widthPlayer = 75;
        widthContainer = 25;
      }
      else if (container > 992){
        widthPlayer = 66.66666666666666;
        widthContainer = 33.33333333333334;
      }
      else if (container > 776){
        widthPlayer = 58.333333333333336;
        widthContainer = 41.666666666666664;
      }
      $(".lecture-player").animate({"width" : widthPlayer + "%"},500);
      $(".lecture-container").animate({"display" : "block"},500);

      // bind event resize
      $( window ).bind("resize", function (){
        $(".lecture-player").attr("style","");
        $( window ).unbind("resize");
      })

    }
    else {
      $(this).addClass("rotate");
      $(".lecture-player").animate({"width" : "100%"},500);
      $(".lecture-container").animate({"display" : "none"},500);

    }
  });
 }
 $(".full-screen").fullScreen();

 $('.lecture-discussion-submit').click(function () {
    var obj = this;

    var course_id = $(".course_id").val();
    var title = $(".discussion-title").val();
    var description = $(".discussion-content").val();
    var curriculum_id = $(".lecture_id").val();

    var params = {
      'title' : title,
      'description' : description,
      'course_id' : course_id,
      'curriculum_id' : curriculum_id
    }

    var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          var data = msg;
          var discussionItem = "<div class='row discussion-item no-margin'> <div class='col-md-1 col-lg-1 no-padding discussion-item-avatar'> <i class='fa fa-smile-o'></i> </div> <div class='col-md-11 col-lg-11 no-padding discussion-item-main'> <ul class='discussion-item-title'> <li class='bold'>"+data.name+"</li><li>vừa đăng thảo luận</li> </ul> <span class='discussion-item-subject'>"+data.title+" </span> <p class='discussion-item-content'>"+data.description+" </p> </div> </div>";
          $(obj).parent().parent().parent().find(".list-discussion").prepend(discussionItem);

          $(".discussion-title").val("");
          $(".discussion-content").val("");
        }
      });
  })

  $('.comment-submit').click(function () {

    var obj = this;
    var course_id = $("#course_id").val();
    var parent_discussion = $(this).attr("discussion_id");
    var description = $(this).parent().find(".comment-content");

    var params = {
      'parent_discussion' : parent_discussion,
      'description' : description.val(),
      'course_id' : course_id
    }

    var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          var data = msg;

          description.val("");

          var childCommentItem = "<div class='row child-item no-margin'> <div class='col-md-1 col-lg-1 no-padding child-item-avatar'> <i class='fa fa-smile-o'></i> </div> <div class='col-md-11 col-lg-11 no-padding child-item-main'> <ul class='child-item-title'> <li class='bold'>"+data.name+"</li> <li>vừa đăng thảo luận</li> </ul> <p class='child-item-content'>"+data.description+" </p> </div> </div> ";

          $(obj).parent().parent().parent().prepend(childCommentItem);

        }
      });
  })

  $('.input-note-content').bind('keypress', function(e) {
    if(e.which === 13){
      var obj = this;
      var content = $(".input-note-content").val();
      var owned_course_id = $(".owned_course_id").val();
      var owned_lecture_id = $(".owned_lecture_id").val();

      var params = {
        'content' : content,
        'owned_course_id' : owned_course_id,
        'owned_lecture_id' : owned_lecture_id
      }

      $(".input-note-content").val("");

      var URL = 'http://' + window.location.host + '/users/create_note';
      $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          var data = msg;
          // description.val("");
          // var childCommentItem = "<div class='row child-item no-margin'> <div class='col-md-1 col-lg-1 no-padding child-item-avatar'> <i class='fa fa-smile-o'></i> </div> <div class='col-md-11 col-lg-11 no-padding child-item-main'> <ul class='child-item-title'> <li class='bold'>"+data.name+"</li> <li>vừa đăng thảo luận</li> </ul> <p class='child-item-content'>"+data.description+" </p> </div> </div> ";

          // $(obj).parent().parent().parent().prepend(childCommentItem);
        }
      });
    }
  });

  $(".note-delete").click(function() {
    var obj = this;
    var note_id = $(".note-id").val();
    var owned_course_id = $(".owned_course_id").val();
    var owned_lecture_id = $(".owned_lecture_id").val();

    var params = {
      'note_id' : note_id,
      'owned_course_id' : owned_course_id,
      'owned_lecture_id' : owned_lecture_id
    }

    console.log(params)

    var URL = 'http://' + window.location.host + '/users/delete_note';
    $.ajax({
      type: 'POST',
      url: URL,
      data: params,
      success: function(msg){
        console.log(msg)
        var data = msg;
      }
    });
  })

}(jQuery));