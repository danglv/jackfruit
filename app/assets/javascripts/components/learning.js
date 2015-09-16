$(document).ready(function (){
	$('#comment-dropdown').click(function (e){
	  	e.stopPropagation(); 
		});
	// close popup
	$('#close-send-comment').click(function (){
    $('#comment-dropdown').fadeOut(225);
		$('#comment-dropdown').removeClass('active');
	})
	// send request to add comment 
	$('#send-comment').click(function (){

		var course_id = $("#course-id").val();
  	var _title = $("#comment-title").val();
  	var _description = $("#comment-content").val();
  	if(_title.trim() == ''){
  		$("#comment-title").focus();
  		return;
  	}
  	if(_description == ''){
  		$("#comment-content").focus();
  		return;
  	}
  	var params = {
  		'title' : _title,
  		'description' : _description
  	}
		var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
		$.ajax({
		    type: 'POST',
		    url: URL,
		    data: params,
		    success: function(msg){
		      var respon =$.parseJSON(JSON.stringify(msg));
		      var comment_item = '<div class="col s12 no-padding cm-item"> <div class="row cm-item-header no-margin"> <ul class="no-margin"> <li> <i class="small material-icons no-padding">face</i> </li> <li> <p class="left" style="font-weight: 500; color: #353535">' + respon.email + '</p> <p class="left" style="font-weight: 500; color: #335d82; font-size: 12px; margin-left: 5px"> đã đăng một thảo luận</p> </li> <li></li> </li> </ul> </div> <div class="row cm-item-content"> <p class="no-margin" style="font-size: 18px; font-weight: 500; color: #59657D">' +respon.title+ '</p> <p style="margin: 0px 0px 0px 0px">' + respon.description + '</p> </div> </div>'
		      $('.lecture-comment-list').prepend(comment_item);
		        $('#comment-dropdown').fadeOut(225);
     			  $('#comment-dropdown').removeClass('active');
		    }
			});

		})
	// search comment when typing
	$('#search-comment').on('input', function (){
		var key_words = $(this).val();
		if(key_words.trim() != ''){
			var list_comment = $('.cm-item');
			list_comment.each(function (){
				var item_comment = $(this);
				var isFind = false;
				item_comment.find(".cm-item-content").each(function (){
					if( $(this).text().toLowerCase().indexOf(key_words.toLowerCase()) > 0 ){
						isFind = true;
					}
				})
				if(!isFind){
					item_comment.attr("style", "display: none");
				}
				else{
					item_comment.attr("style", "display: block");
				}
			});
		}
		else{
			var list_comment = $('.cm-item');
			list_comment.each(function (){
				$(this).attr("style", "display: block");
			});
		}
		
	});

  $('#discussion-submit').click(function () {
    var course_id = $("#course_id").val();
    var title = $("#discussion-title").val();
    var description = $("#discussion-content").val();

    var params = {
      'title' : title,
      'description' : description,
      'course_id' : course_id
    }

    var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          console.log(msg)
        }
      });
  })

  $('#comment-submit').click(function () {
    var course_id = $("#course_id").val();
    var parent_discussion = $("#discussion_id").val();
    var description = $("#comment-content").val();

    var params = {
      'parent_discussion' : parent_discussion,
      'description' : description,
      'course_id' : course_id
    }

    var URL = 'http://' + window.location.host + '/courses/' + course_id + '/add_discussion';
    $.ajax({
        type: 'POST',
        url: URL,
        data: params,
        success: function(msg){
          console.log(msg)
        }
      });
  })

  //================== new layout

  //expand reply
  $.fn.discussionItemReply = function () {

    this.on("click", function () {
      var listChildren = $(this).parent().find(".list-children");
      if ( listChildren != null) {
        if( !listChildren.hasClass("expand") ) {
          listChildren.fadeIn();
          listChildren.addClass("expand");
        }
        else {
          listChildren.fadeOut();
          listChildren.removeClass("expand");
          listChildren.addClass("collapsed");
        }
      }
    });
    return this;
  };
  $.fn.notiItemReply = function () {
    this.on("click", function () {
      var listChildren = $(this).parent().find(".list-children");
      if( listChildren != null){
        if( !listChildren.hasClass("expand") ) {
          listChildren.fadeIn();
          listChildren.addClass("expand");
        }
        else{
          listChildren.fadeOut();
          listChildren.removeClass("expand");
          listChildren.addClass("collapsed");
        }
      }
    });
    return this;
  };
  $(".discussion-item-reply").discussionItemReply();
  $(".noti-item-reply").notiItemReply();


  // tab to show
  $(".learning_tab").on("click", function () {

    var tabValue = $(this).attr("val");
    var itemsProgress = $(this).parent().find(".progress").children();

    var progress_actived = function (object) {
       $(".progress-actived").removeClass("progress-actived");
       $(object).addClass("progress-actived");
       $(object).fadeIn();
    };
    var effectActive = function (active, nonActive) {
      $(".tab-actived").removeClass("tab-actived");
      $(active).removeClass("collapsed");
      $(active).addClass("expand");
      $(active).fadeIn();
      $(nonActive).fadeOut();
      $(nonActive).removeClass("expand");
      $(nonActive).addClass("collapsed");
    };
    var object = $(this);
    var tabActions = {
      discussion : function () {
        progress_actived( itemsProgress[0]);
        effectActive(".discussion",".noti");
        object.addClass("tab-actived");
        return;
      },
      noti : function () {
        progress_actived( itemsProgress[1]);
        effectActive(".noti",".discussion");
        object.addClass("tab-actived");
        return;
      },
      student : function () {
        // progress_actived( itemsProgress[2]);
        return;

      },
      default : function () {
        progress_actived( itemsProgress[0]);
        effectActive(".discussion",".noti");
        return;
      }
    };
    // check exists
    if ( tabValue in tabActions == false) {

      tabValue = "default";
    }
    tabActions[tabValue]();

  });

})